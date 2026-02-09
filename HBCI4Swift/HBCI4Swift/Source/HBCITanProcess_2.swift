//
//  HBCITanProcess_2.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCITanProcess_2 {
    let dialog:HBCIDialog;
    
    init(dialog:HBCIDialog) {
        self.dialog = dialog;
    }

    // parse flicker code out of hhduc (preferred) or challenge (if hhduc is not available)
    func parseFlickerCode(_ challenge:String?, hhduc:Data?) ->String? {

        // hhduc has priority. available from HITAN4
        if let hhduc = hhduc {
            if let s = String(data: hhduc, encoding: String.Encoding.ascii) {
                let trimmed = s.trimmingCharacters(in: CharacterSet.whitespaces);
                if trimmed.count > 0 {
                    do {
                        let code = try HBCIFlickerCode(code: trimmed);
                        return try code.render();
                    }
                    catch {
                        logInfo("Unable to parse flicker code \(trimmed)");
                        return nil;
                    }
                }                
            }
        }
        
        // check if challenge contains something to parse
        if let challenge = challenge {
            let trimmed = challenge.trimmingCharacters(in: CharacterSet.whitespaces);
            if trimmed.count > 0 {
                do {
                    let code = try HBCIFlickerCode(code: trimmed);
                    return try code.render();
                }
                catch {
                    return nil;
                }
            }
        }
        return nil;
    }
    

    func processDecoupledMessage(_ msg:HBCICustomMessage, order:HBCIOrder?, tanOrder:HBCITanOrder) throws -> Bool {
        guard let tanMsg = HBCICustomMessage.newInstance(dialog) else {
            logDebug("processDecoupledMessage: customer message could not be created");
            return false;
        }
        guard let tanOrder2 = HBCITanOrder(message: tanMsg) else {
            logDebug("processDecoupledMessage: TAN order could not be created");
            return false;
        }
        
        guard let secfunc = dialog.user.tanMethod else {
            logError("No TAN method specified");
            return false;
        }
        
        guard let tanMethod = dialog.user.parameters.getTanMethod(secfunc: secfunc) else {
            logError("No TAN process parameters available for secfunc \(secfunc)");
            return false;
        }
        HBCIDialog.callback!.decoupledNotification(msg.dialog.user, challenge: tanOrder.challenge);
        
        tanOrder2.process = "S";
        tanOrder2.orderRef = tanOrder.orderRef;
        
        // add order to message
        if !tanOrder2.enqueue() { return false; }
        
        let maxcount = tanMethod.maxPollsDecoupled != nil ? tanMethod.maxPollsDecoupled! : 100;
        //let wait = tanMethod.waitDecoupled != nil ? tanMethod.waitDecoupled! : 3;
        var wait = tanMethod.waitDecoupled ?? 3;
        if wait < 2 {
            wait = 2;
        }
        
        var count = 0
        sleep(UInt32(wait));
        do {
            var accepted = false;
            while !accepted && count < maxcount {
                if try tanMsg.sendNoTan() {
                    // check response
                    var doWait = false;
                    if let responses = tanMsg.result?.segmentResponses {
                        for response in responses {
                            if response.code == "3956" {
                                logDebug("response code 3956 found - we wait...")
                                doWait = true;
                            }
                        }
                    }
                    if !doWait {
                        accepted = true;
                        continue;
                    }
                } else {
                    // error or user did reject
                    return false;
                }
                sleep(UInt32(wait));
                count += 1;
            }
            if count == maxcount {
                logError("Wartezeit überschritten");
                return false;
            }
            
            logDebug("response code 3956 not found - we continue...");
            
            // now we need to extract the return segment for the original order
            order?.updateResult(tanMsg.result!);
            
            // update original message with result
            msg.result = tanMsg.result!;
            return true;
        } catch {
            // order could not be sent
            logInfo("Error sending second TAN step message");
            throw error;
        }
    }
    
    func processMessage(_ msg:HBCICustomMessage, _ order:HBCIOrder?) throws ->Bool {
        
        guard let vopOrder = HBCIVoPRequestOrder(message: msg) else {
            logDebug("VoPRequestOrder could not be created");
            return false }
        guard let tanOrder = HBCITanOrder(message: msg) else {
            logDebug("TAN Order could not be created");
            return false }
        tanOrder.process = "4";
        
        var hhducString:String?
        var tanMethodID = "";
        var zkaName = "";
        var challengeType:HBCIChallengeType = .none;
        
        var vopRequired = msg.isVoPRequired();
        
        // do we need tan medium information?
        let parameters = dialog.user.parameters;
        
        guard let secfunc = dialog.user.tanMethod else {
            logError("No TAN method specified");
            return false;
        }
        
        guard let tanMethod = parameters.getTanMethod(secfunc: secfunc) else {
            logError("No TAN process parameters available for secfunc \(secfunc)");
            return false;
        }
        
        logDebug("we work with secfunc \(secfunc)");
        
        let needMedia = tanMethod.needTanMedia ?? "0";
        if needMedia == "2" {
            tanOrder.tanMediumName = dialog.user.tanMediumName;
            if tanOrder.tanMediumName == nil {
                tanOrder.tanMediumName = "noref";
            }
            logDebug("we work with TanMediumName \(tanOrder.tanMediumName ?? "<none>")");
        }
        
        
        tanMethodID = tanMethod.identifier;
        if let name = tanMethod.zkaMethodName {
            zkaName = name;
        }
        
        logDebug("tanMethodID is \(tanMethodID)");
        
        // now add Tan order to the same message
        if !msg.addTanOrder(tanOrder) {
            return false;
        }
        
        // add VoP
        if vopRequired {
            logDebug("VoP is required");
            if(!vopOrder.enqueue()) {
                return false;
            }
        }
        
        // now send message
        do {
            if !(try msg.sendNoTan()) { return false };
        } catch {
            logInfo("Error sending first TAN step message");
            throw error;
        }
                        
        guard var result = msg.result else { return false }
        
        if result.hasSegmentResponseWithCode("3091") {
            logDebug("response code 3091 received - no VoP required");
            vopRequired = false;
        }
        
        if vopRequired {
            if vopOrder.vop_id == nil {
                logInfo("VoP is required but no vop id available");
                return false;
            }
            guard let vopResult = vopOrder.result else {
                logInfo("VoP is required but vop result could not be determined");
                return false;
            }

            // VoP Confirmation
            let vopCallbackResult = HBCIDialog.callback!.vopConfirmation(vopResult);
            switch vopCallbackResult {
            case .abort:
                logError("Abbruch durch Benutzer");
                return false;
            case .replace:
                if msg.updateRemoteNameForVoP(vopResult: vopResult) {
                    logError("Korrektur der Nachricht nicht möglich, bitte Überweisung ändern und neu senden");
                    return false;
                }
                break;
            case .proceed: break
            }
            
            if result.hasSegmentResponseWithCode("3945") {
                // change message, replace vop request by vop confirmation
                guard let vopConfOrder = HBCIVoPConfirmationOrder(message: msg) else {
                    logInfo("was not able to create VoP confirmation order")
                    return false;
                }
                if !vopConfOrder.enqueue(vop_id: vopOrder.vop_id!) {
                    logInfo("was not able to enqeue VoP confirmation order")
                    return false;
                }

                // now send VoP confirmation message
                logDebug("send VoP confirmation message");
                do {
                    if !(try msg.sendNoTan()) { return false };
                } catch {
                    logInfo("Error sending first TAN step message");
                    throw error;
                }
                
                // check message result
                if let res = msg.result {
                    result = res;
                } else {
                    return false;
                }
                
                vopRequired = false;   // no further vop handling required
            }
        }
        
        // check if we have a valid reference
        if tanOrder.orderRef == nil {
            // check if we have a HITAN segment at all...
            if let segments = msg.result?.segmentsWithName("TAN"), segments.count > 0 {
                logInfo("TAN order reference could not be determined");
                return false;
            } else {
                return true;
            }
        }

        // check if we need to have a TAN
        if tanOrder.hasResponseWithCode("3076") {
            // if that response is sent back, we don't need a TAN
            logInfo("Response 3076 found - no TAN needed");
            // if TAN is not needed, the update did already happen during sendNoTan above
            //order?.updateResult(msg.result!);
            return true;
        }
        
        if tanOrder.challenge == "nochallenge" {
            // if that response is sent back, we don't need a TAN
            logInfo("Value 'nochallenge' found - no TAN needed");
            // if TAN is not needed, the update did already happen during sendNoTan above
            //order?.updateResult(msg.result!);
            return true;
        }
        
        // now we need the TAN -> callback
        if tanMethodID.prefix(3) == "HHD" && tanMethodID.suffix(3) == "OPT" {
            challengeType = .flicker;
            if tanOrder.challenge_hhd_uc == nil {
                logInfo("TAN method is \(tanMethodID) but no HHD challenge - we nevertheless go on");
            }
            // try to parse flicker code out of HHD_UC or challenge itself
            hhducString = parseFlickerCode(tanOrder.challenge, hhduc: tanOrder.challenge_hhd_uc);
            if hhducString == nil {
                logWarning("TAN method is \(tanMethodID) but no HHD challenge");
            }
            // check if HHDUC is part of the challenge string and if yes, remove it
            if let challenge = tanOrder.challenge, let index = challenge.range(of: "CHLGTEXT") {
                logDebug("Challenge contains HHDUC data - remove that: \(challenge)");
                let newIndex = challenge.index(index.lowerBound, offsetBy: 10);
                tanOrder.challenge = String(challenge.suffix(from: newIndex));
            }
        }
        if tanMethodID.prefix(2) == "MS" {
            challengeType = .photo;
            if let hhduc = tanOrder.challenge_hhd_uc {
                hhducString = hhduc.base64EncodedString();
                if hhducString == nil {
                    logInfo("TanMethod is \(tanMethodID) but hhducString data is empty!");
                }
            } else {
                logInfo("TanMethod is \(tanMethodID) but HHDUC is empty!");
            }
        }
        if tanMethodID.hasPrefix("DECOUPLED") || zkaName.hasPrefix("Decoupled") {
            return try processDecoupledMessage(msg, order: order, tanOrder: tanOrder);
        }
        
        let tan = try HBCIDialog.callback!.getTan(dialog.user, challenge: tanOrder.challenge, challenge_hhd_uc: hhducString, type: challengeType);
        
        if let tanMsg = HBCICustomMessage.newInstance(dialog) {
            if let tanOrder2 = HBCITanOrder(message: tanMsg) {
                tanOrder2.process = "2";
                tanOrder2.orderRef = tanOrder.orderRef;
                
                // add order to message
                if !tanOrder2.enqueue() { return false; }

                if vopRequired {
                    if let vop_id = vopOrder.vop_id {
                        if let vopConfOrder = HBCIVoPConfirmationOrder(message: tanMsg) {
                            if !vopConfOrder.enqueue(vop_id: vop_id) {
                                return false;
                            }
                        }
                    }
                }
                                
                // now send TAN
                tanMsg.tan = tan;
                do {
                    if try tanMsg.sendNoTan() {
                        // now we need to extract the return segment for the original order
                        order?.updateResult(tanMsg.result!);
                        
                        // update original message with result
                        msg.result = tanMsg.result!;
                        return true;
                    } else {
                        return false;
                    }
                } catch {
                    // order could not be sent
                    logInfo("Error sending second TAN step message");
                    throw error;
                }
            }
        }
        return false;
    }
}



