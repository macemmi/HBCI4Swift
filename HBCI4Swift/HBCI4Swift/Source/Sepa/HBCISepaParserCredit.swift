//
//  HBCISepaParserCredit.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

protocol HBCISepaParserCredit {
    
    func transferForDocument(_ account:HBCIAccount, data:Data) ->HBCISepaTransfer?
}
