//
//  HBCIError.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIErrorCode:Int {
    case URLError = 1, SyntaxFileError, ParseError, MessageError, ConnectionError, ConnectionTestError
}


func createError(code: HBCIErrorCode, message:String?, arguments:[String]? = nil) ->NSError {
    var userInfo:Dictionary<String, AnyObject> = [:];
    if let msg = message {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    
    if arguments != nil {
        userInfo["arguments"] = arguments!;
    }
    
    return NSError(domain: "de.pecuniabanking.HBCI4Swift", code: code.rawValue, userInfo: userInfo);
}