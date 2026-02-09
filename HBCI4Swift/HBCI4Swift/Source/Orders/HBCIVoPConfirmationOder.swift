//
//  Untitled.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//

class HBCIVoPConfirmationOrder : HBCIOrder {
    public init?(message: HBCICustomMessage) {
        super.init(name: "VerificationOfPayeeConfirmation", message: message);

        if self.segment == nil {
            return nil;
        }
    }
    
    override func checkTANParameters() -> Bool {
        return true;
    }
    
    open func enqueue(vop_id : Data) -> Bool {
        if(!self.segment.setElementValue(vop_id, path: "vopid")) {
            logInfo("VoP ID could not be set");
            return false;
        }
        
        return msg.addVoPConfirmationOrder(self);
    }


}
