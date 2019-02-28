//
//  HBCITanMediaOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 10.04.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCITanMediaOrder : HBCIOrder {
    open var mediaType:String?
    open var mediaCategory:String?
    
    // result
    open var tanMedia = Array<HBCITanMedium>();
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "TANMediaList", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    open func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupported(self) {
            logInfo(self.name + " is not supported for user " + user.userId);
            return false;
        }
        
        if segment.version >= 4 {
            if let cat = self.mediaCategory {
                if !segment.setElementValue(cat, path: "mediacategory") { return false; }
            } else {
                logInfo("TAN media category not provided");
                return false;
            }
        }
        
        if let type = self.mediaType {
            if !segment.setElementValue(type, path: "mediatype") { return false; }
        } else {
            logInfo("TAN media type is not provided");
            return false;
        }
        msg.addOrder(self);
        return true;
    }
    
    override open func updateResult(_ result:HBCIResultMessage) {
        super.updateResult(result);
        
        if let retSeg = resultSegments.first {
            let version = retSeg.elementValueForPath("SegHead.version") as? Int;
            let degs = retSeg.elementsForPath("MediaInfo");
            for deg in degs {
                if let medium = HBCITanMedium(element: deg, version: version!) {
                    tanMedia.append(medium);
                }
            }
        }
    }

    

}
