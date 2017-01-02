//
//  HBCIFlickerCode.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.01.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

public enum HHDVersion {
    case HHD13, HHD14;
}

enum HHDEncoding {
    case ASC, BCD;
}

public class HBCIFlickerCode {
    internal static let lc_len_hhd14 = 3;
    internal static let lc_len_hhd13 = 2;
    internal static let bit_encoding = 6;
    internal static let bit_controlbyte = 7;
    
    var version:HHDVersion!;
    var lc = 0;
    
    var startCode:StartCode!;
    var de1:Element!;
    var de2:Element!;
    var de3:Element!;
    
    var rest:String?
    
    class Element {
        // true length of element
        var length = 0;
        
        // encoded length (first 5 bits) + control-bits
        var lde = 0;
        
        // data encoding
        var encoding:HHDEncoding?
        
        // element data
        var data:String?
        
        let owner:HBCIFlickerCode;
        
        init(owner:HBCIFlickerCode) {
            self.owner = owner;
        }
        
        // try to parse element
        func parse(s:String) throws ->String {
            
            // nothing to parse
            if s.characters.count == 0 {
                return s;
            }
            
            if s.characters.count < 2 {
                throw HBCIError.ParseError;
            }
            
            // determine LDE (decimal)
            let index = s.startIndex.advancedBy(2);
            let lenString = s.substringToIndex(index);
            if let len = Int(lenString) {
                self.lde = len;
            } else {
                throw HBCIError.ParseError;
            }
            
            self.length = lde & 0x3F; // length is Bits 0-5
            
            // check bounds
            if index.distanceTo(s.endIndex) < length {
                throw HBCIError.ParseError;
            }
            
            // get element data
            self.data = s.substringWithRange(Range(index ..< index.advancedBy(length)));
            
            // return reststring
            return s.substringFromIndex(index.advancedBy(length));
        }
        
        func getEncoding() throws -> HHDEncoding {
            guard let data = self.data else {
                return .BCD;
            }
            
            if let enc = self.encoding {
                return enc;
            }
            
            // in SEPA orders there can also be characters (BIC/IBAN). In this case we need to encode in ASCII. So we BCD only
            // in case there are numbers only
            let regex = try NSRegularExpression(pattern: "[0-9]{1,}", options: NSRegularExpressionOptions.CaseInsensitive);
            let matches = regex.matchesInString(data, options: NSMatchingOptions(), range: NSMakeRange(0, length));
            for match in matches {
                if match.range.length == length {
                    return .BCD;
                }
            }
            return .ASC;
        }
        
        func renderData() throws ->String {
            guard let data = self.data else {
                return "";
            }
            
            let enc = try getEncoding();
            if enc == .ASC {
                return toHex(data);
            }
            
            if length % 2 == 1 {
                return data+"F";
            }
            return data;
        }
        
        func renderLength() throws ->String {
            if self.data == nil {
                return "";
            }
            
            let enc = try getEncoding();
            
            var len = try renderData().characters.count / 2;
            
            // a) BCD -> nothing further to encode
            if enc == .BCD {
                return String(format: "%0.2X", len);
            }
            
            // b) ASC -> set encoding-bit (HHD 1.4)
            if owner.version == .HHD14 {
                len = len + (1 << bit_encoding);
                return String(format: "%0.2X", len);
            }

            // HHD 1.3 -> set 1 in left nibble
            return "1" + String(format: "%0.1X", len);
        }
        
        func getDescription() ->String {
            var res = "";
            res = res + "  Length  : \(length)\n";
            res = res + "  LDE     : \(lde)\n";
            res = res + "  Data    : \(data)\n";
            res = res + "  Encoding: \(encoding)\n";
            return res;
        }
        
    }
    
    class StartCode : Element {
        var controlBytes = Array<UInt8>();
        
