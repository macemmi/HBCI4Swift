//
//  HBCISecurityMethod.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 17.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCISecurityMethodCode {
    case undefined, pinTan, ddv;
}

open class HBCISecurityMethod {
    weak var user:HBCIUser!
    open var code = HBCISecurityMethodCode.undefined;
    
    func signMessage(_ msg:HBCIMessage) ->Bool {
        return false;
    }
    
    func encryptMessage(_ msg:HBCIMessage, dialog:HBCIDialog) ->HBCIMessage? {
        return nil;
    }
    
    func decryptMessage(_ rmsg:HBCIResultMessage, dialog:HBCIDialog) ->HBCIResultMessage? {
        return nil;
    }

}
