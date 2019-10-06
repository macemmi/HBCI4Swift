//
//  HBCISmartCardDDV.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 19.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation


open class HBCISmartcardDDV : HBCISmartcard {
    var cardType:CardType;
    var cardID:NSData?
    
    open var cardNumber:NSString?
    
    public enum CardType {
        case cardtype_UNKNOWN, cardtype_DDV0, cardtype_DDV1, cardtype_RSA
    }

    // constants
    let DDV_EF_ID  = 0x19
    let DDV_EF_BANK = 0x1A
    let DDV_EF_MAC = 0x1B
    let DDV_EF_SEQ = 0x1C
    
    let APDU_CLA_EXT:UInt8 = 0xB0
    let APDU_INS_GET_KEYINFO:UInt8 = 0xEE;
    
    let APDU_SM_RESP_DESCR:UInt8 = 0xBA;
    let APDU_SM_CRT_CC:UInt8 = 0xB4;
    let APDU_SM_REF_INIT_DATA:UInt8 = 0x87;
    let APDU_SM_VALUE_LE:UInt8 = 0x96;
    
    let KEY_TYPE_DF:UInt8 = 0x80;

    override public init(readerName:String) {
        cardType = CardType.cardtype_UNKNOWN;
        super.init(readerName: readerName);
    }
    
    override open func connect(_ tries:Int) -> ConnectResult {
        let result = super.connect(tries);
        if result == ConnectResult.connected || result == ConnectResult.reconnected {
            // get card type
            cardType = getCardType();
            if cardType != CardType.cardtype_DDV0 && cardType != CardType.cardtype_DDV1 {
                // Card is not supported
                disconnect();
                return ConnectResult.not_supported;
            }
            return result;
        }
        return result;
    }
    
    func trim(_ s:NSString) ->String {
        return s.trimmingCharacters(in: CharacterSet.whitespaces);
    }

