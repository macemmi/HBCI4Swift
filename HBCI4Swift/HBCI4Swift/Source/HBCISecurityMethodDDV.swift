//
//  HBCISecurityMethodDDV.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 13.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import CommonCrypto

open class HBCISecurityMethodDDV : HBCISecurityMethod {
    
    var card:HBCISmartcardDDV!
    var sigKeyNumber:Int?
    var sigKeyVersion:Int?
    var cryptKeyNumber:Int?
    var cryptKeyVersion:Int?
    
    public init(card:HBCISmartcardDDV) {
        self.card = card;
        super.init();
        self.code = .ddv;
    }
    
    override func signMessage(_ msg:HBCIMessage) ->Bool {
        //let secref:String = NSString(format: "%d", arc4random());
        var version = 0;
        
        let secref = "\(arc4random())";
        
        if let seg = msg.elementForPath("SigHead") as? HBCISegment {
            version = seg.version;
        } else {
            logInfo("SigHead segment not found");
            return false;
        }
        
        // get cid
        if card != nil {
            if card.cardID == nil {
                if !card.getCardID() {
                    logInfo("Card ID could not be determined");
                    return false;
                }
            }
            
            if sigKeyNumber == nil {
                let keys = card.getKeyData();
                if keys.count < 2 {
                    logInfo("Card keys could not be determined");
                    return false;
                }
                let sigKeys = keys[0];
                sigKeyNumber = Int(sigKeys.keyNumber);
                sigKeyVersion = Int(sigKeys.keyVersion);

                let cryptKeys = keys[1];
                cryptKeyNumber = Int(cryptKeys.keyNumber);
                cryptKeyVersion = Int(cryptKeys.keyVersion);
            }
        } else {
            logInfo("No chipcard assigned to DDV security method");
            return false;
        }
        
        // get signature id
        var sigid = Int(card.getSignatureId());
        sigid = sigid + 1;
        
        if !card.writeSignatureId(sigid) {
            logInfo("Unable to increment signature id");
            return false;
        }
        
        
        // setup sighead segment
        guard let sigKeyNumber = self.sigKeyNumber, let sigKeyVersion = self.sigKeyVersion else {
            return false;
        }
        
        var values_head = ["SigHead.secfunc":"2",
            "SigHead.seccheckref":secref, "SigHead.range":"1", "SigHead.role":"1", "SigHead.SecIdnDetails.func":"1",
            "SigHead.SecIdnDetails.cid":card.cardID!, "SigHead.secref":sigid, "SigHead.SecTimestamp.type":"1",
            "SigHead.SecTimestamp.date":Date(), "SigHead.SecTimestamp.time":Date(), "SigHead.HashAlg.alg":"999",
            "SigHead.SigAlg.alg":"1", "SigHead.SigAlg.mode":"999", "SigHead.KeyName.country":"280",
            "SigHead.KeyName.blz":user.bankCode, "SigHead.KeyName.userid":user.userId, "SigHead.KeyName.keytype":"S",
            "SigHead.KeyName.keynum":sigKeyNumber, "SigHead.KeyName.keyversion":sigKeyVersion, "SigTail.seccheckref":secref
        ] as [String : Any];
        
        if version > 3 {
            values_head["SigHead.SecProfile.method"] = "DDV";
            values_head["SigHead.SecProfile.version"] = "1";
        }
        
        if !msg.setElementValues(values_head) {
            logInfo("SigHead values could not be set");
            return false;
        }
        
        // calculate message hash
        let msgData = msg.messageDataForSignature();
        let hash:Data = RIPEMD160(data: msgData).digest() as Data;
        
        // sign hash
        let signedHash = card.sign(hash);
        if signedHash == nil {
            logInfo("Message hash could not be signed");
            return false;
        }
        
        if !msg.setElementValue(signedHash!, path: "SigTail.sig") { return false; }
        return true;
    }
    
    func buildCryptHead(_ msg:HBCIMessage, key:Data) ->Bool {
        var version = 0;
        
        if let seg = msg.elementForPath("CryptHead") as? HBCISegment {
            version = seg.version;
        } else {
            logInfo("CryptHead segment not found");
            return false;
        }
        
        guard let cryptKeyNumber = self.cryptKeyNumber, let cryptKeyVersion = self.cryptKeyVersion else {
            return false;
        }

        var values = [ "CryptHead.SegHead.seq":"998",
            "CryptHead.secfunc":"4", "CryptHead.role":"1", "CryptHead.SecIdnDetails.func":"1",
            "CryptHead.SecIdnDetails.cid":card.cardID!, "CryptHead.SecTimestamp.date":Date(), "CryptHead.SecTimestamp.time":Date(),
            "CryptHead.CryptAlg.mode":"2", "CryptHead.CryptAlg.alg":"13", "CryptHead.CryptAlg.enckey":key,
            "CryptHead.CryptAlg.keytype":"5", "CryptHead.KeyName.country":"280", "CryptHead.KeyName.blz":user.bankCode,
            "CryptHead.KeyName.userid":user.userId, "CryptHead.KeyName.keynum":cryptKeyNumber, "CryptHead.KeyName.keyversion":cryptKeyVersion,
            "CryptHead.compfunc":"0"
        ] as [String : Any];
        
        if version > 2 {
            values["CryptHead.SecProfile.method"] = "DDV";
            values["CryptHead.SecProfile.version"] = "1";
        }

        
        return msg.setElementValues(values);
    }
    
