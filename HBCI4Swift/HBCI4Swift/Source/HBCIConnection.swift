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
    let url:NSURL;
    
    init(url:NSURL) {
        self.url = url;
    }
    
    func sendMessage(msg:NSData, error:NSErrorPointer) ->NSData? {
        let encData = msg.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.allZeros);
        
        var request = NSMutableURLRequest(URL: self.url);
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
