//
//  HBCISecurityMethodDDV.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 13.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import RIPEMD
import CommonCrypto

public class HBCISecurityMethodDDV : HBCISecurityMethod {
    let user:HBCIUser;
    public var card:HBCISmartcardDDV!
    var sigKeyNumber:Int!;
    var sigKeyVersion:Int!;
    var cryptKeyNumber:Int!
    var cryptKeyVersion:Int!
    
    public init(user:HBCIUser) {
        self.user = user;
    }
    
    
    override func signMessage(msg:HBCIMessage) ->Bool {
        //let secref:String = NSString(format: "%d", arc4random());
        var version = 0;
        
        let secref = "\(arc4random())";
        
        if user.tanMethod == nil {
            logError("Signing failed: missing tanMethod");
            return false;
        }
        
        if let seg = msg.elementForPath("SigHead") as? HBCISegment {
            version = seg.version;
        } else {
            logError("SigHead segment not found");
            return false;
        }
        
        // get cid
        if card != nil {
            if card.cardID == nil {
                if !card.getCardID() {
                    logError("Card ID could not be determined");
                    return false;
                }
            }
            
            if sigKeyNumber == nil {
                let keys = card.getKeyData();
                if keys.count < 2 {
                    logError("Card keys could not be determined");
                    return false;
                }
                let sigKeys = keys[0];
                sigKeyNumber = Int(sigKeys.keyNumber);
                sigKeyVersion = Int(sigKeys.keyVersion);

                let cryptKeys = keys[1];
                cryptKeyNumber = Int(sigKeys.keyNumber);
                cryptKeyVersion = Int(sigKeys.keyVersion);
            }
            
            
        } else {
            logError("No chipcard assigned to DDV security method");
            return false;
        }
        
        // calculate message hash
        let msgData = msg.messageDataForSignature();
        let hash:NSData = RIPEMD.digest(msgData);
        
        // sign hash
        let signedHash = card.sign(hash);
        if signedHash == nil {
            logError("Message hash could not be signed");
            return false;
        }
        
        // get signature id
        let sigid = Int(card.getSignatureId());
        if !card.writeSignatureId(sigid+1) {
            logError("Unable to increment signature id");
            return false;
        }
        
        // setup sighead segment
        var values = ["SigHead.secfunc":"2",
            "SigHead.seccheckref":secref, " SigHead.range":"1", "SigHead.role":"1", "SigHead.SecIdnDetails.func":"1",
            "SigHead.SecIdnDetails.cid":card.cardID!, "SigHead.secref":sigid, "SigHead.SecTimestamp.type":"1",
            "SigHead.SecTimestamp.date":NSDate(), "SigHead.SecTimestamp.time":NSDate(), "SigHead.HashAlg.alg":"999",
            "SigHead.SigAlg.alg":"1", "SigHead.SigAlg.mode":"999", "SigHead.KeyName.country":"280",
            "SigHead.KeyName.blz":user.bankCode, "SigHead.KeyName.userid":user.userId, "SigHead.KeyName.keytype":"S",
            "SigHead.KeyName.keynum":sigKeyNumber, "SigHead.KeyName.keyversion":sigKeyVersion, "SigTail.seccheckref":secref,
            "SigHead.SecProfile.method":"DDV", "SigHead.SecProfile.version":"1",
            "SigTail.sig":signedHash!,
        ];
        
        return msg.setElementValues(values);

    }
    
