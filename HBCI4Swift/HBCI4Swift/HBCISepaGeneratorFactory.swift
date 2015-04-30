//
//  HBCISepaGeneratorFactory.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaGeneratorFactory {
    
    class func creditGenerator(user:HBCIUser, orderName:String? = nil) ->HBCISepaGeneratorCredit? {
        let formats = user.parameters.sepaFormats(orderName);
        
        for (version, urn) in formats {
            let major = version.substringToIndex(3);
            if major == "001" {
                let minor = version.substringFromIndex(4);
                // switch minor
                switch minor {
                case "003.03":
                    return HBCISepaGenerator_001_003_03(urn: urn);
                default:
                    logError("SEPA Credit version \(version) is not supported");
                    return nil;
                }
            }
        }
        return nil;
    }
    
}
