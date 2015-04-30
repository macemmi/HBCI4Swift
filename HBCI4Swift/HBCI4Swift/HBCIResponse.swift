//
//  HBCIResponse.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.02.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCIMessageResponse {
    var code:String?
    var text:String?;
    
    init() {
    }
}

class HBCIOrderResponse : HBCIMessageResponse {
    var reference:String?
    var parameters = Array<String>();
}
