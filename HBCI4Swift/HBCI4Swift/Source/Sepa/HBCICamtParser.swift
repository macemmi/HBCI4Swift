//
//  HBCICamtParser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 04.06.22.
//  Copyright © 2022 Frank Emminghaus. All rights reserved.
//

import Foundation

protocol HBCICamtParser {
    
    func parse(_ account:HBCIAccount, data:Data, isPreliminary:Bool) ->[HBCIStatement]?

}
