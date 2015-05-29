//
//  HBCILog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation



func logError(message:String, file:String = __FILE__, function:String = __FUNCTION__, line:Int = __LINE__) {
    if let log = _log {
        log.logError(message, file: file, function: function, line: line);
    }
}

func logInfo(message:String, file:String = __FILE__, function:String = __FUNCTION__, line:Int = __LINE__) {
    if let log = _log {
        log.logError(message, file: file, function: function, line: line);
    }
}

public protocol HBCILog {
     func logError(message:String, file:String, function:String, line:Int);
     func logInfo(message:String, file:String, function:String, line:Int);
    
}

var _log:HBCILog?;

public class HBCILogManager {
    public class func setLog(log:HBCILog) {
        _log = log;
    }    
}

public class HBCIConsoleLog: HBCILog {
    
    public init() {}
    
    public func logError(message: String, file:String, function:String, line:Int) {
        println(file.lastPathComponent+", "+function+" \(line): "+message);
    }
    public func logInfo(message: String, file:String, function:String, line:Int) {
        println("Info: "+file.lastPathComponent+", "+function+" \(line): "+message);
    }
}