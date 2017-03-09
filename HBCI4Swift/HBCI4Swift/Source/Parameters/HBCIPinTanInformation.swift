//
//  HBCIPinTanInformation.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 09.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

// information in HIPINS segment
open class HBCIPinTanInformation {
    open var pinlen_min:Int?
    open var pinlen_max:Int?
    open var tanlen_max:Int?
    open var text_userId:String?
    open var text_customerId:String?
    open var version:Int?
    
    open var supportedSegs = Dictionary<String, Bool>();

    
    init(segment: HBCISegment) {
        if segment.name != "PinTanInformation_old" {
            version = segment.elementValueForPath("SegHead.version") as? Int;
            pinlen_min = segment.elementValueForPath("PinTanInfo.pinlen_min") as? Int;
            pinlen_max = segment.elementValueForPath("PinTanInfo.pinlen_max") as? Int;
            tanlen_max = segment.elementValueForPath("PinTanInfo.tanlen_max") as? Int;
            text_userId = segment.elementValueForPath("PinTanInfo.info_userid") as? String;
            text_customerId = segment.elementValueForPath("PinTanInfo.info_customerid") as? String;
        }
        
        var segs = segment.elementsForPath("PinTanInfo.PinTanGV");
        if segs.count == 0 {
            // check for older version
            segs = segment.elementsForPath("PinTanGV");
        }
        
        for seg in segs {
            let code = seg.elementValueForPath("segcode") as? String;
            let needTan = seg.elementValueForPath("needtan") as? Bool;
            if code != nil && needTan != nil {
                supportedSegs[code!] = needTan!;
            }
        }
    }
}
