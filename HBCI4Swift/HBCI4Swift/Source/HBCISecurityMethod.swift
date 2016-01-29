//
//  HBCISecurityMethod.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 17.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCISecurityMethodCode {
    case Undefined, PinTan, DDV;
}

public class HBCISecurityMethod {
    weak var user:HBCIUser!
    public var code = HBCISecurityMethodCode.Undefined;
    
    func signMessage(msg:HBCIMessage) ->Bool {
        return false;
    }
    
    func encryptMessage(msg:HBCIMessage, dialog:HBCIDialog) ->HBCIMessage? {
        return nil;
    }
    
    func decryptMessage(rmsg:HBCIResultMessage, dialog:HBCIDialog) ->HBCIResultMessage? {
        return nil;
    }

}
