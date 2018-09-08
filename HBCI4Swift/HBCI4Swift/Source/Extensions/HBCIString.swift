//
//  HBCIString.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

// HBCI String extensions

func firstComponent(_ path:String) ->(component:String, residual:String?) {
    // path or final element?
    var name:String?
    var newPath:String?
    if let range = path.range(of: ".", options: NSString.CompareOptions(), range: nil, locale: nil) {
        name = String(path.prefix(through: range.lowerBound));
        newPath = String(path.suffix(from: path.index(after: range.lowerBound)));
    } else {
        name = path;
    }
    
    return (name!, newPath);
}
