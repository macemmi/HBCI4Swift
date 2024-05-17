//
//  HBCITanMethod.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 25.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

let unknown = "<unknown>";

public enum TanProcess:String {
    case none = "0", process1 = "1", process2 = "2"
}

open class HBCITanMethod {
    public let
    identifier:String!,
    version:Int!,
    secfunc:String!,
    inputInfo:String!,
    name:String!,
    format:String!,
    maxTanLength:Int!
    
    open var
    needTanMedia:String?,
    process:TanProcess!,
    zkaMethodName:String?,
    zkaMethodVersion:String?,
    numActiveMedia:Int?,
    maxPollsDecoupled:Int?,
    waitDecoupled:Int?

    
    init?(element:HBCISyntaxElement, version:Int) {
        self.secfunc = element.elementValueForPath("secfunc") as? String;
        self.identifier = element.elementValueForPath("id") as? String;
        self.inputInfo = element.elementValueForPath("inputinfo") as? String;
        self.name = element.elementValueForPath("name") as? String;
        self.format = element.elementValueForPath("tanformat") as? String;
        self.maxTanLength = element.elementValueForPath("maxlentan") as? Int;
        self.process = TanProcess(rawValue: (element.elementValueForPath("process") as? String) ?? "0");
        self.version = version;
        
        if version >= 3 {
            self.needTanMedia = element.elementValueForPath("needtanmedia") as? String;
            self.numActiveMedia = element.elementValueForPath("nofactivetanmedia") as? Int;
        }
        if version >= 4 {
            self.zkaMethodName = element.elementValueForPath("zkamethod_name") as? String;
            self.zkaMethodVersion = element.elementValueForPath("zkamethod_version") as? String;
        }
        if version >= 7 {
            self.maxPollsDecoupled = element.elementValueForPath("maxpolls_decoupled") as? Int;
            self.waitDecoupled = element.elementValueForPath("nextwait_decoupled") as? Int;
        }
        
        
        if self.identifier == nil || self.secfunc == nil || self.inputInfo == nil || self.name == nil || self.process == nil {
                logInfo("TanMethod \(self.identifier ?? unknown): not all mandatory fields are provided for version \(version)");
                logInfo(element.description);
                return nil;
        }
        
        if version < 7 && (self.format == nil || self.maxTanLength == nil) {
            logInfo("TanMethod \(self.identifier ?? unknown): not all mandatory fields are provided for version \(version)");
            logInfo(element.description);
            return nil;
        }
        
        
    }
    
}
