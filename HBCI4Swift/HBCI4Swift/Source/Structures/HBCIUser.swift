//
//  HBCIUser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 09.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIUser {
    public let bankCode:String;
    public let hbciVersion:String;
    public let bankURL:String;
    public let userId:String;
    public let customerId:String;
    
    var securityMethod:HBCISecurityMethod!
    
    public var sysId:String?
    public var tanMethod:String?
    public var tanMediumName:String?
    public var pin:String?
    public var parameters = HBCIParameters();
    
    public init(userId:String, customerId:String, bankCode:String, hbciVersion:String, bankURLString:String) {
        self.userId = userId;
        self.customerId = customerId;
        self.bankCode = bankCode;
        self.hbciVersion = hbciVersion;
        self.bankURL = bankURLString;
    }
    
    public func setSecurityMethod(method:HBCISecurityMethod) {
        self.securityMethod = method;
        method.user = self;
        
        if method is HBCISecurityMethodDDV {
            self.sysId = "0";
        }
    }
    
    public func setParameterData(data:NSData, error:NSErrorPointer) ->Bool {
        if let syntax = HBCISyntax.syntaxWithVersion(hbciVersion, error: error) {
            if let params = HBCIParameters(data: data, syntax: syntax) {
                self.parameters = params;
                return true;
            }
        }
        return false;
    }
}