        override func parse(s: String) throws -> String {
            // get LDE (hex)
            if s.characters.count < 2 {
                throw HBCIError.ParseError;
            }
            
            var index = s.startIndex.advancedBy(2);
            let lenString = s.substringToIndex(index);
            if let len = Int(lenString, radix: 16) {
                self.lde = len;
            } else {
                throw HBCIError.ParseError;
            }
            
            // get real length
            self.length = lde & 0x3F;
            
            // encoding will be calculated during rendering
            
            // if there is no control byte it must be HHD 1.3
            owner.version = .HHD13;
            
            // get control byte if available
            if (lde & (1<<bit_controlbyte)) != 0 {
                owner.version = .HHD14;
                
                // there can be 9 control bytes at most
                for _ in 0 ..< 10 {
                    if index.distanceTo(s.endIndex) < 2 {
                        throw HBCIError.ParseError;
                    }
                    // 2 characters, Hex
                    let byteString = s.substringWithRange(Range(index ..< index.advancedBy(2)));
                    index = index.advancedBy(2);
                    if let byte = Int(byteString, radix: 16) {
                        controlBytes.append(UInt8(byte));
                        if (byte & (1<<bit_controlbyte)) == 0 {
                            break;
                        }
                    } else {
                        throw HBCIError.ParseError;
                    }
                }
            }
            
            // get start code
            if index.distanceTo(s.endIndex) < length {
                throw HBCIError.ParseError;
            }
            self.data = s.substringWithRange(Range(index ..< index.advancedBy(length)));
            return s.substringFromIndex(index.advancedBy(length));
        }
        
        override func renderLength() throws -> String {
            let s = try super.renderLength();
            
            // HHD 1.3 -> there are no control bytes
            if owner.version == .HHD13 {
                return s;
            }
            
            // HHD 1.4 -> but no control bytes
            if controlBytes.count == 0 {
                return s;
            }
            
            // encode control bytes
            if var len = Int(s, radix: 16) {
                if controlBytes.count > 0 {
                    len = len + (1 << bit_controlbyte);
                }
                return String(format: "%0.2X", len);
            }
            
            throw HBCIError.ParseError;
        }
        
        override func getDescription() -> String {
            var res = super.getDescription();
            res = res + "  Controlbytes: \(controlBytes.description)\n";
            return res;
        }
        
        
    }
    
    
    init() {
        version = .HHD14;
        
        startCode = StartCode(owner: self);
        de1 = Element(owner: self);
        de2 = Element(owner: self);
        de3 = Element(owner: self);
    }
    
    public convenience init(code:String) throws {
        self.init();

        // we first try with HHD 1.4
        do {
            try parse(code, version: .HHD14);
        }
        catch {
            do {
                try parse(code, version: .HHD13);
            }
            catch {
                logError("Could not parse flicker string " + code);
                throw HBCIError.ParseError;
            }
        }
    }
    
    // remove CHLGUC0026....CHLGTEXT from the code, if present. These are HHD 1.3 codes that are encoded into the challenge
    func clean(code:String) throws ->String {
        var cleaned = code.stringByReplacingOccurrencesOfString(" ", withString: ""); // Alle Leerzeichen entfernen
        cleaned = cleaned.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()); // Whitespaces entfernen
        
