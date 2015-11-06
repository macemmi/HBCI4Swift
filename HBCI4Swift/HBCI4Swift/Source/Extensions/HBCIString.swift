//
//  HBCIString.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

// HBCI String extensions

func firstComponent(path:String) ->(component:String, residual:String?) {
    // path or final element?
    var name:String?
    var newPath:String?
    if let range = path.rangeOfString(".", options: NSStringCompareOptions(), range: nil, locale: nil) {
        name = path.substringToIndex(range.startIndex);
        newPath = path.substringFromIndex(range.startIndex.successor());
    } else {
        name = path;
    }
    
    return (name!, newPath);
}