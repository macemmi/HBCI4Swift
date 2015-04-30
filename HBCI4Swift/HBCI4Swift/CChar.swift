//
//  CChar.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 21.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

/*
extension CChar : ExtendedGraphemeClusterLiteralConvertible {
    
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        let num = value.unicodeScalars[value.unicodeScalars.startIndex]
        self = CChar(num.value)
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        let num = value.unicodeScalars[value.unicodeScalars.startIndex]
        self = CChar(num.value)
    }

}
*/

extension CChar : UnicodeScalarLiteralConvertible
{
    
    public typealias UnicodeScalarLiteralType = String
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        let num = value.unicodeScalars[value.unicodeScalars.startIndex]
        self = CChar(num.value)
    }
    
    public var descr: String {
        return String(format: "%c", self)
    }

}
