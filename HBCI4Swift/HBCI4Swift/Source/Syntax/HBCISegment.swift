//
//  HBCISegment.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 01.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISegment: HBCISyntaxElement {
    let code:String;
    let version:Int;
    
    override init(description: HBCISyntaxElementDescription) {
        let sd = description as! HBCISegmentDescription;
        code = sd.code;
        version = sd.version;
        super.init(description: description);
    }

    
    override func elementDescription() -> String {
        let name = self.name ?? "none";
        return "SEG name: \(name)\n";
    }
    

}
