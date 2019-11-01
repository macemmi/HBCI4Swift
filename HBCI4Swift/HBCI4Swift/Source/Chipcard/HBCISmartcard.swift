//
//  HBCISmartcard.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 15.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

import PCSCard.winscard
//import PCSCard.wintypes
import PCSCard.pcsclite

typealias DWORD = UInt32


open class HBCISmartcard {
    public let readerName:String;
    var version:UInt8 = 0;
    var _hCard:SCARDHANDLE?
    var _ioctl_verify:DWORD?
    var _ioctl_pinprops:DWORD?
    var _ioctl_readerdirect:DWORD?
    var connected:Bool;
    var noErrorLog = false;
    
    static var _hContext:SCARDCONTEXT?
    
    // constants
    let CM_IOCTL_GET_FEATURE_REQUEST:DWORD = 0x42000D48;
    
    let APDU_CLA_STD:UInt8 = 0x00
    let APDU_CLA_SM_PROPR:UInt8 = 0x04;
    let APDU_CLA_SM1:UInt8 = 0x08;
    
    let APDU_INS_SELECT_FILE:UInt8 = 0xA4;
    let APDU_INS_READ_RECORD:UInt8 = 0xB2;
    let APDU_INS_GET_CHALLENGE:UInt8 = 0x84;
    let APDU_INS_VERIFY:UInt8 = 0x20;
    let APDU_INS_WRITE_RECORD:UInt8 = 0xDC;
    let APDU_INS_PUT_DATA:UInt8 = 0xDA;
    let APDU_INS_AUTH_INT:UInt8 = 0x88;
    let APDU_SEL_RET_NOTHING:UInt8 = 0x0C;
    
    //let FEATURE_VERIFY_PIN_DIRECT = 0x06 /**< Verify PIN */

    public enum ConnectResult {
        case connected, reconnected, no_card, no_context, not_supported, error
    }


    class func establishReaderContext() ->Bool {
        if _hContext == nil {
            var context:SCARDCONTEXT = 0;
            let rv = SCardEstablishContext(UInt32(SCARD_SCOPE_SYSTEM), nil, nil, &context);
            if rv != SCARD_S_SUCCESS {
                logInfo(String(format:"HBCISmartcard: could not establish connection to chipcard driver (%X)", rv));
                return false;
            } else {
                _hContext = context;
            }
        }
        return true;
    }
    
    open class func readers() ->Array<String>? {
        var readerInfoLen:DWORD = 0;
        var result = Array<String>();
        
        if _hContext == nil && !establishReaderContext() {
            return nil;
        }
        
        if let context = _hContext {
            var rv = SCardListReaders(context, nil, nil, &readerInfoLen);
            if rv != SCARD_S_SUCCESS {
                logInfo(String(format:"HBCISmartcard: could not list available readers (%X)", rv));
                return nil;
            }
            
            var readerInfo = [Int8](repeating: 0, count: Int(readerInfoLen));
            rv = SCardListReaders(context, nil, &readerInfo, &readerInfoLen);
            
            var p = UnsafeMutablePointer<Int8>(mutating: readerInfo);
            while p.pointee != 0 {
                if let s = NSString(cString: p, encoding: String.Encoding.isoLatin1.rawValue) {
                    result.append(s as String);
                }
                p = p.advanced(by: Int(strlen(p))+1);
            }
        }
        return result;
    }
    
    class func releaseReaderContext() ->Bool {
        if let context = _hContext {
            if SCardReleaseContext(context) != SCARD_S_SUCCESS {
                return false;
            }
            _hContext = 0;
        }
        return true;
    }
    
    init(readerName:String) {
        self.readerName = readerName;
        connected = false;
    }
    
    func convertToUInt32(_ x:Int32) ->UInt32 {
        if x >= 0 {
            return UInt32(x);
        } else {
            let i = 0x100000000+Int(x);
            return UInt32(i);
        }
    }
    
