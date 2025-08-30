//
//  HBCISepaInfoParameter.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 21.12.24.
//  Copyright © 2024 Frank Emminghaus. All rights reserved.
//

public struct HBCISepaInfoParameters {
    public let
    allowsSingleAccounts: Bool!,
    allowsNationalAccounts: Bool!
    
    init?(segment:HBCISegment) {

        self.allowsSingleAccounts = segment.elementValueForPath("ParSepaInfo.cansingleaccquery") as? Bool;
        self.allowsNationalAccounts = segment.elementValueForPath("ParSepaInfo.cannationalacc") as? Bool;

        if self.allowsSingleAccounts == nil || self.allowsNationalAccounts == nil {
            logInfo("SepaInfoParameter: not all mandatory fields are provided!");
            logInfo(segment.description);
            return nil;
        }
    }
    
    
}
