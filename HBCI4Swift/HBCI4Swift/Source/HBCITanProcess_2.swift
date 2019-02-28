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
    
    func processOrder(_ order:HBCIOrder) throws ->Bool {
        // create message with order and HKTAN
        if let msg = HBCICustomMessage.newInstance(dialog) {

            // add original order
            msg.addOrder(order);
            
            if let tanOrder = HBCITanOrder(message: msg) {
                tanOrder.process = "4";
                
                var zkaName:String?
                var flicker:String?
                
                // do we need tan medium information?
                let parameters = dialog.user.parameters;
                if let processInfos = parameters.tanProcessInfos, let secfunc = dialog.user.tanMethod {
                    for tanMethod in processInfos.tanMethods {
                        if tanMethod.identifier == secfunc {
                            // check parameters for the selected Tan Method
                            let needMedia = tanMethod.needTanMedia ?? "0";
                            let numMedia = tanMethod.numActiveMedia ?? 0;
                            if needMedia == "2" && numMedia > 0 {
                                tanOrder.tanMediumName = dialog.user.tanMediumName;
                            }
                            
                            zkaName = tanMethod.zkaMethodName;
                        }
                    }
                }
                
                // now add Tan order to the same message
                if !tanOrder.enqueue() {
                    return false;
                }
                
                // now send message
                do {
                    if !(try msg.sendNoTan()) { return false };
                } catch {
                    logInfo("Error sending first TAN step message");
                    return false;
                }
                // check if we have a valid reference
                if tanOrder.orderRef == nil {
                    logInfo("TAN order reference could not be determined");
                    return false;
                }
                
                // now we need the TAN -> callback
                if let zkaName = zkaName {
                    if zkaName.substringToIndex(3) == "HHD" {
                        if tanOrder.challenge_hhd_uc == nil {
                            logWarning("ZKA method name is \(zkaName) but no HHD challenge - we nevertheless go on");
                            flicker = parseFlickerCode(tanOrder.challenge, hhduc: nil);
                        }
                    }
                }
                if let hhduc = tanOrder.challenge_hhd_uc {
                    flicker = parseFlickerCode(tanOrder.challenge, hhduc: hhduc);
                }
                let tan = try HBCIDialog.callback!.getTan(dialog.user, challenge: tanOrder.challenge, challenge_hdd_uc: flicker);
                    
                if let tanMsg = HBCICustomMessage.newInstance(dialog) {
                    if let tanOrder2 = HBCITanOrder(message: tanMsg) {
                        tanOrder2.process = "2";
                        tanOrder2.orderRef = tanOrder.orderRef;
                        
                        // add order to message
                        if !tanOrder2.enqueue() { return false; }
                        
                        // now send TAN
                        tanMsg.tan = tan;
                        do {
                            if try tanMsg.sendNoTan() {
                                // now we need to extract the return segment for the original order
                                order.updateResult(tanMsg.result!);
                                return true;
                            } else {
                                return false;
                            }
                        } catch {
                            // order could not be sent
                            logInfo("Error sending second TAN step message");
                        }
                    }
                }
            }
        }
        return false;
    }
}
