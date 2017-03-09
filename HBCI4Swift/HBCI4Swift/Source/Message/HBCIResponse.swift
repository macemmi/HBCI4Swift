//
//  HBCIResponse.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

open class HBCIMessageResponse {
    open let code:String;
    open let text:String;
    
    init?(element:HBCISyntaxElement) {
        guard let code = element.elementValueForPath("code") as? String else {
            self.code = "";
            self.text = "";
            return nil;
        }
        self.code = code;
        
        guard let text = element.elementValueForPath("text") as? String else {
            self.text = "";
            return nil;
        }
        self.text = text;
    }
    
    var description: String {
        get {
            return "\(self.code) \(self.text)";
        }
    }
}

open class HBCIOrderResponse : HBCIMessageResponse {
    open var reference:Int?
    open var parameters = Array<String>();
    
    override init?(element: HBCISyntaxElement) {
        super.init(element: element);
        if self.code == "" {
            return nil;
        }
        
        if let ref = element.elementValueForPath("ref") as? String {
            self.reference = Int(ref);
        }
        
        self.parameters = element.elementValuesForPath("parm") as! [String];
    }
    
    override var description: String {
        get {
            var descr = "\(self.code) \(self.text) ";
            for param in self.parameters {
                descr += param + " ";
            }
            return descr;
        }
    }
}
