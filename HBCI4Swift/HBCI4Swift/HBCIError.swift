//
//  HBCIError.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIErrorCodes:Int {
    case URLError = 1, SyntaxFileError
}


func createError(code: Int, message:String?, arguments:[String]?) ->NSError {
    var userInfo:Dictionary<String, AnyObject> = [:];
    if let msg = message {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    
    if arguments != nil {
        userInfo["arguments"] = arguments!;
    }
    
    return NSError(domain: "de.pecuniabanking.HBCI4Swift", code: code, userInfo: userInfo);
}