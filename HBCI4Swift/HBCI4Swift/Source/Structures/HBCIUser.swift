//
//  HBCIUser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 09.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIUser {
    open let bankCode:String;
    open let hbciVersion:String;
    open let bankURL:String;
    open let userId:String;
    open let customerId:String;
    
    internal var _securityMethod:HBCISecurityMethod!
    
    open var sysId:String?
    open var tanMethod:String?
    open var tanMediumName:String?
    open var pin:String?
    open var parameters = HBCIParameters();
    open var bankName:String?
    
    public init(userId:String, customerId:String, bankCode:String, hbciVersion:String, bankURLString:String) {
        self.userId = userId;
        self.customerId = customerId;
        self.bankCode = bankCode;
        self.hbciVersion = hbciVersion;
        self.bankURL = bankURLString;
    }
    
    open func setSecurityMethod(_ method:HBCISecurityMethod) {
        self.securityMethod = method;
        method.user = self;
        
        if method is HBCISecurityMethodDDV {
            self.sysId = "0";
        }
    }
    
    open var securityMethod:HBCISecurityMethod! {
        get {
            return self._securityMethod;
        }
        set(method) {
            self._securityMethod = method;
            method.user = self;
            
            if method is HBCISecurityMethodDDV {
                self.sysId = "0";
            }
        }
    }
    
    open func setParameterData(_ data:Data) throws {
        let syntax = try HBCISyntax.syntaxWithVersion(hbciVersion);
        self.parameters = try HBCIParameters(data: data, syntax: syntax);
    }
}
