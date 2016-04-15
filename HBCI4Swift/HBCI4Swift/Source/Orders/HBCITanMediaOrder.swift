//
//  HBCITanMediaOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 10.04.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCITanMediaOrder : HBCIOrder {
    public var mediaType:String?
    public var mediaCategory:String?
    
    // result
    public var tanMedia = Array<HBCITanMedium>();
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "TANMediaList", message: message);
        if self.segment == nil {
            return nil;
        }
    }
    
    public func enqueue() ->Bool {
        // check if order is supported
        if !user.parameters.isOrderSupported(self) {
            logError(self.name + " is not supported for user " + user.userId);
            return false;
        }
        
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
    
    override public func updateResult(result:HBCIResultMessage) {
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
