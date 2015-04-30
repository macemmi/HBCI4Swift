//
//  HBCITanProcessInformation.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

enum HashMode:String {
    case NONE = "0", RIPEMD160 = "1", SHA1 = "2"
}

import Foundation

// Information in HITANS segment
class HBCITanProcessInformation {
    var version:Int?
    var orderHashMode = HashMode.NONE;
    var tanMethods = Array<HBCITanMethod>();
    
    init(segment:HBCISegment) {
        version = segment.elementValueForPath("SegHead.version") as? Int;
        if let s = segment.elementValueForPath("ParTAN.orderhashmode") as? String {
            self.orderHashMode = HashMode(rawValue: s) ?? HashMode.NONE;
        }
        
        let procs = segment.elementsForPath("ParTAN.TANProcessParams");
        for proc in procs {
            if let method = HBCITanMethod(element: proc, version:version!) {
                tanMethods.append(method);
            }
        }
    }
}