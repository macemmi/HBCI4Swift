//
//  HBCIUser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 09.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCIUser {
    public var
    bankCode:String?,
    hbciVersion:String?,
    bankURL:String?,
    userId:String?,
    customerId:String?,
    sysId:String?,
    tanMethod:String?,
    tanMediumName:String?,
    pin:String?,
    parameters = HBCIParameters();
    
    public init() {
    }
    
    class func newInstance() ->HBCIUser {
        return HBCIUser();
    }
    
}
