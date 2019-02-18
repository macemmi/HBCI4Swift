//
//  HBCIDialog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation



open class HBCIDialog {
    var connection:HBCIConnection!
    var dialogId:String?
    var user:HBCIUser;
    var hbciVersion:String!                 // todo: replace with let once Xcode bug is fixed
    var syntax:HBCISyntax!                  // todo: replace with let once Xcode bug is fixed
    var messageNum = 1;
    var orders = Array<HBCIOrder>();
    
    // the callback handler
    open static var callback:HBCICallback?
    
    public init(user:HBCIUser) throws {
        
        self.user = user;
        self.hbciVersion = user.hbciVersion;
        
        if user.securityMethod == nil {
            logDebug("Security method for user not defined");
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
                logDebug("Could not create URL from \(user.bankURL)");
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
            logDebug(msg.description);
            return nil;
        }
        
        if !user.securityMethod.signMessage(msg) {
            logDebug(msg.description);
            return nil;
        }
        if !msg.finalize() {
            logDebug(msg.description);
            return nil;
        }
        if !msg.validate() {
            logDebug(msg.description);
            return nil;
        }
        
        //print(msg.description)
        
        if let msg_crypted = user.securityMethod.encryptMessage(msg, dialog: self) {
            
            if !msg_crypted.validate() {
                logDebug(msg_crypted.description);
                return nil;
            }
            
            let msgData = msg_crypted.messageData();
            //print(msg_crypted.messageString());
            
            // send message to bank
            do {
                let result = try self.connection.sendMessage(msgData);
                
                let resultMsg_crypted = HBCIResultMessage(syntax: self.syntax);
                if resultMsg_crypted.parse(result) {
                    if let dialogId = resultMsg_crypted.valueForPath("MsgHead.dialogid") as? String {
                        self.dialogId = dialogId;
                    }
                    self.messageNum += 1;
                    if let value = user.securityMethod.decryptMessage(resultMsg_crypted, dialog: self) {
                        if value.checkResponses() {
                            return value
                        } else {
                            logError("Error message from bank");
                            logDebug(String(data:result, encoding:String.Encoding.isoLatin1));
                            logDebug(String(data: result, encoding: String.Encoding.isoLatin1));
                            logDebug("Message sent: " + msg.messageString());
                            return value;
                        }
                    }
                    logDebug("Message could not be decrypted");
                    logDebug(String(data: result, encoding: String.Encoding.isoLatin1));
                    return nil;
                } else {
                    logDebug("Message could not be parsed");
                    logDebug(String(data: result, encoding: String.Encoding.isoLatin1));
                    return nil;
                }
            } catch {
                logDebug("Message sent: " + msg.messageString());
            }
        }
        return nil;
    }

    open func dialogInit() throws ->HBCIResultMessage? {
        if user.sysId == nil {
            logDebug("Dialog Init failed: missing sysId");
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
                                                   "ProcPrep.prodName":"PecuniaBanking",
                                                   "ProcPrep.prodVersion":"100" ];
        
        if user.securityMethod is HBCISecurityMethodDDV {
            values["Idn.sysStatus"] = "0";
        }
        
        self.dialogId = "0";
        
        if let result = try sendMessage("DialogInit", values: values) {
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
                                             "ProcPrep.prodName":"PecuniaBanking",
                                             "ProcPrep.prodVersion":"100"];
        
        self.dialogId = "0";
        
        if let result = try sendMessage("Synchronize", values: values) {
            if result.isOk() {
                result.updateParameterForUser(self.user);
                
                for seg in result.segments {
                    if seg.name == "SyncRes" {
                        user.sysId = seg.elementValueForPath("sysid") as? String;
                        if user.sysId == nil {
                            logDebug("SysID could not be found");
                        }
                    }
                }
                return result;
            }
        }
        return nil;
    }
    
    func segmentWithName(_ segName:String) ->HBCISegment? {
        if let segVersions = self.syntax.segs[segName] {
            // now find the right segment version
            // check which segment versions are supported by the bank
            var supportedVersions = Array<Int>();
            for seg in user.parameters.bpSegments {
                if seg.name == segName+"Par" {
                    // check if this version is also supported by us
                    if segVersions.isVersionSupported(seg.version) {
                        supportedVersions.append(seg.version);
                    }
                }
            }
            
            if supportedVersions.count == 0 {
                // this process is not supported by the bank
                logDebug("Process \(segName) is not supported");
                return nil;
            }
            // now sort the versions - we take the latest supported version
            supportedVersions.sort(by: >);
            
            if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                if let segment = sd.compose() as? HBCISegment {
                    segment.name = segName;
                    return segment;
                }
            }
        } else {
            logDebug("Segment \(segName) is not supported by HBCI4Swift");
        }
        return nil;
    }
    
    
    func customMessageForSegment(_ segName:String) ->HBCIMessage? {
        if let md = self.syntax.msgs["CustomMessage"] {
            if let msg = md.compose() as? HBCIMessage {
                if let segVersions = self.syntax.segs[segName] {
                    // now find the right segment version
                    // check which segment versions are supported by the bank
                    var supportedVersions = Array<Int>();
                    for seg in user.parameters.bpSegments {
                        if seg.name == segName+"Par" {
                            // check if this version is also supported by us
                            if segVersions.isVersionSupported(seg.version) {
                                supportedVersions.append(seg.version);
                            }
                        }
                    }
                    
                    if supportedVersions.count == 0 {
                        // this process is not supported by the bank
                        logDebug("Process \(segName) is not supported");
                        return nil;
                    }
                    // now sort the versions - we take the latest supported version
                    supportedVersions.sort(by: >);
                    
                    if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                        if let segment = sd.compose() {
                            segment.name = segName;
                            msg.children.insert(segment, at: 2);
                            return msg;
                        }
                    }
                } else {
                    logDebug("Segment \(segName) is not supported by HBCI4Swift");
                }
            }
        }
        return nil;
    }

    func sendCustomMessage(_ message:HBCICustomMessage) throws ->Bool {
        if let _ = try sendMessage(message) {
            return true;
        }
        return false;
    }
        
    
    
}
