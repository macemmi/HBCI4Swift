//
//  HBCILog.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation


func logError(_ message:String?, file:String = #file, function:String = #function, line:Int = #line) {
    if let log = _log {
        log.logError(message, file: file, function: function, line: line);
    }
}

func logWarning(_ message:String?, file:String = #file, function:String = #function, line:Int = #line) {
    if let log = _log {
        log.logWarning(message, file: file, function: function, line: line);
    }
}

func logInfo(_ message:String?, file:String = #file, function:String = #function, line:Int = #line) {
    if let log = _log {
        log.logInfo(message, file: file, function: function, line: line);
    }
}

func logDebug(_ message:String?, file:String = #file, function:String = #function, line:Int = #line, values:Int...) {
    if let msg = message {
        let m = String(format: msg, arguments: values);
        if let log = _log {
            log.logDebug(m, file: file, function: function, line: line);
        }
    }
}

func logDebug(data: Data?, file:String = #file, function:String = #function, line:Int = #line) {
    var result = ""
    if let data = data {
        data.forEach { byte in
            if byte < 32 || byte > 126 {
                result = result.appendingFormat("<%.02X>", byte)
            } else {
                result = result + String(Unicode.Scalar(byte))          //Character(Unicode.Scalar(byte))
            }
        }
    }
    if let log = _log {
        log.logDebug(result, file: file, function: function, line: line);
    }
}

public protocol HBCILog {
     func logError(_ message:String?, file:String, function:String, line:Int);
     func logWarning(_ message:String?, file:String, function:String, line:Int);
     func logInfo(_ message:String?, file:String, function:String, line:Int);
     func logDebug(_ message:String?, file:String, function:String, line:Int);
}

var _log:HBCILog?;

open class HBCILogManager {
    open class func setLog(_ log:HBCILog) {
        _log = log;
    }    
}

open class HBCIConsoleLog: HBCILog {
    
    public init() {}
    
    open func logError(_ message: String?, file:String, function:String, line:Int) {
        if let msg = message {
            let url = URL(fileURLWithPath: file);
            print(url.lastPathComponent+", "+function+" \(line): "+msg);
        } else {
            let url = URL(fileURLWithPath: file);
            print(url.lastPathComponent+", "+function+" \(line): nil message");
        }
    }
    open func logWarning(_ message: String?, file:String, function:String, line:Int) {
        if let msg = message {
            let url = URL(fileURLWithPath: file);
            print("Warning"+url.lastPathComponent+", "+function+" \(line): "+msg);
        } else {
            let url = URL(fileURLWithPath: file);
            print("Warning: "+url.lastPathComponent+", "+function+" \(line): nil message");
        }
    }
    open func logInfo(_ message: String?, file:String, function:String, line:Int) {
        if let msg = message {
            let url = URL(fileURLWithPath: file);
            print("Info"+url.lastPathComponent+", "+function+" \(line): "+msg);
        } else {
            let url = URL(fileURLWithPath: file);
            print("Info"+url.lastPathComponent+", "+function+" \(line): nil message");
        }
    }
    open func logDebug(_ message: String?, file:String, function:String, line:Int) {
        if let msg = message {
            let url = URL(fileURLWithPath: file);
            print("Debug"+url.lastPathComponent+", "+function+" \(line): "+msg);
        } else {
            let url = URL(fileURLWithPath: file);
            print("Debug"+url.lastPathComponent+", "+function+" \(line): nil message");
        }
    }
}
