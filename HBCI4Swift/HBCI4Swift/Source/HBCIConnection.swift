//
//  HBCIConnection.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

protocol HBCIConnection {
    func sendMessage(msg:NSData) throws ->NSData;
    func close();
}

class HBCIPinTanConnection : HBCIConnection {
    let url:NSURL;
    
    init(url:NSURL) {
        self.url = url;
    }
    
    func sendMessage(msg:NSData) throws ->NSData {
        
        let encData = msg.base64EncodedDataWithOptions(NSDataBase64EncodingOptions());
        
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "POST";
        request.HTTPBody = encData;
        request.timeoutInterval = 240;
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type");
        
        var response:NSURLResponse?;
        
        do {
            let result = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response);
            
            // check status code
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    logError(httpResponse.description);
                    logError(NSString(data: result, encoding: NSISOLatin1StringEncoding) as! String)
                    throw HBCIError.Connection(url.path!);
                }
            } else {
                logError("No HTTP response");
                throw HBCIError.Connection(url.path!);
            }
            
            
            let decoded = NSData(base64EncodedData: result, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters);
            
            if let value = decoded {
                return value
            }
            
        } catch let err as NSError {
            logError(err.localizedDescription);
            throw HBCIError.Connection(url.path!);
        }
        
        throw HBCIError.Connection(url.path!);
    }
    
    func close() {
    }
}

class HBCIDDVConnection : HBCIConnection {
    let host:String;
    var inputStream:NSInputStream!
    var outputStream:NSOutputStream!

    init(host:String) throws {
        self.host = host;
        
        var inp :NSInputStream?
        var out :NSOutputStream?
        
        NSStream.getStreamsToHostWithName(host, port: 3000, inputStream: &inp, outputStream: &out);
        
        if let inpStr = inp, outStr = out {
            self.inputStream = inpStr;
            self.outputStream = outStr;
        } else {
            logError("Unable to open connection to server \(host)");
            throw HBCIError.Connection(host);
        }
    }
    
    func sendMessage(msg: NSData) throws -> NSData {
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
            throw HBCIError.ServerTimeout(host);
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
    
    func close() {
        if inputStream != nil {
            inputStream.close();
        }
        if outputStream != nil {
            outputStream.close();
        }
    }


}