    func checkResult(_ result:NSData?) ->Bool {
        if let data = result {
            var p = data.bytes.bindMemory(to: UInt8.self, capacity: data.length).advanced(by: data.length-2);
            var status = UInt16(p.pointee) << 8;
            p = p.advanced(by: 1);
            status = status + (UInt16(p.pointee) & 0xff);
            
            if status & 0xFFFF == 0x9000 {
                return true;
            }
        }
        return false;
    }
    
    func extractDataFromResult(_ result:NSData) ->NSData {
        return NSData(bytes: result.bytes, length: result.length-2);
    }
    
    
    open func verifyPin() ->Bool {
        var sendBuffer = [UInt8](repeating:0, count:Int(MAX_BUFFER_SIZE));
        var recBuffer = [UInt8](repeating:0, count:Int(MAX_BUFFER_SIZE));
        var pin_verify = PIN_VERIFY_STRUCTURE();
        
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_VERIFY, 0x00, 0x81, 0x08, 0x25, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ];
        
        pin_verify.bTimerOut = 15;
        pin_verify.bTimerOut2 = 5;
        pin_verify.bmFormatString = 0x89;
        pin_verify.bmPINBlockString = 0x07;
        pin_verify.bmPINLengthFormat = 0x10;
        pin_verify.wPINMaxExtraDigit = 0x0408;
        pin_verify.bEntryValidationCondition = 0x02;
        pin_verify.bNumberMessage = 0x01;
        pin_verify.wLangId = 0x0904;
        pin_verify.bMsgIndex = 0x00;
        pin_verify.bTeoPrologue.0 = 0x00;
        pin_verify.bTeoPrologue.1 = 0x00;
        pin_verify.bTeoPrologue.2 = 0x00;
        pin_verify.ulDataLength = 13;
        
        //let p = toPointer(&pin_verify);
        let vLen = MemoryLayout<PIN_VERIFY_STRUCTURE>.size - 1;
        //let p = UnsafeRawPointer(UnsafeMutablePointer(&pin_verify)).assumingMemoryBound(to: UInt8.self);
        UnsafeMutablePointer(&pin_verify).withMemoryRebound(to: UInt8.self, capacity: vLen) {
            for i in 0..<vLen {
                sendBuffer[i] = $0[i];
            }
        }
        
        for i in 0..<command.count {
            sendBuffer[vLen+i] = command[i];
        }
        
        let length = DWORD(vLen + command.count);
        var rLength:DWORD = 0;
        
