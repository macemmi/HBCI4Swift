//
//  HBCIDialog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation



open class HBCIDialog {
    let product:String;
    let version:String;
    var connection:HBCIConnection!
    var dialogId:String?
    var user:HBCIUser;
    var hbciVersion:String!                 // todo: replace with let once Xcode bug is fixed
    var syntax:HBCISyntax!                  // todo: replace with let once Xcode bug is fixed
    var messageNum = 1;
    var orders = Array<HBCIOrder>();
    
    // the callback handler
    public static var callback:HBCICallback?
    
    public init(user:HBCIUser, product:String, version:String = "100") throws {
        self.product = product;
        self.version = version;
        self.user = user;
        self.hbciVersion = user.hbciVersion;
        
        if user.securityMethod == nil {
            logInfo("Security method for user not defined");
            throw HBCIError.missingData("SecurityMethod");
        }

        self.syntax = try HBCISyntax.syntaxWithVersion(hbciVersion);
        
        if user.securityMethod is HBCISecurityMethodDDV {
            self.connection = try HBCIDDVConnection(host: user.bankURL);
            return;
        } else {
            if let url = URL(string:user.bankURL) {
                self.connection = HBCIPinTanConnection(url: url);
                return;
            } else {
                logInfo("Could not create URL from \(user.bankURL)");
                throw HBCIError.badURL(user.bankURL);
            }
        }
    }
    
    func sendMessage(_ message:String, values:Dictionary<String,Any>) throws ->HBCIResultMessage? {
        if let md = self.syntax.msgs[message] {
            if let msg = md.compose() as? HBCIMessage {
                for (path, value) in values {
                    if !msg.setElementValue(value, path: path) {
                        return nil;
                    }
                }
                return try sendMessage(msg);
            }
        }
        return nil;
    }
    
    func sendMessage(_ msg:HBCIMessage) throws ->HBCIResultMessage? {
        if !msg.enumerateSegments() {
            logInfo(msg.description);
            return nil;
        }
        
        if !user.securityMethod.signMessage(msg) {
            logInfo(msg.description);
            return nil;
        }
        if !msg.finalize() {
            logInfo(msg.description);
            return nil;
        }
        if !msg.validate() {
            logInfo(msg.description);
            return nil;
        }
        
        logDebug("Message payload:");
        logDebug(msg.messageString());
        
        if let msg_crypted = user.securityMethod.encryptMessage(msg, dialog: self) {
            
            if !msg_crypted.validate() {
                logInfo(msg_crypted.description);
                return nil;
            }
            
            let msgData = msg_crypted.messageData();
            logDebug("Encrypted message:");
            logDebug(msg_crypted.messageString());
            
            // send message to bank
            do {
                let result = try self.connection.sendMessage(msgData);
                logDebug("Message received:");
                logDebug(String(data: result, encoding: String.Encoding.isoLatin1));
                
                let resultMsg_crypted = HBCIResultMessage(syntax: self.syntax);
                if resultMsg_crypted.parse(result) {
                    if let dialogId = resultMsg_crypted.valueForPath("MsgHead.dialogid") as? String {
                        self.dialogId = dialogId;
                    }
                    self.messageNum += 1;
                    if let value = user.securityMethod.decryptMessage(resultMsg_crypted, dialog: self) {
                        if value.checkResponses() {
                            logDebug("Result Message:");
                            logDebug(value.description);
                            return value
                        } else {
                            logError("Banknachricht");
                            logInfo(String(data:result, encoding:String.Encoding.isoLatin1));
                            logInfo(String(data: result, encoding: String.Encoding.isoLatin1));
                            logInfo("Message sent: " + msg.messageString());
                            return value;
                        }
                    }
                    logInfo("Message could not be decrypted");
                    logInfo(String(data: result, encoding: String.Encoding.isoLatin1));
                    return nil;
                } else {
                    logInfo("Message could not be parsed");
                    logInfo(String(data: result, encoding: String.Encoding.isoLatin1));
                    return nil;
                }
            } catch {
                logInfo("Message sent: " + msg.messageString());
            }
        }
        return nil;
    }

    open func dialogInit() throws ->HBCIResultMessage? {
        if user.sysId == nil {
            logInfo("Dialog Init failed: missing sysId");
            return nil;
        }
        
        var values:Dictionary<String,Any> = ["Idn.KIK.country":"280",
                                               "Idn.KIK.blz":user.bankCode,
                                               "Idn.customerid":user.customerId,
                                               "Idn.sysid":user.sysId!,
                                               "Idn.sysStatus":"1",
                                               "ProcPrep.BPD":user.parameters.bpdVersion,
                                               "ProcPrep.UPD":user.parameters.updVersion,
                                               "ProcPrep.lang":"0",
                                               "ProcPrep.prodName":product,
                                               "ProcPrep.prodVersion":version ];
        
        if user.securityMethod is HBCISecurityMethodDDV {
            values["Idn.sysStatus"] = "0";
        }
        
        self.dialogId = "0";
        
        guard let msg = HBCIDialogInitMessage.newInstance(self) else {
            logInfo("Dialog Init failed: message could not be created");
            return nil;
        }
        if !msg.setElementValues(values) {
            logInfo("Dialog Init failed: messages values could not be set)");
            return nil;
        }
        guard try msg.send() else {
            logInfo("Dialog Init failed: message could not be sent");
            return nil;
        }
        if let result = msg.result {
            if result.isOk() {
                result.updateParameterForUser(self.user);
                return result;
            }
        }
        return nil;
    }
    
    open func dialogEnd() ->HBCIResultMessage? {
        if let dialogId = self.dialogId {
            let values:Dictionary<String,Any> = ["DialogEnd.dialogid":dialogId,
                                                 "MsgHead.dialogid":dialogId,
                                                 "MsgHead.msgnum":messageNum,
                                                 "MsgTail.msgnum":messageNum];
            do {
                if let result = try sendMessage("DialogEnd", values: values) {
                    self.connection.close();
                    return result;
                }
            } catch { };
        }
        self.connection.close();
        return nil;
    }
    
    open func syncInit() throws ->HBCIResultMessage? {
        user.tanMethod = "999";
        user.sysId = "0";
        
        let values:Dictionary<String,Any> = ["Idn.KIK.country":"280",
                                             "Idn.KIK.blz":user.bankCode,
                                             "Idn.customerid":user.customerId,
                                             "Idn.sysid":"0",
                                             "Idn.sysStatus":"1",
                                             "ProcPrep.BPD":"0",
                                             "Sync.mode":0,
                                             "ProcPrep.UPD":"0",
                                             "ProcPrep.lang":"0",
                                             "ProcPrep.prodName":product,
                                             "ProcPrep.prodVersion":version];
        
        self.dialogId = "0";
        
        if let result = try sendMessage("Synchronize", values: values) {
            if result.isOk() {
                result.updateParameterForUser(self.user);
                
                for seg in result.segments {
                    if seg.name == "SyncRes" {
                        user.sysId = seg.elementValueForPath("sysid") as? String;
                        if user.sysId == nil {
                            logInfo("SysID could not be found");
                        }
                    }
                }
                return result;
            }
        }
        return nil;
    }
    
}