        // check if challenge contains codes
        if let r1 = cleaned.rangeOfString("CHLGUC"), r2 = cleaned.rangeOfString("CHLGTEXT") {
            if r1.startIndex >= r2.startIndex {
                return cleaned;
            }
            
            // first cut second token
            // then cut everything up to "CHLGUC"
            if r1.startIndex.distanceTo(cleaned.endIndex) < 10 {
                throw HBCIError.ParseError;
            }
            cleaned = cleaned.substringWithRange(Range(r1.startIndex.advancedBy(10) ..< r2.startIndex));

            // append "0" to make LC 3 digits, just like for HHD 1.4
            return "0" + cleaned;
        }
        return cleaned;
    }
    
    func parse(code:String, version:HHDVersion) throws {
        reset();
        
        var cd = try clean(code);
        
        // get LC - plain ASCII
        let len = version == .HHD14 ? HBCIFlickerCode.lc_len_hhd14 : HBCIFlickerCode.lc_len_hhd13;
        if let lc = Int(cd.substringToIndex(len)) {
            self.lc = lc;
        } else {
            throw HBCIError.ParseError;
        }
        
        cd = cd.substringFromIndex(len);
        
        // get start code / control bytes
        cd = try startCode.parse(cd);
        
        // 3. LDE/DE 1-3
        cd = try de1.parse(cd);
        cd = try de2.parse(cd);
        cd = try de3.parse(cd);
        
        if cd.characters.count > 0 {
            rest = cd;
        }
    }
    
    public func render() throws ->String {
        // 1. get payload
        let s = try createPayload();
        
        // 2. create luhn
        let luhn = try createLuhnChecksum();
        
        // 3. XOR Checksum
        let xor = try createXORChecksum(s);
        
        // put together
        return s + luhn + xor;
    }
    
    func reset() {
        self.lc = 0;
        self.startCode = StartCode(owner: self);
        self.de1 = Element(owner: self);
        self.de2 = Element(owner: self);
        self.de3 = Element(owner: self);
        self.rest = nil;
    }
    
    func createPayload() throws ->String {
        
        // 1. length start code
        var s = try startCode.renderLength();

        // 2. control bytes
        for cb in startCode.controlBytes {
            s += toHex(cb);
        }
        
        // 3. start code
        s += try startCode.renderData();
        
        // Elements
        let des = [de1, de2, de3];
        for de in des {
            s += try de.renderLength();
            s += try de.renderData();
        }
        
        var len = s.characters.count;
        len += 2; // include check sums
        len /= 2; // number of bytes - each byte consists of 2 chars
        let lc = toHex(UInt8(len));
        return lc + s;
    }
    
    func quersumme(x:Int) ->Int {
        let h = x/10;
        let l = x%10;
        return h+l;
    }
    
    func createLuhnChecksum() throws ->String {
        // Step 1: get payload

        var s = "";
        
         // a) Controlbytes
        for cb in startCode.controlBytes {
            s += toHex(cb);
        }

        // b) start code
        s += try startCode.renderData();
        
        // c) Elements
        if let _ = de1.data {
            s += try de1.renderData();
        }
        if let _ = de2.data {
            s += try de2.renderData();
        }
        if let _ = de3.data {
            s += try de3.renderData();
        }
        
        // step 2: calculate checksum
        var luhn = 0;
        for (index, char) in s.characters.enumerate() {
            if let x = Int(String(char), radix: 16) {
                luhn += index % 2 == 0 ? x : quersumme(2*x);
            } else {
                logError("\(char) cannot be parsed as Hex");
                throw HBCIError.ParseError;
            }
        }
        
        // calculates how much we have to add to luhn to come to the next multiple of 10
        let mod = luhn % 10;
        if mod == 0 {
            return "0";
        }
        
        let rest = 10 - mod;
        let sum = luhn + rest;
        
        luhn = sum - luhn;
        return String(format: "%X", luhn);
    }
    
    func createXORChecksum(s:String) throws ->String {
        var xorsum = 0;
        for scalar in s.unicodeScalars {
            if let x = Int(String(scalar), radix:  16) {
                xorsum ^= x;
            } else {
                logError("\(scalar) cannot be parsed as Hex");
                throw HBCIError.ParseError;
            }
        }
        return String(format: "%X", xorsum);
    }
    
}

func toHex(s:String) ->String {
    var res = "";
    for scalar in s.unicodeScalars {
        res = res + String(format: "%0.2X", UInt8(ascii: scalar));
    }
    return res;
}

func toHex(byte:UInt8) ->String {
    return String(format: "%0.2X", byte);
}

func ==(a:HBCIFlickerCode.Element, b:HBCIFlickerCode.Element) ->Bool {
    if !(a.data == b.data) { return false; }
    if a.lde != b.lde { return false; }
    if let enc1 = a.encoding {
        if let enc2 = b.encoding {
            return enc1 == enc2;
        }
    } else {
        return b.encoding == nil;
    }
    return false;
}

public func ==(a:HBCIFlickerCode, b:HBCIFlickerCode) ->Bool {
    if a.lc != b.lc { return false; }
    if !(a.startCode == b.startCode) { return false; }
    if !(a.de1 == b.de1) { return false; }
    if !(a.de2 == b.de2) { return false; }
    if !(a.de3 == b.de3) { return false; }
    let r1 = a.rest ?? "";
    let r2 = b.rest ?? "";
    return r1 == r2;
}

