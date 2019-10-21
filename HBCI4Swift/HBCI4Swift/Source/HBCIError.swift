//
//  HBCIError.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIError : Error, Equatable {
    case badURL(String)
    case connection(String)
    case serverTimeout(String)
    case missingData(String)
    case invalidHBCIVersion(String)
    case syntaxFileError
    case parseError
    case userAbort
    case PINError
    
}


public enum HBCIErrorCode:Int {
    case urlError = 1, syntaxFileError, parseError, messageError, connectionError, connectionTestError
}


func createError(_ code: HBCIErrorCode, message:String?, arguments:[String]? = nil) ->NSError {
    var userInfo:Dictionary<String, Any> = [:];
    if let msg = message {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    
    if arguments != nil {
        userInfo["arguments"] = arguments!;
    }
    
    return NSError(domain: "de.pecuniabanking.HBCI4Swift", code: code.rawValue, userInfo: userInfo);
}
