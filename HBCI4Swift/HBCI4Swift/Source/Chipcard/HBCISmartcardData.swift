//
//  HBCISmartcardData.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 20.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public struct HBCICardBankData {
    public var name:String;
    public var bankCode:String;
    public var country:String;
    public var host:String;
    public var hostAdd:String;
    public var userId:String;
    public var commtype:UInt8;
    
    public init() {
        name = "";
        bankCode = "";
        country = "";
        host = "";
        hostAdd = "";
        userId = "";
        commtype = 0;
    };
    
    public init(name:String, bankCode:String, country:String, host:String, hostAdd:String, userId:String, commtype:UInt8) {
        self.name = name;
        self.bankCode = bankCode;
        self.country = country;
        self.host = host;
        self.hostAdd = hostAdd;
        self.userId = userId;
        self.commtype = commtype;
    }
}

struct HBCICardKeyData {
    var keyNumber, keyVersion, keyLength, algorithm:UInt8;
}
