//
//  FileManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol CriptextFileDelegate {
    func uploadProgressUpdate(file: File, progress: Int)
    func finishRequest(file: File, success: Bool)
}

class CriptextFileManager {
    let COMPLETE = 100
    let PENDING = -1
    
    var appId = "qynhtyzjrshazxqarkpy"
    var appSecret = "lofjksedbxuucdjjpnby"
    var token : String {
        return "\(appId):\(appSecret)".data(using: .utf8)!.base64EncodedString()
    }
    var chunkSize = 512000
    var registeredFiles = [File]()
    var delegate : CriptextFileDelegate?
    
    internal(set) var keyPairs = [Int: (Data, Data)]()
    var encryption : Bool {
        return keyPairs.count > 0
    }
    
    enum RequestType {
        case upload
        case download
    }
    
    func registerFile(filepath: String, name: String, mimeType: String){
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: filepath)
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        let totalChunks = Int(ceil(Double(fileSize) / Double(chunkSize)))
        let fileRegistry = self.createRegistry(name: name, size: fileSize, mimeType: mimeType)
        fileRegistry.filepath = filepath
        fileRegistry.requestType = .upload
        fileRegistry.chunksProgress = Array(repeating: PENDING, count: totalChunks)
        self.registeredFiles.insert(fileRegistry, at: 0)
        let requestData = [
            "filesize": fileSize,
            "filename": name,
            "totalChunks": totalChunks,
            "chunkSize": chunkSize
            ] as [String : Any]
        APIManager.registerFile(parameters: requestData, token: token) { (requestError, responseData) in
            if let error = requestError {
                print(error)
                return
            }
            let fileResponse = responseData as! Dictionary<String, Any>
            let filetoken = fileResponse["filetoken"] as! String
            fileRegistry.token = filetoken
            self.handleFileTurn()
        }
    }
    
    func registerFile(file: File, uploading: Bool = false){
        guard uploading || !alreadyDownloaded(file: file) else {
            self.delegate?.finishRequest(file: file, success: true)
            return
        }
        if let myFile = registeredFiles.first(where: {$0.token == file.token}) {
            if(myFile.requestStatus == .failed){
                myFile.requestStatus = .pending
                self.handleFileTurn()
            } else if (myFile.requestStatus == . finish) {
                delegate?.finishRequest(file: myFile, success: true)
            }
            return
        }
        guard !uploading else {
            return
        }
        file.requestStatus = .pending
        file.requestType = .download
        registeredFiles.append(file)
        APIManager.getFileMetadata(filetoken: file.token, token: self.token) { (requestError, responseData) in
            guard let metadata = responseData?["file"] as? [String: Any] else {
                file.requestStatus = .failed
                return
            }
            let totalChunks = metadata["chunks"] as! Int
            file.chunksProgress = Array(repeating: self.PENDING, count: totalChunks)
            self.handleFileTurn()
        }
    }
    
    private func alreadyDownloaded(file: File) -> Bool {
        let fileURL = CriptextFileManager.getURLForFile(name: file.name)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
            return fileSize == file.size
        } catch {
            return false
        }
    }
    
    private func createRegistry(name: String, size: Int, mimeType: String) -> File {
        let attachment = File()
        attachment.name = name
        attachment.size = size
        attachment.mimeType = mimeType
        attachment.requestStatus = .pending
        return attachment
    }
    
    private func handleFileTurn(){
        for file in registeredFiles.reversed() {
            if(file.requestStatus == .pending){
                startRequest(file.token)
                break
            }
            if(file.requestStatus == .processing){
                break
            }
        }
    }
    
    private func startRequest(_ filetoken: String){
        guard let fileIndex = registeredFiles.index(where: {$0.token == filetoken}) else {
            handleFileTurn()
            return
        }
        let file = registeredFiles[fileIndex]
        for (index, progress) in file.chunksProgress.enumerated() {
            if(progress == COMPLETE){
                continue
            }
            if(progress != PENDING){
                break
            }
            registeredFiles[fileIndex].requestStatus = .processing
            if(file.requestType == .upload){
                let chunk = getChunkData(file: file, index: index)
                uploadChunk(chunk, file: file, part: index)
            } else {
                downloadChunk(file: file, part: index)
            }
            return
        }
        handleFileTurn()
    }
    
    private func getChunkData(file: File, index: Int) -> Data{
        let fileHandle = FileHandle(forReadingAtPath: file.filepath)!
        fileHandle.seek(toFileOffset: UInt64(index * chunkSize))
        let data = fileHandle.readData(ofLength: chunkSize)
        fileHandle.closeFile()
        guard encryption else {
            return data
        }
        let key = keyPairs[0]!.0
        let iv = keyPairs[0]!.1
        return AESCipher.encrypt(data: data, keyData: key, ivData: iv, operation: kCCEncrypt)!
    }
    
    private func uploadChunk(_ chunk: Data, file: File, part: Int){
        let filetoken = file.token
        let params = [
            "part": part + 1,
            "filetoken": filetoken,
            "filename": file.name,
            "mimeType": file.mimeType
        ] as [String: Any]
        APIManager.uploadChunk(chunk: chunk, params: params, token: self.token, progressDelegate: self) { (requestError) in
            guard let fileIndex = self.registeredFiles.index(where: {$0.token == filetoken}) else {
                self.handleFileTurn()
                return
            }
            guard requestError == nil else {
                self.registeredFiles[fileIndex].requestStatus = .failed
                self.chunkUpdateProgress(Double(self.PENDING)/100.0, for: file.token, part: part + 1)
                self.delegate?.finishRequest(file: file, success: false)
                self.handleFileTurn()
                return
            }
            file.chunksProgress[part] = self.COMPLETE
            self.checkCompleteUpload(filetoken: filetoken)
            self.startRequest(filetoken)
        }
    }
    
    private func downloadChunk(file: File, part: Int){
        let filetoken = file.token
        APIManager.downloadChunk(filetoken: filetoken, part: part + 1, token: self.token, progressDelegate: self) { (requestError, chunkData) in
            guard let fileIndex = self.registeredFiles.index(where: {$0.token == filetoken}) else {
                self.handleFileTurn()
                return
            }
            guard requestError == nil else {
                print(requestError.debugDescription)
                self.registeredFiles[fileIndex].requestStatus = .failed
                self.chunkUpdateProgress(Double(self.PENDING)/100.0, for: file.token, part: part + 1)
                self.delegate?.finishRequest(file: file, success: false)
                self.handleFileTurn()
                return
            }
            file.chunksProgress[part] = self.COMPLETE
            self.checkCompleteUpload(filetoken: filetoken)
            self.startRequest(filetoken)
        }
    }
    
    private func mergeFileChunks(filetoken: String){
        guard let file = registeredFiles.first(where: {$0.token == filetoken}) else {
            return
        }
        let fileURL = CriptextFileManager.getURLForFile(name: file.name)
        try? FileManager.default.removeItem(at: fileURL)
        for part in 1...file.chunksProgress.count {
            let chunk = getChunk(file: file, part: part)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try! FileHandle(forUpdating: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(chunk)
                fileHandle.closeFile()
            } else {
                try! chunk.write(to: fileURL, options: Data.WritingOptions.atomic)
            }
        }
        file.filepath = fileURL.path
    }
    
    private func getChunk(file: File, part: Int) -> Data{
        let chunkURL = CriptextFileManager.getURLForFile(name: "\(file.token).part\(part)")
        let chunkData = try! Data(contentsOf: chunkURL)
        guard encryption,
            let keys = keyPairs[file.emailId] else {
            return chunkData
        }
        let key = keys.0
        let iv = keys.1
        return AESCipher.encrypt(data: chunkData, keyData: key, ivData: iv, operation: kCCDecrypt)!
    }
    
    private func checkCompleteUpload(filetoken: String){
        guard let file = registeredFiles.first(where: {$0.token == filetoken}) else {
            return
        }
        if !file.chunksProgress.contains(where: {$0 != COMPLETE}){
            file.requestStatus = .finish
            if(file.requestType == .download){
                self.mergeFileChunks(filetoken: filetoken)
            }
            self.delegate?.finishRequest(file: file, success: true)
        }
    }
    
    func removeFile(filetoken: String){
        guard let index = registeredFiles.index(where: {$0.token == filetoken}) else {
            return
        }
        registeredFiles.remove(at: index)
    }
    
    func pendingAttachments() -> Bool{
        return registeredFiles.contains(where: {$0.requestStatus != .finish})
    }
    
    func storeFiles() -> [File] {
        DBManager.store(registeredFiles)
        return registeredFiles
    }
    
    func getFilesRequestData() -> [[String: Any]] {
        return registeredFiles.map({ (file) -> [String: Any] in
            return ["token": file.token,
                    "name": file.name,
                    "size": file.size,
                    "mimeType": file.mimeType]
        })
    }
    
    func setEncryption(id: Int, key: Data, iv: Data){
        keyPairs[id] = (key, iv)
    }
    
    static func getURLForFile(name: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(name)
    }
}

extension CriptextFileManager: ProgressDelegate {
    func updateProgress(_ percent: Double, for id: String) {
        
    }
    
    func chunkUpdateProgress(_ percent: Double, for token: String, part: Int) {
        guard let file = registeredFiles.first(where: {$0.token == token}) else {
            return
        }
        file.chunksProgress[part - 1] = Int(percent * 100)
        let totalProgress = file.chunksProgress.reduce(0) { (sum, individualProgress) -> Int in
            guard individualProgress != PENDING else {
                return sum
            }
            return sum + individualProgress
        } / file.chunksProgress.count
        print("Progress: \(totalProgress) - Current Part: \(part)")
        file.progress = totalProgress
        delegate?.uploadProgressUpdate(file: file, progress: totalProgress)
    }
}