    func getInfoForKey(_ keyNum:UInt8, keyType:UInt8) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_EXT, APDU_INS_GET_KEYINFO, keyType, keyNum, 0x00 ];
        let apdu = NSData(bytes: UnsafePointer<UInt8>(command), length: 5);
        let result = sendAPDU(apdu);
        if checkResult(result) {
            return extractDataFromResult(result!);
        }
        return nil;
    }
    
    open func getCardType() ->CardType {
        let files:[[UInt8]] = [
            [ 0xd2,0x76,0x00,0x00,0x25,0x48,0x42,0x01,0x00 ],
            [ 0xd2,0x76,0x00,0x00,0x25,0x48,0x42,0x02,0x00 ],
            [ 0xd2,0x76,0x00,0x00,0x74,0x48,0x42,0x01,0x10 ]
        ];
        
        var i = 0;
        
        // do  not log errors
        noErrorLog = true;
        while i < 3 {
            if !selectRoot() {
                i += 1;
                continue;
            }
            let fileName = NSData(bytes: UnsafePointer<UInt8>(files[i]), length: 9);
            if selectFileByName(fileName) {
                break;
            }
            i += 1;
        }
        noErrorLog = false;
        
        switch(i) {
        case 0: return CardType.cardtype_DDV0;
        case 1: return CardType.cardtype_DDV1;
        case 2: return CardType.cardtype_RSA;
        default: return CardType.cardtype_UNKNOWN;
        }
    }
    
    open func getCardID() ->Bool {
        let result = readRecordWithSFI(1, sfi: DDV_EF_ID);
        if let res = result {
            cardID = res;
            
            var cardid = [UInt8](repeating: 0, count: 16);
            let p = res.bytes.bindMemory(to: UInt8.self, capacity: res.length);
            for i in 0 ..< 8 {
                cardid[i<<1] = ((p[i+1] >> 4) & 0x0F) + 0x30;
                cardid[(i<<1)+1] = ((p[i+1]) & 0x0F) + 0x30;
            }
            cardNumber = NSString(bytes: cardid, length: 16, encoding: String.Encoding.isoLatin1.rawValue);
            return true;
        }
        return false;
    }
    
    open func writeBankData(_ idx:Int, data:HBCICardBankData) ->Bool {
        let raw = UnsafeMutablePointer<UInt8>.allocate(capacity: 88);
        for i in 0 ..< 88 {
            raw[i] = 0x20;
        }
        
        if let name = data.name.data(using: String.Encoding.isoLatin1) {
            memcpy(raw, (name as NSData).bytes, name.count>20 ? 20:name.count);
        }
        if let host = data.host.data(using: String.Encoding.isoLatin1) {
            memcpy(raw.advanced(by: 25), (host as NSData).bytes, host.count>28 ? 28:host.count);
        }
        if let hostAdd = data.hostAdd.data(using: String.Encoding.isoLatin1) {
            memcpy(raw.advanced(by: 53), (hostAdd as NSData).bytes, hostAdd.count>2 ? 2:hostAdd.count);
        }
        if let country = data.country.data(using: String.Encoding.isoLatin1) {
            memcpy(raw.advanced(by: 55), (country as NSData).bytes, country.count>3 ? 3:country.count);
        }
        if let userId = data.userId.data(using: String.Encoding.isoLatin1) {
            memcpy(raw.advanced(by: 58), (userId as NSData).bytes, userId.count>30 ? 30:userId.count);
        }
        if let bankCode = data.bankCode.data(using: String.Encoding.isoLatin1) {
            let p = UnsafeMutablePointer<UInt8>(mutating: (bankCode as NSData).bytes.bindMemory(to: UInt8.self, capacity: bankCode.count));
            for i in 0 ..< 4 {
                var c1 = p[i<<1] - 0x30;
                let c2 = p[i<<1 + 1] - 0x30;
                
                if c1 == 2 && c2 == 0 {
                    c1 ^= 0x0F;
                }
                raw[20+i] = (c1<<4) | c2;
            }
        }
        raw[24] = data.commtype;
        let recordData = NSData(bytes: UnsafePointer<UInt8>(raw), length: 88);
        let success = writeRecordWithSFI(idx, sfi: DDV_EF_BANK, data: recordData);
        raw.deinitialize(count: 88);
        return success;
    }
    
    open func getBankData(_ idx:Int) ->HBCICardBankData? {
        if let result = readRecordWithSFI(idx, sfi: DDV_EF_BANK) {
            var p = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.length));
            var name, host, hostAdd, country, userId, bankCode:NSString!

            name = NSString(bytes: p, length: 20, encoding: String.Encoding.isoLatin1.rawValue);
            if name == nil {
                return nil;
            }
            p = p.advanced(by: 25);
            host = NSString(bytes: p, length: 28, encoding: String.Encoding.isoLatin1.rawValue);
            if host == nil {
                return nil;
            }
            p = p.advanced(by: 28);
            hostAdd = NSString(bytes: p, length: 2, encoding: String.Encoding.isoLatin1.rawValue);
            if hostAdd == nil {
                return nil;
            }
            p = p.advanced(by: 2);
            country = NSString(bytes: p, length: 3, encoding:String.Encoding.isoLatin1.rawValue);
            if country == nil {
                return nil;
            }
            p = p.advanced(by: 3);
            userId = NSString(bytes: p, length: 30, encoding: String.Encoding.isoLatin1.rawValue);
            if userId == nil {
                return nil;
            }
            
            p = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.length)).advanced(by: 20);
            var blz = [UInt8](repeating: 0, count: 8);
            for i in 0 ..< 4 {
                var nibble:UInt8 = 0;
                nibble=(p[i]>>4)&0x0F;
                if (nibble>0x09) {
                    nibble^=0x0F;
                }
                blz[i<<1]=nibble+0x30;
                
                nibble=p[i]&0x0F;
                if (nibble>0x09) {
                    nibble^=0x0F;
                }
                blz[(i<<1)+1]=nibble+0x30;
            }
            bankCode = NSString(bytes: blz, length: 8, encoding: String.Encoding.isoLatin1.rawValue);
            if bankCode == nil {
                return nil;
            }
            
            let ct = UnsafeMutablePointer<UInt8>(mutating: (result as NSData).bytes.bindMemory(to: UInt8.self, capacity: result.length))[24];
            
            return HBCICardBankData(name: trim(name), bankCode: trim(bankCode), country: trim(country), host: trim(host), hostAdd: trim(hostAdd), userId: trim(userId), commtype: ct);
        }
        return nil;
    }
    
    func getKeyData() ->Array<HBCICardKeyData> {
        var keys = Array<HBCICardKeyData>();
        
        if cardType == CardType.cardtype_DDV0 {
            if selectSubFileWithId(0x13) {
                if let record = readRecord(1) {
                    let p = UnsafeMutablePointer<UInt8>(mutating: record.bytes.bindMemory(to: UInt8.self, capacity: record.length));
                    let key = HBCICardKeyData(keyNumber: p[0], keyVersion: p[4], keyLength: p[1], algorithm: p[2]);
                    keys.append(key);
                }
            }
            if selectSubFileWithId(0x14) {
                if let record = readRecord(1) {
                    let p = UnsafeMutablePointer<UInt8>(mutating: record.bytes.bindMemory(to: UInt8.self, capacity: record.length));
                    let key = HBCICardKeyData(keyNumber: p[0], keyVersion: p[3], keyLength: p[1], algorithm: p[2]);
                    keys.append(key);
                }
            }
        } else if cardType == CardType.cardtype_DDV1 {
            if let info = getInfoForKey(2, keyType: KEY_TYPE_DF) {
                let p = UnsafeMutablePointer<UInt8>(mutating: info.bytes.bindMemory(to: UInt8.self, capacity: info.length));
                let key = HBCICardKeyData(keyNumber: 2, keyVersion: p[info.length - 1], keyLength: 0, algorithm: 0);
                keys.append(key);
            }
            if let info = getInfoForKey(3, keyType: KEY_TYPE_DF) {
                let p = UnsafeMutablePointer<UInt8>(mutating: info.bytes.bindMemory(to: UInt8.self, capacity: info.length));
                let key = HBCICardKeyData(keyNumber: 3, keyVersion: p[info.length - 1], keyLength: 0, algorithm: 0);
                keys.append(key);
            }
        } else {
            // not supported
            logInfo("HBCISmartcard: get key data is not supported for this card type");
        }
        
        return keys;
    }
    
    func getSignatureId() ->UInt16 {
        if let result = readRecordWithSFI(1, sfi: DDV_EF_SEQ) {
            let p = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.length));
            return (UInt16(p[0])<<8) | (UInt16(p[1]) & 0xff);
        }
        return 0;
    }
    
    func writeSignatureId(_ sigid:Int) ->Bool {
        let buffer:[UInt8] = [ UInt8(sigid >> 8), UInt8(sigid & 0xff) ];
        let data = NSData(bytes: UnsafePointer<UInt8>(buffer), length: 2);
        return writeRecordWithSFI(1, sfi: DDV_EF_SEQ, data: data);
    }
    
    func sign(_ hash:Data) ->NSData? {
        let pHash = UnsafeMutablePointer<UInt8>(mutating: (hash as NSData).bytes.bindMemory(to: UInt8.self, capacity: hash.count));
        
        // write right key part
        let rKey = NSData(bytes: UnsafePointer<UInt8>(pHash.advanced(by: 8)), length: 12);
        if !writeRecordWithSFI(1, sfi: DDV_EF_MAC, data: rKey) {
            return nil;
        }
        
        if cardType == CardType.cardtype_DDV0 {
            let lKey = NSData(bytes: UnsafePointer<UInt8>(pHash), length: 8);
            
            // store left part
            if !putData(0x0100, data: lKey) {
                return nil;
            }
            
            // re-read right part and signature
            let command:[UInt8] = [ APDU_CLA_SM_PROPR, APDU_INS_READ_RECORD, 1, UInt8(Int(DDV_EF_MAC<<3) | 0x04), 0x00 ];
            let apdu = NSData(bytes: UnsafePointer<UInt8>(command), length: 5);
            if let result = sendAPDU(apdu) {
                let p = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.length)).advanced(by: 12);
                return NSData(bytes: UnsafePointer<UInt8>(p), length: 8);
            }
            return nil;
        } else {
            // DDV-1
            let command1:[UInt8] = [
                APDU_CLA_SM1, APDU_INS_READ_RECORD, 1, UInt8(Int(DDV_EF_MAC<<3) | 0x04), 0x11, APDU_SM_RESP_DESCR, 0x0C, APDU_SM_CRT_CC,
                0x0A, APDU_SM_REF_INIT_DATA, 0x08
            ];
            let command2:[UInt8] = [ APDU_SM_VALUE_LE, 0x01, 0x00, 0x00 ];
            
            let apdu = NSMutableData(bytes: command1, length: 11);
            apdu.append(pHash, length: 8);
            apdu.append(command2, length: 4);
            
            if let result = sendAPDU(apdu) {
                let p = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.length)).advanced(by: 16);
                return NSData(bytes: UnsafePointer<UInt8>(p), length: 8);
            }
        }
        return nil;
    }
    
    func getEncryptionKeys(_ keyNum:UInt8) ->(plain:NSData, encrypted:NSData)? {
        // get 16 byte key from 8 byte keys
        if let plain1 = getChallenge(8) {
            if let encr1 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: plain1) {
                if let plain2 = getChallenge(8) {
                    if let encr2 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: plain2) {
                        // now build keys and return
                        let plain = NSMutableData();
                        plain.append(plain1 as Data);
                        plain.append(plain2 as Data);
                        
                        let encrypted = NSMutableData();
                        encrypted.append(encr1 as Data);
                        encrypted.append(encr2 as Data);
                        return (plain,encrypted);
                    }
                }
            }
        }
        return nil;
    }
    
    func decryptKey(_ keyNum:UInt8, encrypted:NSData) ->NSData? {
        // decrypt 2 8-byte parts
        let encr1 = NSData(bytes: encrypted.bytes, length: 8);
        let p = encrypted.bytes.bindMemory(to: UInt8.self, capacity: encrypted.length).advanced(by: 8);
        let encr2 = NSData(bytes: UnsafePointer<UInt8>(p), length: 8);
        
        if let plain1 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: encr1) {
            if let plain2 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: encr2) {
                let result = NSMutableData();
                result.append(plain1 as Data);
                result.append(plain2 as Data);
                return result;
            }
        }
        return nil;
    }
}
