//
//  HBCICallback.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 24.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public protocol HBCICallback {
    func getTan(user:HBCIUser, challenge:String?, challenge_hdd_uc:String?) throws ->String;
    
}

public class HBCICallbackConsole : HBCICallback {
    
    public init() {}
    
    public func getTan(user:HBCIUser, challenge:String?, challenge_hdd_uc:String?) ->String {
        print("Enter TAN (challenge:\(challenge)): ", terminator: "");
        let stdIn = NSFileHandle.fileHandleWithStandardInput();
        let data = stdIn.availableData.mutableCopy() as! NSMutableData;
        data.length -= 1;
        let input = NSString(data: data, encoding: NSUTF8StringEncoding) as! String;
        return input;
    }
}
