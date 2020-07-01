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
        var creditFormats = [HBCISepaFormat]();
        

        for format in formats {
            if format.type == HBCISepaFormatType.CreditTransfer {
                creditFormats.append(format);
            }
        }
        
        if let format = creditFormats.first(where: { $0.variant == "001" }) {
            return HBCISepaGenerator_001_001_03(format: format);
        }
        if let format = creditFormats.first(where: { $0.variant == "003" }) {
            return HBCISepaGenerator_001_003_03(format: format);
        }
        
        logInfo("No supported SEPA credit format found");

        return nil;
    }
    
}
