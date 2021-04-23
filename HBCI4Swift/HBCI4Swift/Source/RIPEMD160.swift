//
//  RIPEMD160.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 09.08.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class RIPEMD160 {
    var h0:UInt32 = 0x67452301;
    var h1:UInt32 = 0xefcdab89;
    var h2:UInt32 = 0x98badcfe;
    var h3:UInt32 = 0x10325476;
    var h4:UInt32 = 0xc3d2e1f0;
    
    var paddedData:Data!

    
    let r = [   0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
                3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12,
                1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
                4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13 ];
    
    let r´ = [  5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
                6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
                15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
                8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
                12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11 ];
    
    let s = [   11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
                7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
                11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
                11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
                9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6 ];
    
    let s´ = [  8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
                9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
                9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
                15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
                8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11 ];
    
    let K:[UInt32] = [  0x00000000,
                        0x5a827999,
                        0x6ed9eba1,
                        0x8f1bbcdc,
                        0xa953fd4e ];
    
    let K´:[UInt32] = [ 0x50a28be6,
                        0x5c4dd124,
                        0x6d703ef3,
                        0x7a6d76e9,
                        0x00000000 ];
    
    init(data: Data) {
        self.paddedData = pad(data);
    }
    
    func pad(_ data:Data) ->Data {
        var paddedData = NSData(data: data) as Data;
        var paddingData = [UInt8](repeating: 0, count: 72);
        paddingData[0] = 0x80;
        
        let zeros = (64 - ((data.count+9) % 64)) % 64;
        var n = data.count * 8;
        paddedData.append(paddingData, count: zeros+1);
        
        let p = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        memcpy(p, &n,MemoryLayout.size(ofValue: n))
        
        paddedData.append(UnsafeBufferPointer<Int>(start: &n, count: 1));
        return paddedData;
    }
    
    func f(_ j:Int, x:UInt32, y:UInt32, z:UInt32) ->UInt32 {
        if j<=15 {
            return x ^ y ^ z;
        } else if j <= 31 {
            return (x & y) | (~x & z);
        } else if j <= 47 {
            return (x | ~y) ^ z;
        } else if j <= 63 {
            return (x & z) | (y & ~z);
        } else if j <= 79 {
            return x ^ (y | ~z);
        } else {
            assertionFailure("RIPEMD160: wrong index for function f");
        }
        return 0;
    }
    
    func rol(_ x:UInt32, n:Int) -> UInt32 {
        return (x << UInt32(n)) | (x >> UInt32(32 - n));
    }
    
    func hash(_ X:UnsafePointer<UInt32>) {
        var A = h0;
        var B = h1;
        var C = h2;
        var D = h3;
        var E = h4;
        var A´ = h0;
        var B´ = h1;
        var C´ = h2;
        var D´ = h3;
        var E´ = h4;
        var T:UInt32;
        
        for j in 0...79 {
            T = rol(A &+ f(j, x:B, y:C, z:D) &+ X[r[j]] &+ K[j>>4], n: s[j]) &+ E;
            A = E;
            E = D;
            D = rol(C, n: 10);
            C = B;
            B = T;
            T = rol(A´ &+ f(79-j, x:B´, y:C´, z:D´) &+ X[r´[j]] &+ K´[j>>4], n: s´[j]) &+ E´;
            A´ = E´;
            E´ = D´;
            D´ = rol(C´, n: 10);
            C´ = B´;
            B´ = T;
        }
        T = h1 &+ C &+ D´;
        h1 = h2 &+ D &+ E´;
        h2 = h3 &+ E &+ A´;
        h3 = h4 &+ A &+ B´;
        h4 = h0 &+ B &+ C´;
        h0 = T;
    }
    
    func digest() ->Data {
        let blocks = paddedData.count / 64;
        
        paddedData.withUnsafeBytes { (p:UnsafeRawBufferPointer) in
            
            let q = p.bindMemory(to: UInt32.self)
            var x = q.baseAddress!
            for _ in 0 ..< blocks {
                hash(x);
                x = x.advanced(by: 16);
            }
        }
        
        let digest = NSMutableData();
        digest.append(&h0, length: 4);
        digest.append(&h1, length: 4);
        digest.append(&h2, length: 4);
        digest.append(&h3, length: 4);
        digest.append(&h4, length: 4);
        return digest as Data;
    }
    
    
}
