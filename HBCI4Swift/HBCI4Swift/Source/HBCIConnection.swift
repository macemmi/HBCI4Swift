//
//  HBCIConnection.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HBCIConntectionTestMode {
    case none, write, read;
}

var testMode = HBCIConntectionTestMode.none;
var msgNum = 0;
var testData = Array<NSData>();

class HBCIConnection {
    
    enum Error: ErrorType {
        case ConnectionError, Timeout, TestDataError;
    }
    
    let url:NSURL?
    let host:String?
    
    var inputStream:NSInputStream!
    var outputStream:NSOutputStream!
    
    init(url:NSURL) {
        self.host = nil;
        self.url = url;
    }
    
    init(host:String) throws {
        self.url = nil;
        self.host = host;
        
        var inp :NSInputStream?
        var out :NSOutputStream?
        
        NSStream.getStreamsToHostWithName(host, port: 3000, inputStream: &inp, outputStream: &out);
        
        if let inpStr = inp, outStr = out {
            self.inputStream = inpStr;
            self.outputStream = outStr;
        } else {
            logError("Unable to open connection to server \(host)");
            throw Error.ConnectionError;
        }
    }
    
    func sendMessage(msg:NSData) throws ->NSData {

        if let url = self.url {
            let encData = msg.base64EncodedDataWithOptions(NSDataBase64EncodingOptions());
            
            let request = NSMutableURLRequest(URL: url);
            request.HTTPMethod = "POST";
            request.HTTPBody = encData;
            request.timeoutInterval = 240;
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type");
            
            var response:NSURLResponse?;
            
            if testMode == .read {
                if msgNum < testData.count {
                    return testData[msgNum++];
                } else {
                    logError("HBCIConnection: no test data found for index \(msgNum)");
                    throw Error.TestDataError;
                }
            }
            
            do {
                let result = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response);

                // check status code
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        logError(httpResponse.description);
                        logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String)
                        throw Error.ConnectionError;
                    }
                } else {
                    logError("No HTTP response");
                    throw Error.ConnectionError;
                }
                
                
                let decoded = NSData(base64EncodedData: result, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters);

                if testMode == .write && decoded != nil {
                    testData.append(decoded!);
                }
                
                if let value = decoded {
                    return value
                }
            
            } catch let err as NSError {
                logError(err.localizedDescription);
                throw Error.ConnectionError;
            }
            
            throw Error.ConnectionError;
        }
        
        if self.host != nil {
            
            if inputStream.streamStatus != NSStreamStatus.Open {
                inputStream.open();
            }
            if outputStream.streamStatus != NSStreamStatus.Open {
                outputStream.open();
            }
            
            outputStream.write(UnsafePointer<UInt8>(msg.bytes), maxLength: msg.length);
            
            var tries = 0;
            // wait for server to respond
            while !inputStream.hasBytesAvailable {
                sleep(1);
                if tries == 30 {
                    break;
                }
                tries++;
            }
            if tries == 30 {
                logError("Timeout");
                inputStream.close();
                throw Error.Timeout;
            }
            
            let data = NSMutableData();
            let buffer = UnsafeMutablePointer<UInt8>.alloc(4000);
            while inputStream.hasBytesAvailable {
                let bytes = inputStream.read(buffer, maxLength: 4000);
                data.appendBytes(buffer, length: bytes);
            }
            buffer.destroy();
            
            return data;
        }
        
        throw Error.ConnectionError;
    }
    
    func close() {
        if inputStream != nil {
            inputStream.close();
        }
        if outputStream != nil {
            outputStream.close();
        }
    }
    
    class func setTestData(data:Array<NSData>) {
        testData = data;
        testMode = .read;
        msgNum = 0;
    }
    
    class func getTestData() ->Array<NSData> {
        return testData;
    }
    
    class func setWriteMode() {
        testMode = .write;
        msgNum = 0;
        testData = Array<NSData>();
    }
    
    class func loadTestData(name:String) ->Bool {
        let fman = NSFileManager();
        var fileNames = Array<String>();

        do {
            let files = try fman.contentsOfDirectoryAtPath("./../../../test")
            for file in files {
                if file.hasPrefix(name) {
                    fileNames.append(file );
                }
            }
            // sort filenames
            fileNames.sortInPlace(<);
            
            // load files
            for name in fileNames {
                if let data = fman.contentsAtPath("./../../../test/" + name) {
                    testData.append(data);
                }
            }
        } catch {
            return false;
        }
        testMode = .read;
        msgNum = 0;
        return true;
    }
    
    class func saveTestData(name:String) ->Bool {
        var index = 1;
        for data in testData {
            data.writeToFile("./../../../test/" + name + String(index) + ".data", atomically: false);
            index++;
        }
        return true;
    }
}
