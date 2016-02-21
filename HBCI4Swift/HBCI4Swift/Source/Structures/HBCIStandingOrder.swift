//
//  HBCIStandingOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 16.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HBCIStandingOrderCycleUnit : String {
    case monthly = "M", weekly = "W";
}

public class HBCIStandingOrder : HBCISepaTransfer {
    public var startDate: NSDate;
    public var lastDate: NSDate?
    public var cycle: Int;
    public var executionDay: Int;
    public var cycleUnit: HBCIStandingOrderCycleUnit;
    public var orderId:String?
    
    public init(account: HBCIAccount, startDate: NSDate, cycle: Int, day: Int, cycleUnit:HBCIStandingOrderCycleUnit = .monthly) {
        self.startDate = startDate;
        self.cycle = cycle;
        self.executionDay = day;
        self.cycleUnit = cycleUnit;
        super.init(account: account);        
    }
    
    convenience init(transfer:HBCISepaTransfer, startDate: NSDate, cycle: Int, day: Int, cycleUnit:HBCIStandingOrderCycleUnit = .monthly) {
        self.init(account: transfer.account, startDate: startDate, cycle: cycle, day: day, cycleUnit: cycleUnit);
        self.batchbook = transfer.batchbook;
        self.sepaId = transfer.sepaId;
        self.paymentInfoId = transfer.paymentInfoId;
        self.date = transfer.date;
        
        for item in transfer.items {
            self.items.append(item);
        }
    }
    
}
