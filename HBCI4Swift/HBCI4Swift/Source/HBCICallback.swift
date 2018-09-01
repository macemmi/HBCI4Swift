//
//  HBCICallback.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 24.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public protocol HBCICallback {
    func getTan(_ user:HBCIUser, challenge:String?, challenge_hdd_uc:String?) throws ->String;
    
}

open class HBCICallbackConsole : HBCICallback {
    
    public init() {}
    
    open func getTan(_ user:HBCIUser, challenge:String?, challenge_hdd_uc:String?) ->String {
        print("Enter TAN (challenge:\(challenge ?? "<nil>")): ", terminator: "");
        let stdIn = FileHandle.standardInput;
        let data = Data(stdIn.availableData.dropLast());
        let input = String(data: data, encoding: String.Encoding.utf8);
        return input!;
    }
}
