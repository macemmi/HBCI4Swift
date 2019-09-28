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
    let document:XMLDocument;
    let root:XMLElement;
    let numberFormatter = NumberFormatter();
    let format:HBCISepaFormat;
    var schemaLocationAttrNode:XMLNode!
    
    init(format:HBCISepaFormat) {
        
        // set format
        self.format = format;
        
        // create document
        self.root = XMLElement(name: "Document");
        self.document = XMLDocument(rootElement: self.root);
        
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
    
    fileprivate func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;
    }
    
    func numberToString(_ number:NSDecimalNumber) ->String? {
        return numberFormatter.string(from: number);
    }
    
    func defaultMessageId() ->String {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS";
        return formatter.string(from: Date());
    }
    
    func setNamespace() {
        var namespace = XMLNode(kind: XMLNode.Kind.namespace);
        namespace.stringValue = format.urn;
        namespace.name = "";
        root.addNamespace(namespace);
        
        namespace = XMLNode(kind: XMLNode.Kind.namespace);
        namespace.stringValue = "http://www.w3.org/2001/XMLSchema-instance";
        namespace.name = "xsi";
        root.addNamespace(namespace);
        
        schemaLocationAttrNode = XMLNode(kind: XMLNode.Kind.attribute);
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
            logInfo("SEPA document error: " + error.description);
            logInfo("Schema validation location: " + (schemaLocationAttrNode.stringValue ?? "<none>"));
            logInfo("Schema validation location old: " + (oldLocation ?? "none"));
            schemaLocationAttrNode.stringValue = oldLocation;
            return false;
        }
        schemaLocationAttrNode.stringValue = oldLocation;
        return true;
    }
    
    func sepaISODateString() ->String {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX";
        return formatter.string(from: Date());
    }
    
    func sepaDateString(_ date:Date) ->String {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        return formatter.string(from: date);
    }

    
}
