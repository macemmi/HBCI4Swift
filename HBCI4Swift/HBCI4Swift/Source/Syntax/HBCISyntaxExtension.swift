//
//  HBCISyntaxExtension.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

var _extension:HBCISyntaxExtension?

open class HBCISyntaxExtension {
    var extensions = Dictionary<String, HBCISyntax>();
    
    init() {}
    
    open func add(_ path:String, version:String) throws {
        if !["220", "300"].contains(version) {
            throw HBCIError.invalidHBCIVersion(version);
        }

        let syntax = try HBCISyntax(path: path);
        extensions[version] = syntax;
    }
    
    open class var instance:HBCISyntaxExtension {
        get {
            if _extension == nil {
                _extension = HBCISyntaxExtension();
            }
            return _extension!
        }
    }
}
