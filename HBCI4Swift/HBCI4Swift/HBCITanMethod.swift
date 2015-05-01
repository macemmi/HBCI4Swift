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

public class HBCITanMethod {
    public let
    identifier:String!,
    inputInfo:String!,
    name:String!,
    format:String!,
    maxTanLength:Int!
    
    public var
    needTanMedia:String?,
    process:TanProcess!,
    zkaMethodName:String?,
    zkaMethodVersion:String?,
    numActiveMedia:Int?
    
    
    init?(element:HBCISyntaxElement, version:Int) {
        self.identifier = element.elementValueForPath("secfunc") as? String;
        self.inputInfo = element.elementValueForPath("inputinfo") as? String;
        self.name = element.elementValueForPath("name") as? String;
        self.format = element.elementValueForPath("tanformat") as? String;
        self.maxTanLength = element.elementValueForPath("maxlentan") as? Int;
        self.process = TanProcess(rawValue: (element.elementValueForPath("process") as? String) ?? "0");
        
        if version >= 3 {
            self.needTanMedia = element.elementValueForPath("needtanmedia") as? String;
            self.numActiveMedia = element.elementValueForPath("nofactivetanmedia") as? Int;
        }
        if version >= 4 {
            self.zkaMethodName = element.elementValueForPath("zkamethod_name") as? String;
            self.zkaMethodVersion = element.elementValueForPath("zkamethod_version") as? String;
        }
        
        
        if self.identifier == nil || self.inputInfo == nil || self.name == nil || self.format == nil || self.maxTanLength == nil || self.process == nil {
                logError("TanMethod \(self.identifier ?? unknown): not all mandatory fields are provided for version \(version)");
                logError(element.description);
                return nil;
        }
    }
    
}