    /*
    func decryptTest(plain:NSData, encData:NSData) {
        // decrypt message
        let key = NSMutableData(data: plain);
        key.appendBytes(plain.bytes, length: 8);
        
        var decrypted = [UInt8](count:encData.length, repeatedValue:0);
        var plainSize = 0;
        
        let rv = CCCrypt(UInt32(kCCDecrypt), UInt32(kCCAlgorithm3DES), UInt32(0), key.bytes, 24, nil, encData.bytes, encData.length, &decrypted, encData.length, &plainSize);
        if Int(rv) != kCCSuccess {
            logInfo("Decryption failed. Status: \(rv)");
            return;
        }
        
        let msgData = NSData(bytes: decrypted, length: plainSize);
    }
    */
    
    override func encryptMessage(_ msg:HBCIMessage, dialog:HBCIDialog) ->HBCIMessage? {

        if let lastSegNum = msg.lastSegmentNumber() {
            if let dialogId = dialog.dialogId {
                let msgBody = msg.messageDataForEncryption();
                
                // encrypt message body
                if let (plain, enc) = card.getEncryptionKeys(3) {
                    // build 3DES key
                    let key = NSMutableData(data: plain as Data);
                    key.append(plain.bytes, length: 8);
                    
                    //iv
                    let iv = [UInt8](repeating: 0, count: 8);
                    
                    let bufSize = msgBody.count+8;
                    var encrypted = [UInt8](repeating: 0, count: bufSize);
                    var encSize = 0;
                    
                    // pad message data
                    let paddedData = NSMutableData(data: msgBody);
                    let padlen = 8-msgBody.count%8;
                    var padLen_pad = UInt8(padlen);
                    paddedData.append(iv, length: padlen-1);
                    paddedData.append(&padLen_pad, length: 1);
                    
                    let rv = CCCrypt(UInt32(kCCEncrypt), UInt32(kCCAlgorithm3DES), UInt32(0), key.bytes, kCCKeySize3DES, iv, paddedData.bytes, paddedData.length, &encrypted, bufSize, &encSize);
                    if Int(rv) != kCCSuccess {
                        logInfo("Encryption failed. Status: \(rv)");
                        return nil;
                    }
                    
                    let cryptedData = Data(bytes: UnsafePointer<UInt8>(encrypted), count: encSize)
                    
                    //self.decryptTest(plain, encData: cryptedData);
                    
                    let values = ["MsgHead.dialogid":dialogId, "MsgHead.msgnum":"\(dialog.messageNum)", "CryptData.data":cryptedData,
                        "CryptData.SegHead.seq":"999", "MsgHead.SegHead.seq":"1", "MsgTail.msgnum":"\(dialog.messageNum)",
                        "MsgTail.SegHead.seq":"\(lastSegNum)"
                    ] as [String : Any]
                    
                    if let md = dialog.syntax.msgs["Crypted"] {
                        if let msg_crypted = md.compose() as? HBCIMessage {
                            if buildCryptHead(msg_crypted, key: enc as Data) {
                                if msg_crypted.setElementValues(values) {
                                    let cryptedMsgData = msg_crypted.messageData();
                                    let sizeString = NSString(format: "%012d", cryptedMsgData.count) as String;
                                    if msg_crypted.setElementValue(sizeString, path: "MsgHead.msgsize") {
                                        return msg_crypted;
                                    }
                                }
                            }
                        }
                    } else {
                        logInfo("SyntaxFile error: Crypted message not found");
                    }
                } else {
                    logInfo("Encryption keys could not be determined from chipcard");
                }
            } else {
                logInfo("Dialog ID is not defined");
            }
        }
        return nil;
    }
    
    override func decryptMessage(_ rmsg:HBCIResultMessage, dialog:HBCIDialog) ->HBCIResultMessage? {
        if let cryptedData = rmsg.valueForPath("CryptData.data") as? NSData {
            if let enc = rmsg.valueForPath("CryptHead.CryptAlg.enckey") as? Data {
                if let plain = card.decryptKey(3, encrypted: enc as NSData) {
                    // decrypt message
                    let key = NSMutableData(data: plain as Data);
                    key.append(plain.bytes, length: 8);
                    
                    var decrypted = [UInt8](repeating: 0, count: cryptedData.length+8);
                    var plainSize = 0;
                  
                    let rv = CCCrypt(UInt32(kCCDecrypt), UInt32(kCCAlgorithm3DES), UInt32(0), key.bytes, 24, nil, cryptedData.bytes, cryptedData.length, &decrypted, cryptedData.length+8, &plainSize);
                    if Int(rv) != kCCSuccess {
                        logInfo("Decryption failed. Status: \(rv)");
                        return nil;
                    }
                    
                    let msgData = Data(bytes: UnsafePointer<UInt8>(decrypted), count: plainSize);
                    
                    let result = HBCIResultMessage(syntax: dialog.syntax);
                    if !result.parse(msgData) {
                        logInfo("Result Message could not be parsed");
                        logInfo(String(data: msgData, encoding: String.Encoding.isoLatin1));
                    }
                    return result;
                } else {
                    logInfo("Could not decrypt key");
                }
            } else {
                logInfo("Encryption key not found in message");
            }
        } else {
            // message is not encrypted
            return rmsg;
        }
        return nil;
    }


    
}
