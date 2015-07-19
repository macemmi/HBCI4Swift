//
//  HBCISecurityMethod.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 17.07.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public class HBCISecurityMethod {
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
