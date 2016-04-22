//
//  HBCISyntaxExtension.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.04.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

var _extension:HBCISyntaxExtension?

public class HBCISyntaxExtension {
    var extensions = Dictionary<String, HBCISyntax>();
    
    init() {}
    
    public func add(path:String, version:String) throws {
        if !["220", "300"].contains(version) {
            throw HBCIError.InvalidHBCIVersion(version);
        }

        let syntax = try HBCISyntax(path: path);
        extensions[version] = syntax;
    }
    
    public class var instance:HBCISyntaxExtension {
        get {
            if _extension == nil {
                _extension = HBCISyntaxExtension();
            }
            return _extension!
        }
    }
}
