//
//  HBCITanMediaOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 10.04.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCITanMediaOrder : HBCIOrder {
    public var accountNumber:String?,
    accountSubNumber:String?,
    bankCode:String?,
    mediaType:String?,
    mediaCategory:String?
    
    // result
    public var tanMedia = Array<HBCITanMedium>();
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "TANMediaList", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() ->Bool {
        /*
        if bankCode == nil || accountNumber == nil {
            logError(self.name + " order has no BLZ or Account information");
            return false;
        }
        
        // check if order is supported
        if !user.parameters.isOrderSupportedForAccount(self, number: accountNumber!, subNumber: accountSubNumber) {
            logError(self.name + " is not supported for account " + accountNumber!);
            return false;
        }
        */
        if segment.version >= 4 {
            if let cat = self.mediaCategory {
                segment.setElementValue(cat, path: "mediacategory");
            } else {
                logError("TAN media category not provided");
                return false;
            }
        }
        
        if let type = self.mediaType {
            segment.setElementValue(type, path: "mediatype");
        } else {
            logError("TAN media type is not provided");
            return false;
        }
        msg.addOrder(self);
        return true;
    }
    
    override func updateResult(result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let retSeg = self.resultSegment {
            let degs = retSeg.elementsForPath("MediaInfo");
            for deg in degs {
                if let medium = HBCITanMedium(element: deg) {
                    tanMedia.append(medium);
                }
            }
        }
    }

    

}
