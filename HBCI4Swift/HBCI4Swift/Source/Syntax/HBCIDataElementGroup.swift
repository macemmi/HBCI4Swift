//
//  HBCIDataElementGroup.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 29.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIDataElementGroup: HBCISyntaxElement {
    override func elementDescription() -> String {
        return "DEG name: \(self.name)\n";
    }
}
