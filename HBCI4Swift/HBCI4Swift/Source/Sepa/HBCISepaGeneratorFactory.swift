//
//  HBCISepaGeneratorFactory.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaGeneratorFactory {
    
    class func creditGenerator(_ user:HBCIUser, orderName:String? = nil) ->HBCISepaGeneratorCredit? {
        let formats = user.parameters.sepaFormats(HBCISepaFormatType.CreditTransfer, orderName: orderName);
        
        for format in formats {
            switch format.variant {
                case "003":
                    switch format.version {
                    case "03": return HBCISepaGenerator_001_003_03(format: format);
                        
                    default:
                        logError("SEPA Credit variant \(format.variant) version \(format.version) is not supported");
                        return nil;
                }
            default:
                logError("SEPA Credit variant \(format.variant) is not supported");
                return nil;
            }
            
        }
        return nil;
    }
    
}
