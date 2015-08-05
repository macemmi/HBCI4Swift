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
    let url:NSURL?
    let host:String?
    
    var inputStream:NSInputStream!
    var outputStream:NSOutputStream!
    
    init(url:NSURL) {
        self.host = nil;
        self.url = url;
    }
    
    init?(host:String) {
        self.url = nil;
        self.host = host;
        
        var inp :NSInputStream?
        var out :NSOutputStream?
        
        NSStream.getStreamsToHostWithName(host, port: 3000, inputStream: &inp, outputStream: &out);
        
        if let inpStr = inp, outStr = out {
            self.inputStream = inpStr;
            self.outputStream = outStr;
        } else {
            logError("Unable to open connection to server "+host);
            return nil;
        }
    }
    
    func sendMessage(msg:NSData, error:NSErrorPointer) ->NSData? {

        if let url = self.url {
            let encData = msg.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.allZeros);
            
            var request = NSMutableURLRequest(URL: url);
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
                    return nil;
                }
            }
            
            if let result = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error) {
                // check status code
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        logError(httpResponse.description);
                        logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String)
                        return nil;
                    }
                } else {
                    logError("No HTTP response");
                    return nil;
                }
                
                
                let decoded = NSData(base64EncodedData: result, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters);
                
                if testMode == .write && decoded != nil {
                    testData.append(decoded!);
                }
                
                return decoded;
            }
            // todo: evaluate NSURLResponse?
            return nil;
        }
        
        if let host = self.host {
            
            if inputStream.streamStatus != NSStreamStatus.Open {
                inputStream.open();
            }
            if outputStream.streamStatus != NSStreamStatus.Open {
                outputStream.open();
            }
            
            /*
            if let fout = NSOutputStream(toFileAtPath: "/Users/emmi/PecuniaMessage.bin", append: false) {
                fout.open();
                let w2 = fout.write(UnsafePointer<UInt8>(msg.bytes), maxLength: msg.length);
                if w2 == -1 {
                    println(fout.streamError?.description);
                }
                fout.close();
            }
            
            if let fin = NSInputStream(fileAtPath: "/Users/emmi/TestMessage.bin") {
                fin.open();
                var data = NSMutableData();

                var buffer = UnsafeMutablePointer<UInt8>.alloc(4000);
                while fin.hasBytesAvailable {
                    let bytes = fin.read(buffer, maxLength: 4000);
                    data.appendBytes(buffer, length: bytes);
                }
                let written = outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length);
            }
            */
            
            let written = outputStream.write(UnsafePointer<UInt8>(msg.bytes), maxLength: msg.length);
            
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
                return nil;
            }
            
            var data = NSMutableData();
            var buffer = UnsafeMutablePointer<UInt8>.alloc(4000);
            while inputStream.hasBytesAvailable {
                let bytes = inputStream.read(buffer, maxLength: 4000);
                data.appendBytes(buffer, length: bytes);
            }
            buffer.destroy();
            
            //let decoded = NSData(base64EncodedData: data, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters);

            return data;
        }
        return nil;
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
        var error:NSError?
        if let files = fman.contentsOfDirectoryAtPath("./../../../test", error: &error) {
            for file in files {
                if file.hasPrefix(name) {
                    fileNames.append(file as! String);
                }
            }
            // sort filenames
            fileNames.sort(<);
            
            // load files
            for name in fileNames {
                if let data = fman.contentsAtPath("./../../../test/" + name) {
                    testData.append(data);
                }
            }
        } else {
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