    func buildCryptHead(msg:HBCIMessage, key:NSData) ->Bool {
        var values = [ "CryptHead.SegHead.seq":"998",
            "CryptHead.secfunc":"4", "CryptHead.role":"1", "CryptHead.SecIdnDetails.func":"1",
            "CryptHead.SecIdnDetails.cid":card.cardID!, "CryptHead.SecTimestamp.date":NSDate(), "CryptHead.SecTimestamp.time":NSDate(),
            "CryptHead.CryptAlg.mode":"2", "CryptHead.CryptAlg.alg":"13", "CryptHead.CryptAlg.enckey":key,
            "CryptHead.CryptAlg.keytype":"5", "CryptHead.KeyName.country":"280", "CryptHead.KeyName.blz":user.bankCode,
            "CryptHead.KeyName.userid":user.userId, "CryptHead.KeyName.keynum":cryptKeyNumber, "CryptHead.KeyName.keyversion":cryptKeyVersion,
            "CryptHead.SecProfile.method":"DDV", "CryptHead.SecProfile.version":"1",
            "CryptHead.compfunc":"0"
        ];
        
        return msg.setElementValues(values);
    }

    
    override func encryptMessage(msg:HBCIMessage, dialog:HBCIDialog) ->HBCIMessage? {
        if let lastSegNum = msg.lastSegmentNumber() {
            if let dialogId = dialog.dialogId {
                var cryptedData:NSData!
                let msgBody = msg.messageDataForEncryption();
                
                // encrypt message body
                if let (plain, enc) = card.getEncryptionKeys(3) {
                    // build 3DES key
                    var key = NSMutableData(data: plain);
                    key.appendBytes(plain.bytes, length: 8);
                    
                    //iv
                    //let iv = UnsafePointer<UInt8>(calloc(1, 8));
                    let encrypted = UnsafeMutablePointer<UInt8>.alloc(msgBody.length+8);
                    var encSize = 0;
                    
                    let rv = CCCrypt(UInt32(kCCEncrypt), UInt32(kCCAlgorithm3DES), UInt32(0), key.bytes, 24, nil, msgBody.bytes, msgBody.length, encrypted, msgBody.length+8, &encSize);
                    if Int(rv) != kCCSuccess {
                        logError("Encryption failed. Status: \(rv)");
                        encrypted.destroy();
                        return nil;
                    }
                    
                    cryptedData = NSData(bytes: encrypted, length: encSize);
                    encrypted.destroy();
                    
                    let values = ["MsgHead.dialogid":dialogId, "MsgHead.msgnum":"\(dialog.messageNum)", "CryptData.data":cryptedData,
                        "CryptData.SegHead.seq":"999", "MsgHead.SegHead.seq":"1", "MsgTail.msgnum":"\(dialog.messageNum)",
                        "MsgTail.SegHead.seq":"\(lastSegNum)"
                    ]
                    
                    if let md = dialog.syntax.msgs["Crypted"] {
                        if let msg_crypted = md.compose() as? HBCIMessage {
                            if buildCryptHead(msg_crypted, key: enc) {
                                if msg_crypted.setElementValues(values) {
                                    let cryptedData = msg_crypted.messageData();
                                    let sizeString = NSString(format: "%012d", cryptedData.length) as String;
                                    if msg_crypted.setElementValue(sizeString, path: "MsgHead.msgsize") {
                                        return msg_crypted;
                                    }
                                }
                            }
                        }
                    } else {
                        logError("SyntaxFile error: Crypted message not found");
                    }
                } else {
                    logError("Encryption keys could not be determined from chipcard");
                }
            } else {
                logError("Dialog ID is not defined");
            }
        }
        return nil;
    }
    
    override func decryptMessage(rmsg:HBCIResultMessage, dialog:HBCIDialog) ->HBCIResultMessage? {
        if let cryptedData = rmsg.valueForPath("CryptData.data") as? NSData {
            if let enc = rmsg.valueForPath("CryptHead.CryptAlg.enckey") as? NSData {
                if let plain = card.decryptKey(3, encrypted: enc) {
                    // decrypt message
                    var key = NSMutableData(data: plain);
                    key.appendBytes(plain.bytes, length: 8);
                    
                    let decrypted = UnsafeMutablePointer<UInt8>.alloc(cryptedData.length+8);
                    var plainSize = 0;
                  
                    let rv = CCCrypt(UInt32(kCCDecrypt), UInt32(kCCAlgorithm3DES), UInt32(0), key.bytes, 24, nil, cryptedData.bytes, cryptedData.length, decrypted, cryptedData.length+8, &plainSize);
                    if Int(rv) != kCCSuccess {
                        logError("Encryption failed. Status: \(rv)");
                        decrypted.destroy();
                        return nil;
                    }
                    
                    let msgData = NSData(bytes: decrypted, length: plainSize);
                    decrypted.destroy();
                    
                    var result = HBCIResultMessage(syntax: dialog.syntax);
                    if !result.parse(msgData) {
                        logError("Result Message could not be parsed");
                        logError(NSString(data: msgData, encoding: NSISOLatin1StringEncoding) as! String);
                    }
                    return result;
                } else {
                    logError("Could not decrypt key");
                }
            } else {
                logError("Encryption key not found in message");
            }
        } else {
            logError("Encrypted data not found in message");
        }
        return nil;
    }


    
}