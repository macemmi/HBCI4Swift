//
//  HBCICallback.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 24.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public protocol HBCICallback {
    func getTan(userId:String, challenge:String?, challenge_hdd_uc:NSData?) ->String;
    
}

public class HBCICallbackConsole : HBCICallback {
    
    public init() {}
    
    public func getTan(userId:String, challenge:String?, challenge_hdd_uc:NSData?) ->String {
        print("Enter TAN (challenge:\(challenge)): ");
        let stdIn = NSFileHandle.fileHandleWithStandardInput();
        var data = stdIn.availableData.mutableCopy() as! NSMutableData;
        data.length--;
        let input = NSString(data: data, encoding: NSUTF8StringEncoding) as! String;
        return input;
    }
}
