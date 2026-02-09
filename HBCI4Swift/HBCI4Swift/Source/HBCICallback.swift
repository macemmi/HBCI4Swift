//
//  HBCICallback.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 24.03.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIChallengeType {
    case none
    case flicker
    case photo
}

public enum HBCIVopConfirmationCallbackResult {
    case proceed
    case abort
    case replace
}


public protocol HBCICallback {
    func getTan(_ user:HBCIUser, challenge:String?, challenge_hhd_uc:String?, type:HBCIChallengeType) throws ->String;
    func decoupledNotification(_ user:HBCIUser, challenge:String?);
    func vopConfirmation(_ vopResult:HBCIVoPResult) -> HBCIVopConfirmationCallbackResult;
}

open class HBCICallbackConsole : HBCICallback {
    
    public init() {}
    
    open func getTan(_ user:HBCIUser, challenge:String?, challenge_hhd_uc:String?, type:HBCIChallengeType) ->String {
        print("Enter TAN (challenge:\(challenge ?? "<nil>")): ", terminator: "");
        let stdIn = FileHandle.standardInput;
        let data = Data(stdIn.availableData.dropLast());
        let input = String(data: data, encoding: String.Encoding.utf8);
        return input!;
    }
    
    open func decoupledNotification(_ user: HBCIUser, challenge: String?) {
        print("\(challenge ?? "")");
    }
    
    open func vopConfirmation(_ vopResult: HBCIVoPResult) -> HBCIVopConfirmationCallbackResult {
        if vopResult.status == HBCIVoPResultStatus.match {
            return .proceed;
        }
        return .abort;
    }
}
