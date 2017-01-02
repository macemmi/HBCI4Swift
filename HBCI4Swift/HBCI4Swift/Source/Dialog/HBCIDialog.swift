//
//  HBCIDialog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation



public class HBCIDialog {
    var connection:HBCIConnection!
    var dialogId:String?
    var user:HBCIUser;
    var hbciVersion:String!                 // todo: replace with let once Xcode bug is fixed
    var syntax:HBCISyntax!                  // todo: replace with let once Xcode bug is fixed
    var messageNum = 1;
    var orders = Array<HBCIOrder>();
    
    // the callback handler
    public static var callback:HBCICallback?
    
    public init(user:HBCIUser) throws {
        
        self.user = user;
        self.hbciVersion = user.hbciVersion;
        
        if user.securityMethod == nil {
            logError("Security method for user not defined");
            throw HBCIError.MissingData("SecurityMethod");
        }

        self.syntax = try HBCISyntax.syntaxWithVersion(hbciVersion);
        
        if user.securityMethod is HBCISecurityMethodDDV {
            self.connection = try HBCIDDVConnection(host: user.bankURL);
            return;
        } else {
            if let url = NSURL(string:user.bankURL) {
                self.connection = HBCIPinTanConnection(url: url);
                return;
            } else {
                logError("Could not create URL from \(user.bankURL)");
                throw HBCIError.BadURL(user.bankURL);
            }
        }
    }
    
    func sendMessage(message:String, values:Dictionary<String,AnyObject>) throws ->HBCIResultMessage? {
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
    
    func sendMessage(msg:HBCIMessage) throws ->HBCIResultMessage? {
        if !msg.enumerateSegments() {
            logError(msg.description);
            return nil;
        }
        
        if !user.securityMethod.signMessage(msg) {
            logError(msg.description);
            return nil;
        }
        if !msg.finalize() {
            logError(msg.description);
            return nil;
        }
        if !msg.validate() {
            logError(msg.description);
            return nil;
        }
        
        //println(msg.description)
        
        if let msg_crypted = user.securityMethod.encryptMessage(msg, dialog: self) {
            
            if !msg_crypted.validate() {
                logError(msg_crypted.description);
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
                            logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String);
                            logError("Message sent: " + msg.messageString());
                            return value;
                        }
                    }
                    logError("Message could not be decrypted");
                    logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String);
                    return nil;
                } else {
                    logError("Message could not be parsed");
                    logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String);
                    return nil;
                }
            } catch {
                logError("Message sent: " + msg.messageString());
            }
        }
        return nil;
    }

    public func dialogInit() throws ->HBCIResultMessage? {
        if user.sysId == nil {
            logError("Dialog Init failed: missing sysId");
            return nil;
        }
        
        var values:Dictionary<String,AnyObject> = ["Idn.KIK.country":"280", "Idn.KIK.blz":user.bankCode, "Idn.customerid":user.customerId,
            "Idn.sysid":user.sysId!, "Idn.sysStatus":"1", "ProcPrep.BPD":user.parameters.bpdVersion,
            "ProcPrep.UPD":user.parameters.updVersion, "ProcPrep.lang":"0", "ProcPrep.prodName":"PecuniaBanking",
            "ProcPrep.prodVersion":"100"
        ];
        
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
    
    public func dialogEnd() ->HBCIResultMessage? {
        if let dialogId = self.dialogId {
            let values:Dictionary<String,AnyObject> = ["DialogEnd.dialogid":dialogId, "MsgHead.dialogid":dialogId, "MsgHead.msgnum":messageNum, "MsgTail.msgnum":messageNum];
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
    
    public func syncInit() throws ->HBCIResultMessage? {
        user.tanMethod = "999";
        user.sysId = "0";
        
        let values:Dictionary<String,AnyObject> = ["Idn.KIK.country":"280", "Idn.KIK.blz":user.bankCode, "Idn.customerid":user.customerId,
            "Idn.sysid":"0", "Idn.sysStatus":"1", "ProcPrep.BPD":"0", "Sync.mode":0,
            "ProcPrep.UPD":"0", "ProcPrep.lang":"0", "ProcPrep.prodName":"PecuniaBanking",
            "ProcPrep.prodVersion":"100"
        ];
        
        self.dialogId = "0";
        
        if let result = try sendMessage("Synchronize", values: values) {
            if result.isOk() {
                result.updateParameterForUser(self.user);
                
                for seg in result.segments {
                    if seg.name == "SyncRes" {
                        user.sysId = seg.elementValueForPath("sysid") as? String;
                        if user.sysId == nil {
                            logError("SysID could not be found");
                        }
                    }
                }
                return result;
            }
        }
        return nil;
    }
    
    func segmentWithName(segName:String) ->HBCISegment? {
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
                logError("Process \(segName) is not supported");
                return nil;
            }
            // now sort the versions - we take the latest supported version
            supportedVersions.sortInPlace(>);
            
            if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                if let segment = sd.compose() as? HBCISegment {
                    segment.name = segName;
                    return segment;
                }
            }
        } else {
            logError("Segment \(segName) is not supported by HBCI4Swift");
        }
        return nil;
    }
    
    
    func customMessageForSegment(segName:String) ->HBCIMessage? {
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
                        logError("Process \(segName) is not supported");
                        return nil;
                    }
                    // now sort the versions - we take the latest supported version
                    supportedVersions.sortInPlace(>);
                    
                    if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                        if let segment = sd.compose() {
                            segment.name = segName;
                            msg.children.insert(segment, atIndex: 2);
                            return msg;
                        }
                    }
                } else {
                    logError("Segment \(segName) is not supported by HBCI4Swift");
                }
            }
        }
        return nil;
    }

    func sendCustomMessage(message:HBCICustomMessage) throws ->Bool {
        if let _ = try sendMessage(message) {
            return true;
        }
        return false;
    }
        
    
    
}