        if let hCard = _hCard, let ioctl_verify = _ioctl_verify {
            let rv = SCardControl132(hCard, ioctl_verify, &sendBuffer, length, &recBuffer, DWORD(MAX_BUFFER_SIZE), &rLength);
            if rv == SCARD_S_SUCCESS {
                if recBuffer[0] == 0x90 && recBuffer[1] == 0x00 {
                    return true;
                }
            } else {
                logInfo(String(format:"HBCISmartcard: verify failed (%X)", rv));
                logCommand(NSData(bytes:sendBuffer, length:Int(length)), result:NSData(bytes:recBuffer, length:Int(rLength)));
            }
        }
        return false;
    }
    
    func retrieveCapabilities() ->Bool {
        var length:DWORD = 0;
        
        if let hCard = _hCard {
            let recBuffer = [UInt8](repeating:0, count:Int(MAX_BUFFER_SIZE));
            let pRecBuffer = UnsafeMutablePointer<UInt8>(mutating: recBuffer);
            let rv = SCardControl132(hCard, CM_IOCTL_GET_FEATURE_REQUEST, nil, 0, pRecBuffer, DWORD(MAX_BUFFER_SIZE), &length);
            if rv != SCARD_S_SUCCESS {
                // log
                logInfo(String(format:"HBCISmartcard: feature request failed (%X)", rv));
                return false;
            }
            
            if (Int(length) % MemoryLayout<PCSC_TLV_STRUCTURE>.size) != 0 {
                // log
                return false;
            }
            
            let count = Int(length) / MemoryLayout<PCSC_TLV_STRUCTURE>.size;
            
            pRecBuffer.withMemoryRebound(to: PCSC_TLV_STRUCTURE.self, capacity: count) {
                var p = $0;
                for _ in 0 ..< count {
                    switch(p.pointee.tag) {
                    case UInt8(FEATURE_VERIFY_PIN_DIRECT): _ioctl_verify = p.pointee.value.bigEndian;
                        //case UInt8(FEATURE_IFD_PIN_PROPERTIES): _ioctl_pinprops = p.memory.value.bigEndian;
                        //case UInt8(FEATURE_MCT_READER_DIRECT): _ioctl_readerdirect = p.memory.value.bigEndian;
                    default: break;
                    }
                    p = p.advanced(by: 1);
                }
            }
            
            if _ioctl_verify == nil {
                // log
                logInfo("HBCISmartcard: IOCTL for verify could not be retrieved");
                return false;
            }
        }
        return true;
    }
    
    open func isConnected() ->Bool {
        var state:DWORD = 0;
        var prot:DWORD = 0;
        var length:DWORD = 0;
        var attrLen = DWORD(MAX_ATR_SIZE);
        
        // get card status
        if let hCard = _hCard {
            var attributes = [UInt8](repeating:0, count:Int(attrLen));
            
            let rv = SCardStatus(hCard, nil, &length, &state, &prot, &attributes, &attrLen);
            
            if rv != SCARD_S_SUCCESS {
                logInfo(String(format:"HBCISmartcard: chipcard status could not be retrieved (%X)", rv));
                return false;
            }
            if (state & DWORD(SCARD_ABSENT)) != 0 {
                return false;
            }
            return true;
        }
        return false;
    }
    
    // check if reader ist still connected
    open func isReaderConnected() ->Bool {
        if let readers = HBCISmartcard.readers() {
            return readers.contains(readerName);
        }
        return false;
    }
    
    open func connect(_ tries:Int) ->ConnectResult {
        var prot:DWORD = 0;
        var n = 0;
        var reconnected = false;
        var rv:Int32 = 0;
        
        if !HBCISmartcard.establishReaderContext() {
            return ConnectResult.no_context;
        }
        
        if let context = HBCISmartcard._hContext {
            while n < tries {
                // once connection was successful, following accesses have to be done with
                // a reconnect
                if let hCard = _hCard {
                    rv = SCardReconnect(hCard, DWORD(SCARD_SHARE_EXCLUSIVE), DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), DWORD(SCARD_RESET_CARD), &prot);
                    if rv == SCARD_S_SUCCESS {
                        reconnected = true;
                    }
                } else {
                    var hCard:SCARDHANDLE = 0;
                    rv = SCardConnect(context, readerName.cString(using: String.Encoding.isoLatin1)!, DWORD(SCARD_SHARE_EXCLUSIVE), DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), &hCard, &prot);
                    if rv == SCARD_S_SUCCESS {
                        _hCard = hCard;
                    }
                }
                if convertToUInt32(rv) == SCARD_E_NO_SMARTCARD {
                    if n < tries-1 {
                        // wait 500ms
                        var a = timespec();
                        var b = timespec();
                        a.tv_sec = 0;
                        a.tv_nsec = 500000000;
                        nanosleep(&a, &b);
                    }
                    n += 1;
                } else {
                    break;
                }
            }
            
            if n < tries && rv == SCARD_S_SUCCESS {
                if isConnected() && retrieveCapabilities() {
                    if reconnected {
                        return ConnectResult.reconnected;
                    } else {
                        return ConnectResult.connected;
                    }
                }
            } else {
                if convertToUInt32(rv) == SCARD_E_NO_SMARTCARD {
                    return ConnectResult.no_card;
                }
            }
            logInfo(String(format: "HBCISmartcard: connection error (%X)", rv));
            return ConnectResult.error;
        } else {
            return ConnectResult.no_context;
        }
    }
    
    open func disconnect() {
        if let hCard = _hCard {
            SCardDisconnect(hCard, DWORD(SCARD_UNPOWER_CARD));
        }
    }
    
    func logCommand(_ command:NSData, result: NSData?) {
        var cm = "APDU command: ";
        var p = UnsafeMutablePointer<UInt8>(mutating: command.bytes.bindMemory(to: UInt8.self, capacity: command.length));
        for i in 0..<command.length {
            cm += String(format: "%.02X ", p[i]);
        }
        logInfo(cm);
        cm = "APDU command result: ";
        if let res = result {
            p = UnsafeMutablePointer<UInt8>(mutating: res.bytes.bindMemory(to: UInt8.self, capacity: res.length));
            for i in 0..<res.length {
                cm += String(format: "%.02X ", p[i]);
            }
        } else {
            cm += "none";
        }
        logInfo(cm);
    }
    
    func sendAPDU(_ command:NSData) ->NSData? {
        var length = DWORD(MAX_BUFFER_SIZE);
        var result:NSData?
        
        if let hCard = _hCard {
            var pioReceive = SCARD_IO_REQUEST();
            var recBuffer = [UInt8](repeating:0, count:Int(MAX_BUFFER_SIZE));
            
            let rv = SCardTransmit(hCard, &g_rgSCardT1Pci, command.bytes.assumingMemoryBound(to: UInt8.self), DWORD(command.length), &pioReceive, &recBuffer, &length);
            if rv == SCARD_S_SUCCESS {
                result = NSData(bytes: recBuffer, length: Int(length));
            }
            if !checkResult(result) && !noErrorLog {
                logCommand(command, result: result);
            }
        }
        return result;
    }
    
    func selectRoot() ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x00, APDU_SEL_RET_NOTHING, 0x02, 0x3F, 0x00 ];
        let apdu = Data(command);
        let result = sendAPDU(apdu as NSData);
        return checkResult(result);
    }
    
    func selectFileByName(_ fileName:NSData) ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x04, APDU_SEL_RET_NOTHING, UInt8(fileName.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.append(fileName as Data);
        let result = sendAPDU(apdu);
        return checkResult(result);
    }
    
    func readRecordWithSFI(_ recordNumber:Int, sfi:Int) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_READ_RECORD, UInt8(recordNumber), UInt8((sfi<<3) | 0x04), 0x00];
        let apdu = NSData(bytes: command, length: 5);
        let result = sendAPDU(apdu);
        if checkResult(result) {
            return extractDataFromResult(result!);
        }
        return nil;
    }
    
    func writeRecordWithSFI(_ recordNumber:Int, sfi:Int, data:NSData) ->Bool {
        let command:[UInt8] = [APDU_CLA_STD, APDU_INS_WRITE_RECORD, UInt8(recordNumber), UInt8((sfi<<3) | 0x04), UInt8(data.length) ];
        
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.append(data as Data);
        if let result = sendAPDU(apdu) {
            return checkResult(result);
        }
        return false;
     }
    
    func putData(_ tag:Int, data:NSData) ->Bool {
        let command:[UInt8] = [APDU_CLA_STD, APDU_INS_WRITE_RECORD, UInt8((tag>>8) & 0xff), UInt8(tag & 0xff), UInt8(data.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.append(data as Data);
        if let result = sendAPDU(apdu) {
            return checkResult(result);
        }
        return false;
    }

    func readRecord(_ recordNumber:Int) ->NSData? {
        return readRecordWithSFI(recordNumber, sfi: 0);
    }
    
    func selectSubFileWithId(_ fileId:Int) ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x02, APDU_SEL_RET_NOTHING, 0x02, UInt8((fileId>>8) & 0xFF), UInt8(fileId & 0xFF) ];
        let apdu = NSData(bytes: command, length: 7);
        let result = sendAPDU(apdu);
        return checkResult(result);
    }
    
    func getChallenge(_ size:UInt8) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_GET_CHALLENGE, 0x00, 0x00, size ];
        let apdu = NSData(bytes: command, length: 5);
        if let result = sendAPDU(apdu) {
            if checkResult(result) {
                return extractDataFromResult(result);
            }
        }
        return nil;
    }
    
    func internal_authenticate(_ keyNum:UInt8, keyType:UInt8, data:NSData) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_AUTH_INT, 0x00, keyType | keyNum, UInt8(data.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.append(data as Data);
        // append zero at the end
        var x:UInt8 = 0;
        apdu.append(&x, length: 1);
        if let result = sendAPDU(apdu) {
            if checkResult(result) {
                return extractDataFromResult(result);
            }
        }
        return nil;
    }
    
}
