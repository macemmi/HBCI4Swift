//
//  HBCIConnection.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 07.01.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

protocol HBCIConnection {
    func sendMessage(_ msg:Data) throws ->Data;
    func close();
}

class HBCIPinTanConnection : HBCIConnection {
    let url:URL;
    
    init(url:URL) {
        self.url = url;
    }
    
    func sendMessage(_ msg:Data) throws ->Data {
        
        let encData = msg.base64EncodedData(options: NSData.Base64EncodingOptions());
        
        let request = NSMutableURLRequest(url: url);
        request.httpMethod = "POST";
        request.httpBody = encData;
        request.timeoutInterval = 240;
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type");
        
        var response:URLResponse?;
        
        do {
            let result = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response);
            
            // check status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    logError(httpResponse.description);
                    logError(String(data: result, encoding: String.Encoding.isoLatin1));
                    throw HBCIError.connection(url.path);
                }
            } else {
                logError("No HTTP response");
                throw HBCIError.connection(url.path);
            }
            
            
            let decoded = Data(base64Encoded: result, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters);
            
            if let value = decoded {
                return value
            }
            
        } catch let err as NSError {
            logError(err.localizedDescription);
            throw HBCIError.connection(url.path);
        }
        
        throw HBCIError.connection(url.path);
    }
    
    func close() {
    }
}

class HBCIDDVConnection : HBCIConnection {
    let host:String;
    var inputStream:InputStream!
    var outputStream:OutputStream!

    init(host:String) throws {
        self.host = host;
        
        var inp :InputStream?
        var out :OutputStream?
        
        Stream.getStreamsToHost(withName: host, port: 3000, inputStream: &inp, outputStream: &out);
        
        if let inpStr = inp, let outStr = out {
            self.inputStream = inpStr;
            self.outputStream = outStr;
        } else {
            logError("Unable to open connection to server \(host)");
            throw HBCIError.connection(host);
        }
    }
    
    func sendMessage(_ msg: Data) throws -> Data {
        if inputStream.streamStatus != Stream.Status.open {
            inputStream.open();
        }
        if outputStream.streamStatus != Stream.Status.open {
            outputStream.open();
        }
        
        outputStream.write((msg as NSData).bytes.bindMemory(to: UInt8.self, capacity: msg.count), maxLength: msg.count);
        
        var tries = 0;
        // wait for server to respond
        while !inputStream.hasBytesAvailable {
            sleep(1);
            if tries == 30 {
                break;
            }
            tries += 1;
        }
        if tries == 30 {
            logError("Timeout");
            inputStream.close();
            throw HBCIError.serverTimeout(host);
        }
        
        let data = NSMutableData();
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4000);
        while inputStream.hasBytesAvailable {
            let bytes = inputStream.read(buffer, maxLength: 4000);
            data.append(buffer, length: bytes);
        }
        buffer.deinitialize();
        
        return data as Data;
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
