//
//  HBCIFlickerCode.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 23.01.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HHDVersion {
    case HHD13, HHD14;
}

enum HHDEncoding {
    case ASC, BCD;
}

class HBCIFlickerCode {
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
        /**
         * Die tatsaechliche Laenge des DE.
         * Bereinigt um ggf. vorhandene Control-Bits.
         */
        var length = 0;
        
        /**
         * Die Laengen-Angabe des DE im Roh-Format.
         * Sie kann noch Control-Bits enthalten, sollte daher
         * also NICHT fuer Laengenberechnungen verwendet werden.
         * In dem Fall stattdessen <code>length</code> verwenden.
         */
        var lde = 0;
        
        /**
         * Das Encoding der Nutzdaten.
         * Per Definition ist im Challenge HHDuc dieses Bit noch NICHT gesetzt.
         * Das Encoding passiert erst beim Rendering.
         */
        var encoding:HHDEncoding?
        
        /**
         * Die eigentlichen Nutzdaten des DE.
         */
        var data:String?
        
        let owner:HBCIFlickerCode;
        
        init(owner:HBCIFlickerCode) {
            self.owner = owner;
        }

        /**
         * Parst das DE am Beginn des uebergebenen Strings.
         * @param s der String, dessen Anfang das DE enthaelt.
         * @return der Reststring.
         */
        func parse(s:String) throws ->String {
            
            // nothing to parse
            if s.lengthOfBytesUsingEncoding(NSISOLatin1StringEncoding) == 0 {
                return s;
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
            
            // get element data
            self.data = s.substringWithRange(Range(start: index, end: index.advancedBy(length)));
            
            // return reststring
            return s.substringFromIndex(index);
        }
        
        func getEncoding() throws -> HHDEncoding {
            guard let data = self.data else {
                return .BCD;
            }
            
            if let enc = self.encoding {
                return enc;
            }
            
            // Siehe tan_hhd_uc_v14.pdf, letzter Absatz in B.2.3
            // Bei SEPA-Auftraegen koennen auch Buchstaben in BIC/IBAN vorkommen.
            // In dem Fall muss auch ASC-codiert werden. Also machen wir BCD nur
            // noch dann, wenn ausschliesslich Zahlen drin stehen.
            // Das macht subsembly auch so
            // http://www.onlinebanking-forum.de/phpBB2/viewtopic.php?p=75602#75602
            let regex = try NSRegularExpression(pattern: "[0-9]{1,}", options: NSRegularExpressionOptions.CaseInsensitive);
            let matches = regex.matchesInString(data, options: NSMatchingOptions(), range: NSMakeRange(0, length));
            for match in matches {
                if match.range.length == length {
                    return .BCD;
                }
            }
            return .ASC;
        }
        
        /**
         * Rendert die Nutzdaten fuer die Uebertragung via Flickercode.
         * @return die codierten Nutzdaten.
         * Wenn das DE keine Nutzdaten enthaelt, wird "" zurueck gegeben.
         */
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
        
        /**
         * Rendert die Laengenangabe fuer die Uebertragung via Flickercode.
         * @return die codierten Nutzdaten.
         * Wenn das DE keine Nutzdaten enthaelt, wird "" zurueck gegeben.
         */
        func renderLength() throws ->String {
            // Keine Daten enthalten. Dann muessen wir auch nichts weiter
            // beruecksichtigen.
            // Laut Belegungsrichtlinien TANve1.4  mit Erratum 1-3 final version vom 2010-11-12.pdf
            // duerfen im "ChallengeHHDuc" eigentlich keine leeren DEs enthalten
            // sein. Daher geben wir in dem Fall "" zurueck und nicht "00" wie in
            // tan_hhd_uc_v14.pdf angegeben. Denn mit "00" wollte es mein TAN-Generator nicht
            // lesen. Kann aber auch sein, dass der einfach nicht HHD 1.4 tauglich ist
            if self.data == nil {
                return "";
            }
            
            let enc = try getEncoding();
            
            var len = try renderData().lengthOfBytesUsingEncoding(NSASCIIStringEncoding) / 2;
            
            // A) BCD -> Muss nichts weiter codiert werden.
            if enc == .BCD {
                return String(format: "%0.2X", len);
            }
            
            // B) ASC -> Encoding-Bit reincodieren
            // HHD 1.4 -> in das Bit-Feld codieren
            if owner.version == .HHD14 {
                len = len + (1 << bit_encoding);
                return String(format: "%0.2X", len);
            }

            // HHD 1.3 -> nur ne 1 im linken Halbbyte schicken
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
        
        /**
         * Parst das DE am Beginn des uebergebenen Strings.
         * @param s der String, dessen Anfang das DE enthaelt.
         * @return der Reststring.
         */
        override func parse(s: String) throws -> String {
            // 1. LDE ermitteln (hex)
            var index = s.startIndex.advancedBy(2);
            let lenString = s.substringToIndex(index);
            if let len = Int(lenString, radix: 16) {
                self.lde = len;
            } else {
                throw HBCIError.ParseError;
            }
            
            // 2. tatsaechliche Laenge ermitteln
            self.length = lde & 0x3F;
            
            // Encoding gibts hier noch nicht.
            // Das passiert erst beim Rendern
            
            // Wenn kein Control-Byte vorhanden ist, muss es HHD 1.3 sein
            owner.version = .HHD13;
            
            // 3. Control-Byte ermitteln, falls vorhanden
            if (lde & bit_controlbyte) != 0 {
                owner.version = .HHD14;
                
                // Es darf maximal 9 Controlbytes geben
                for var i = 0; i < 10; i++ {
                    // 2 Zeichen, Hex
                    let byteString = s.substringWithRange(Range(start: index, end: index.advancedBy(2)));
                    index = index.advancedBy(2);
                    if let byte = Int(byteString, radix: 16) {
                        controlBytes.append(UInt8(byte));
                        if (byte & bit_controlbyte) == 0 {
                            break;
                        }
                    } else {
                        throw HBCIError.ParseError;
                    }
                }
            }
            
            // 4. Startcode ermitteln
            self.data = s.substringWithRange(Range(start: index, end: index.advancedBy(length)));
            return s.substringFromIndex(index.advancedBy(length));
        }
        
        override func renderLength() throws -> String {
            let s = try super.renderLength();
            
            // HHD 1.3 -> gibt keine Controlbytes
            if owner.version == .HHD13 {
                return s;
            }
            
            // HHD 1.4 -> aber keine Controlbytes vorhanden
            if controlBytes.count == 0 {
                return s;
            }
            
            // Controlbytes reincodieren
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
    
    convenience init(code:String) throws {
        self.init();

        // we first try with HHD 1.4
        do {
            try parse(code, version: .HHD14);
        }
        catch {
            try parse(code, version: .HHD13);
        }
    }
    
    /**
     * Entfernt das CHLGUC0026....CHLGTEXT aus dem Code, falls vorhanden.
     * Das sind HHD 1.3-Codes, die nicht im "Challenge HHDuc" uebertragen
     * wurden sondern direkt im Challenge-Freitext,
     * @param code
     * @return
     */
    func clean(code:String) ->String {
        var cleaned = code.stringByReplacingOccurrencesOfString(" ", withString: ""); // Alle Leerzeichen entfernen
        cleaned = cleaned.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()); // Whitespaces entfernen
        
        // Jetzt checken, ob die beiden Tokens enthalten sind
        if let r1 = cleaned.rangeOfString("CHLGUC"), r2 = cleaned.rangeOfString("CHLGTEXT") {
            if r1.startIndex >= r2.startIndex {
                return cleaned;
            }
            
            // Erstmal den 2. Token abschneiden
            // Dann alles abschneiden bis zum Beginn von "CHLGUC"
            // Wir haben eigentlich nicht nur "CHLGUC" sondern "CHLGUC0026"
            // Wobei die 4 Zahlen sicher variieren koennen. Wir schneiden einfach alles ab.
            cleaned = cleaned.substringWithRange(Range(start: r1.startIndex.advancedBy(10), end: r2.startIndex));

            // Jetzt vorn noch ne "0" dran haengen, damit LC wieder 3-stellig ist - wie bei HHD 1.4
            return "0" + cleaned;
        }
        return cleaned;
    }
    
    func parse(code:String, version:HHDVersion) throws {
        reset();
        
        var cd = clean(code);
        
        // 1. LC ermitteln. Banales ASCII
        let len = version == .HHD14 ? HBCIFlickerCode.lc_len_hhd14 : HBCIFlickerCode.lc_len_hhd13;
        if let lc = Int(cd.substringToIndex(len)) {
            self.lc = lc;
        } else {
            throw HBCIError.ParseError;
        }
        
        cd = cd.substringFromIndex(len);
        
        // 2. Startcode/Control-Bytes
        cd = try startCode.parse(cd);
        
        // 3. LDE/DE 1-3
        cd = try de1.parse(cd);
        cd = try de2.parse(cd);
        cd = try de3.parse(cd);
        
        if cd.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) > 0 {
            rest = cd;
        }
    }
    
    func render() throws ->String {
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
    
    /**
     * Generiert den Payload neu.
     * Das ist der komplette Code, jedoch ohne Pruefziffern am Ende.
     * @return der neu generierte Payload.
     */
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
        
        var len = s.lengthOfBytesUsingEncoding(NSASCIIStringEncoding);
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
    
    /**
     * Berechnet die Luhn-Pruefziffer neu.
     * @return die Pruefziffer im Hex-Format.
     */
    func createLuhnChecksum() throws ->String {
        ////////////////////////////////////////////////////////////////////////////
        // Schritt 1: Payload ermitteln

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
        
        //
        ////////////////////////////////////////////////////////////////////////////
        
        ////////////////////////////////////////////////////////////////////////////
        // Schritt 2: Pruefziffer berechnen
        var luhn = 0;
        for (index, char) in s.characters.enumerate() {
            if let x = Int(String(char), radix: 16) {
                luhn += index % 2 == 0 ? x : quersumme(2*x);
            } else {
                logError("\(char) cannot be parsed as Hex");
                throw HBCIError.ParseError;
            }
        }
        
        // Ermittelt, wieviel zu "luhnsum" addiert werden muss, um auf die
        // naechste Zahl zu kommen, die durch 10 teilbar ist
        // Beispiel:
        // luhnsum = 129 modulo 10 -> 9
        // 10 - 9 = 1
        // also 129 + 1 = 130
        let mod = luhn % 10;
        if mod == 0 {
            return "0"; // Siehe "Schritt 3" in tan_hhd_uc_v14.pdf, Seite 17
        }
        
        let rest = 10 - mod;
        let sum = luhn + rest;
        
        // Von dieser Summe ziehen wir die berechnete Summe ab
        // Beispiel:
        // 130 - 129 = 1
        // 1 -> ist die Luhn-Checksumme.
        luhn = sum - luhn;
        return toHex(UInt8(luhn));
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

/**
 * Wandelt alle Zeichen des String gemaess des jeweiligen ASCII-Wertes in HEX-Codierung um.
 * Beispiel: Das Zeichen "0" hat den ASCII-Wert "30" in Hexadezimal-Schreibweise.
 * @param s der umzuwandelnde String.
 * @return der codierte String.
 */
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

