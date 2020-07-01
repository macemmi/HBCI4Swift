//
//  HBCISepaFormat.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HBCISepaFormatType : String {
    case CreditTransfer = "001", PaymentStatus = "002", DebitTransfer = "008";
}

let urns = [
    "001.001.03":"urn:iso:std:iso:20022:tech:xsd:pain.001.001.03",
    "001.003.03":"urn:iso:std:iso:20022:tech:xsd:pain.001.003.03"
];


func < (left:HBCISepaFormat, right:HBCISepaFormat) ->Bool {
    let type1 = left.type.rawValue;
    let type2 = right.type.rawValue;
    if type1 != type2 {
        return type1 < type2;
    }
    if left.variant != right.variant {
        return left.variant < right.variant;
    }
    return left.version < right.version;
}

class HBCISepaFormat {
    let type:HBCISepaFormatType!
    let variant:String!
    let version:String!
    
    init?(urn:String) {
        let pattern = "[0-9]{3}.[0-9]{3}.[0-9]{2}";
        //let pattern = "pain.[0-9]{3}.[0-9]{3}.[0-9]{2}(_GBIC_[0-9])?";

        if let match = urn.range(of: pattern, options: NSString.CompareOptions.regularExpression, range: nil, locale: nil) {
            //let prefix = urn.prefix(upTo: match.lowerBound);
            let format = String(urn[match]);
            self.type = HBCISepaFormatType(rawValue: format.substringToIndex(3));
            self.variant = format.substringWithRange(NSMakeRange(4, 3));
            self.version = format.substringFromIndex(8);
        
            if type == nil || variant == nil || version == nil {
                logInfo("Cannot parse urn " + urn);
                return nil;
            }
            
            if urns[formatString] == nil {
                logInfo("Sepa format \(formatString) is not supported");
                return nil;
            }
        } else {
            self.type = nil;
            self.variant = nil;
            self.version = nil;
            return nil;
        }
    }
    
    var formatString:String {
        get {
            return type.rawValue + "." + variant + "." + version;
        }
    }
    
    var schemaLocation:String {
        get {
            return urns[formatString]! + " pain." + formatString + ".xsd";
        }
    }
    
    var validationSchemaLocation:String {
        get {
            var path = Bundle.main.bundlePath.replacingOccurrences(of: " ", with:"%20");
            path = path + "/Contents/Frameworks/HBCI4Swift.framework/Resources/pain.";
            return urns[formatString]! + " " + path + formatString + ".xsd";
        }
    }
    
    var urn:String {
        return urns[formatString]!;
    }
    
    
}
