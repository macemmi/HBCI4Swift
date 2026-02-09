//
//  HBCIVoPParameters.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 06.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//

class HBCIVoPParameters {
    public
    let segments: [String]!
    let supportedFormats: [String]!
    
    init(segment:HBCISegment) {
        self.segments = segment.elementValuesForPath("ParVerificationOfPayee.vop_segment") as? [String];
        if let formats = segment.elementValueForPath("ParVerificationOfPayee.supportedstatusformats") as? String {
            self.supportedFormats = formats.components(separatedBy: ",");
        } else {
            self.supportedFormats = [];
        }
    }

}
