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
    
    func processOrder(order:HBCIOrder, error:NSErrorPointer) ->Bool {
        // create message with order and HKTAN
        if let msg = HBCICustomMessage.newInstance(dialog) {

            // add original order
            msg.addOrder(order);
            
            if let tanOrder = HBCITanOrder(message: msg) {
                tanOrder.process = "4";
                
                // do we need tan medium information?
                var tanMediumNameNeeded = false;
                let parameters = dialog.user.parameters;
                if let processInfos = parameters.tanProcessInfos, secfunc = dialog.user.tanMethod {
                    for tanMethod in processInfos.tanMethods {
                        if tanMethod.identifier == secfunc {
                            // check parameters for the selected Tan Method
                            let needMedia = tanMethod.needTanMedia ?? "0";
                            let numMedia = tanMethod.numActiveMedia ?? 0;
                            if needMedia == "2" && numMedia > 0 {
                                tanOrder.tanMediumName = dialog.user.tanMediumName;
                            }
                        }
                    }
                }
                
                // now add Tan order to the same message
                if !tanOrder.enqueue() {
                    return false;
                }
                
                // now send message
                if msg.sendNoTan(error) {
                    // check if we have a valid reference
                    if tanOrder.orderRef == nil {
                        logError("TAN order reference could not be determined");
                        return false;
                    }
                    
                    // now we need the TAN -> callback
                    let tan = HBCIDialog.callback!.getTan(dialog.user.userId, challenge: tanOrder.challenge, challenge_hdd_uc: tanOrder.challenge_hdd_uc);
                    
                    if let tanMsg = HBCICustomMessage.newInstance(dialog) {
                        if let tanOrder2 = HBCITanOrder(message: tanMsg) {
                            tanOrder2.process = "2";
                            tanOrder2.orderRef = tanOrder.orderRef;
                            
                            // add order to message
                            tanOrder2.enqueue();
                            
                            // now send TAN
                            tanMsg.tan = tan;
                            if tanMsg.sendNoTan(error) {
                                // now we need to extract the return segment for the original order
                                order.updateResult(tanMsg.result!);
                                return true;
                            } else {
                                // order could not be sent
                                logError("Error sending second TAN step message");
                            }
                        }
                    }
                } else {
                    logError("Error sending first TAN step message");
                }
            }
        }
        return false;
    }
}
