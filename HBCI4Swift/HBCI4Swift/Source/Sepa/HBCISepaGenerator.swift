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
    let document:NSXMLDocument;
    let root:NSXMLElement;
    let numberFormatter = NSNumberFormatter();
    let format:HBCISepaFormat;
    var schemaLocationAttrNode:NSXMLNode!
    
    init(format:HBCISepaFormat) {
        
        // set format
        self.format = format;
        
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
    
    var sepaFormat:HBCISepaFormat {
        get {
            return format;
        }
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
        var namespace = NSXMLNode(kind: NSXMLNodeKind.NamespaceKind);
        namespace.stringValue = format.urn;
        namespace.name = "";
        root.addNamespace(namespace);
        
        namespace = NSXMLNode(kind: NSXMLNodeKind.NamespaceKind);
        namespace.stringValue = "http://www.w3.org/2001/XMLSchema-instance";
        namespace.name = "xsi";
        root.addNamespace(namespace);
        
        schemaLocationAttrNode = NSXMLNode(kind: NSXMLNodeKind.AttributeKind);
        schemaLocationAttrNode.name = "xsi:schemaLocation"
        schemaLocationAttrNode.stringValue = format.schemaLocation;
        root.addAttribute(schemaLocationAttrNode);
    }
    
    func validate() ->Bool {
        
        // set local schema validation path
        let oldLocation = schemaLocationAttrNode.stringValue;
        schemaLocationAttrNode.stringValue = self.format.validationSchemaLocation;
        
        do {
            try document.validate();
        } catch let error as NSError {
            logError("SEPA document error: " + error.description);
            schemaLocationAttrNode.stringValue = oldLocation;
            return false;
        }
        schemaLocationAttrNode.stringValue = oldLocation;
        return true;
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

    
}
