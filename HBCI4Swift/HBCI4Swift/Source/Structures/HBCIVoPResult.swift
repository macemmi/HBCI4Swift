//
//  HBCIVoPResult.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 11.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//
public enum HBCIVoPResultStatus : String {
    case match = "RCVC", closeMatch = "RVMC", noMatch = "RVNM", notApplicable = "RVNA", withMismatches = "RVCM", pending = "PDNG"
}


open class HBCIVoPResultItem {
    public var status:         HBCIVoPResultStatus
    public var iban:           String
    public var givenName:      String
    public var actualName:     String?
    public var naReasonCode:   String?
    public var naReasonInf:    String?
    
    init(status:HBCIVoPResultStatus, iban:String, givenName:String) {
        self.status = status;
        self.iban = iban;
        self.givenName = givenName;
    }
}


open class HBCIVoPResult {
    public var textMatch:          String?
    public var textNoMatch:        String?
    public var textCloseMatch:     String?
    public var textNA:             String?
    public var status:             HBCIVoPResultStatus
    public var items:              Array<HBCIVoPResultItem>
    
    init(status:HBCIVoPResultStatus, textMatch:String, textNoMatch:String, textCloseMatch:String, textNA:String) {
        self.status = status;
        self.textMatch = textMatch;
        self.textNoMatch = textNoMatch;
        self.textCloseMatch = textCloseMatch;
        self.textNA = textNA;
        
        items = Array<HBCIVoPResultItem>();
    }
    
    init?(segment:HBCISegment) {
        guard let statusString = segment.elementValueForPath("result.result") as? String else {
            logDebug("Status string could not be determined from VOP result");
            return nil;
        }
        guard let stat = HBCIVoPResultStatus(rawValue: statusString) else {
            logDebug("Status could not be determined from VOP result");
            return nil;
        }
        guard let iban = segment.elementValueForPath("result.IBAN_receiver") as? String else {
            logDebug("IBAN could not be determined from VOP result");
            return nil;
        }
        
        if let info = segment.elementValueForPath("result.IBAN_info") as? String {
            logDebug("VOP result additional IBAN info: \(info)");
        }
        
        self.status = stat;
        
        if let text = segment.elementValueForPath("failMessage") as? String {
            textNoMatch = text;
            textCloseMatch = text;
        }
        
        if let naText = segment.elementValueForPath("result.rnva_reason") as? String {
            textNA = naText;
        }
        
        items = Array<HBCIVoPResultItem>();
                
        let item = HBCIVoPResultItem(status: stat, iban: iban, givenName: "");
        if stat == .closeMatch {
            var actualName = segment.elementValueForPath("result.alt_receiver") as? String;
            if actualName == nil {
                actualName = segment.elementValueForPath("result.alt_id") as? String;
            }
            item.actualName = actualName;
        }
         
        items.append(item);
    }
    
}
