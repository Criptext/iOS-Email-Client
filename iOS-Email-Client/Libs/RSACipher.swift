//
//  RSACipher.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/14/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class RSACipher {
    class func encrypt(data: Data, keyData: Data, ivData: Data, operation: Int) -> Data {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let options = CCOptions(kCCOptionPKCS7Padding)
        
        var numBytesEncrypted : size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes({ dataBytes in
                ivData.withUnsafeBytes({ ivBytes in
                    keyData.withUnsafeBytes({ keyBytes in
                        CCCrypt(CCOperation(operation), CCAlgorithm(kCCAlgorithmAES), options, keyBytes, keyLength, ivBytes, dataBytes, data.count, cryptBytes, cryptLength, &numBytesEncrypted)
                    })
                })
            })
        }
        
        if(UInt32(cryptStatus) == UInt32(kCCSuccess)){
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        }else{
            print("error: \(cryptStatus)")
        }
        
        return cryptData
    }
}
