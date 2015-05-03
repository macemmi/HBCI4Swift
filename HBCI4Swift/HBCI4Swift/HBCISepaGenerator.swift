//
//  HBCISepaGenerator.swift
//  HBCISepaGenerator
//
//  Created by Frank Emminghaus on 21.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

enum SepaOrderType: String {
    case Credit = "001", Debit = "008"
}

class HBCISepaGenerator {
    let urn:String;
    let document:NSXMLDocument;
    let root:NSXMLElement;
    let numberFormatter = NSNumberFormatter();
    
    init(urn:String) {
        self.urn = urn;
        
        // create document
        self.root = NSXMLElement(name: "Document");
        self.document = NSXMLDocument(rootElement: self.root);
        
        self.document.version = "1.0";
        self.document.characterEncoding = "UTF-8";

        // set namespace
        self.setNamespace();
        
        // init formatters
        initFormatters();
    }
    
    private func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;
    }
    
    func numberToString(number:NSDecimalNumber) ->String? {
        return numberFormatter.stringFromNumber(number);
    }
    
    func defaultMessageId() ->String {
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS";
        return formatter.stringFromDate(NSDate());
    }
    
    func setNamespace() {
        // first remove .xsd substring (if existing) to get location
        let location = urn.stringByReplacingOccurrencesOfString(".xsd", withString: "", options: NSStringCompareOptions.allZeros, range: nil);
        
        var range = Range<String.Index>(start: advance(location.endIndex, -15), end: location.endIndex);
        let schema = location.substringWithRange(range) + ".xsd";
        
        var namespace = NSXMLNode(kind: NSXMLNodeKind.NSXMLNamespaceKind);
        namespace.stringValue = location;
        namespace.name = "";
        root.addNamespace(namespace);
        
        namespace = NSXMLNode(kind: NSXMLNodeKind.NSXMLNamespaceKind);
        namespace.stringValue = "http://www.w3.org/2001/XMLSchema-instance";
        namespace.name = "xsi";
        root.addNamespace(namespace);
        
        var attr = NSXMLNode(kind: NSXMLNodeKind.NSXMLAttributeKind);
        attr.name = "xsi:schemaLocation"
        attr.stringValue = location + " " + schema;
        root.addAttribute(attr);
    }
    
    func sepaISODateString() ->String {
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX";
        return formatter.stringFromDate(NSDate());
    }
    
    func sepaDateString(date:NSDate) ->String {
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        return formatter.stringFromDate(date);
    }
    
    func getURN() ->String {
        return self.urn;
    }
    

}
