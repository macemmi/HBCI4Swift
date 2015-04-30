//
//  HBCISepaGeneratorCredit.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

protocol HBCISepaGeneratorCredit {
    
    func documentForTransfer(transfer:HBCISepaTransfer) ->NSData?
    func getURN() ->String;
}
