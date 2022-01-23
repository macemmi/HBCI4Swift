//
//  HBCISepaParserFactory.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaParserFactory {
    
    class func creditParser(_ urn:String) ->HBCISepaParserCredit? {
        if let format = HBCISepaFormat(urn: urn) {
            switch format.variant {
            case "003":
                switch format.version {
                case "03": return HBCISepaParser_001_003_03(format: format);
                    
                default:
                    logInfo("SEPA Credit variant \(format.variant ?? "?") version \(format.version ?? "?") is not supported");
                    return nil;
                }
            case "001":
                switch format.version {
                case "03": return HBCISepaParser_001_001_03(format: format);
                    
                default:
                    logInfo("SEPA Credit variant \(format.variant ?? "?") version \(format.version ?? "?") is not supported");
                    return nil;
                }

            default:
                logInfo("SEPA Credit variant \(format.variant ?? "?") is not supported");
                return nil;
            }
            
        } else {
            return nil;
        }
    }
    
}
