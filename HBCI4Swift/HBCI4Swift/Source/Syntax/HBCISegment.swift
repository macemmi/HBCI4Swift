//
//  HBCISegment.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 01.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCISegment: HBCISyntaxElement {
    public let code:String;
    public let version:Int;
    
    override init(description: HBCISyntaxElementDescription) {
        let sd = description as! HBCISegmentDescription;
        code = sd.code;
        version = sd.version;
        super.init(description: description);
    }

    
    override func elementDescription() -> String {
        return "SEG name: \(self.name)\n";
    }
    

}
