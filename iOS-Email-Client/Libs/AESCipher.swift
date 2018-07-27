//
//  AESCipher.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AESCipher {
    class func encrypt(data: Data, keyData: Data, ivData: Data, operation: Int) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let options = CCOptions(kCCOptionPKCS7Padding)
        
        var numBytesEncrypted : size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes({ dataBytes in
                ivData.withUnsafeBytes({ ivBytes in
                    keyData.withUnsafeBytes({ keyBytes in
                        CCCrypt(CCOperation(operation), CCAlgorithm(kCCAlgorithmAES128), options, keyBytes, keyLength, ivBytes, dataBytes, data.count, cryptBytes, cryptLength, &numBytesEncrypted)
                    })
                })
            })
        }
        
        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
            return nil
        }
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        return cryptData
    }
    
    class func generateKey(password: String, saltData: Data) -> Data? {
        let keySize = 16
        let passwordData = password.data(using: .utf8)!
        var key = Data(count: keySize)
        let status = passwordData.withUnsafeBytes({ (passwordBytes: UnsafePointer<Int8>) in
            saltData.withUnsafeBytes({ (saltBytes: UnsafePointer<UInt8>) in
                key.withUnsafeMutableBytes({ (keyBytes: UnsafeMutablePointer<UInt8>) in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes, passwordData.count, saltBytes, saltData.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 10000, keyBytes, key.count)
                })
            })
        })
        
        guard UInt32(status) == UInt32(kCCSuccess) else {
            return nil
        }
        return key
    }
    
    class func generateRandomBytes(length bytesCount: Int = 16) -> Data {
        var randomBytes = Array<UInt8>(repeating: 0, count: bytesCount)
        SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        return Data(bytes: randomBytes)
    }
}
