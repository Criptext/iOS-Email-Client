//
//  FileManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol CriptextFileDelegate: class {
    func uploadProgressUpdate(file: File, progress: Int)
    func finishRequest(file: File, success: Bool)
    func fileError(message: String)
}

class CriptextFileManager {
    let COMPLETE = 100
    let PENDING = -1
    let MAX_SIZE = 25000000
    
    weak var myAccount : Account!
    var chunkSize = 512000
    var registeredFiles = [File]()
    var apiManager: APIManager.Type = APIManager.self
    weak var delegate: CriptextFileDelegate?
    
    var keyPairs = [Int: (Data, Data)]()
    var encryption : Bool {
        return keyPairs.count > 0
    }

    func availableSize(addedSize: Int) -> Bool {
        let overallSize = registeredFiles.reduce(0) { (sum, file) -> Int in
            return sum + file.size
        }
        return overallSize + addedSize <= MAX_SIZE
    }
    
    @discardableResult func registerFile(filepath: String, name: String, mimeType: String) -> Bool {
        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filepath) else {
            return false
        }
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        guard self.availableSize(addedSize: fileSize),
            fileSize != 0 else {
            self.delegate?.fileError(message: String.localize("EXCEEDS_MAX_SIZE", arguments: File.prettyPrintSize(size: MAX_SIZE)))
            return false
        }
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
        apiManager.registerFile(token: myAccount.jwt, parameters: requestData) { [weak self] (responseData) in
            guard let weakSelf = self else {
                fileRegistry.requestStatus = .failed
                return
            }
            if case let .EntityTooLarge(maxSize) = responseData {
                let mSize = File.prettyPrintSize(size: Int(maxSize))
                weakSelf.removeFile(path: filepath)
                weakSelf.delegate?.fileError(message: String.localize("THE_FILE_EXCEEDS", arguments: name, mSize))
                weakSelf.handleFileTurn()
                return
            }
            guard case let .SuccessDictionary(fileResponse) = responseData else {
                fileRegistry.requestStatus = .failed
                weakSelf.handleFileTurn()
                return
            }
            let filetoken = fileResponse["filetoken"] as! String
            fileRegistry.token = filetoken
            weakSelf.handleFileTurn()
        }
        return true
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
        file.requestType = .download
        registeredFiles.append(file)
        apiManager.getFileMetadata(filetoken: file.token, token: myAccount.jwt) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            guard case let .SuccessDictionary(responseFile) = responseData,
            let metadata = responseFile["file"] as? [String: Any] else {
                file.requestStatus = .failed
                weakSelf.delegate?.uploadProgressUpdate(file: file, progress: 0)
                weakSelf.delegate?.finishRequest(file: file, success: false)
                if let index = weakSelf.registeredFiles.firstIndex(where: {$0.token == file.token}) {
                    weakSelf.registeredFiles.remove(at: index)
                    weakSelf.delegate?.fileError(message: String.localize("UNABLE_FILE"))
                }
                return
            }
            let totalChunks = metadata["chunks"] as! Int
            file.requestStatus = .pending
            file.chunksProgress = Array(repeating: weakSelf.PENDING, count: totalChunks)
            weakSelf.handleFileTurn()
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
        attachment.fileKey = File.getKeyCodedString(key:  keyPairs[0]!.0, iv:  keyPairs[0]!.1)
        return attachment
    }
    
    func handleFileTurn(){
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
        guard let fileIndex = registeredFiles.firstIndex(where: {$0.token == filetoken}) else {
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
    
    private func getChunkData(file: File, index: Int) -> Data {
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
        apiManager.uploadChunk(chunk: chunk, params: params, token: myAccount.jwt, progressDelegate: self) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            guard let fileIndex = weakSelf.registeredFiles.firstIndex(where: {$0.token == filetoken}) else {
                weakSelf.handleFileTurn()
                return
            }
            guard case .Success = responseData else {
                weakSelf.registeredFiles[fileIndex].requestStatus = .failed
                weakSelf.chunkUpdateProgress(Double(weakSelf.PENDING)/100.0, for: file.token, part: part + 1)
                weakSelf.delegate?.finishRequest(file: file, success: false)
                weakSelf.handleFileTurn()
                return
            }
            file.chunksProgress[part] = weakSelf.COMPLETE
            weakSelf.checkCompleteUpload(filetoken: filetoken)
            weakSelf.startRequest(filetoken)
        }
    }
    
    private func downloadChunk(file: File, part: Int){
        let filetoken = file.token
        apiManager.downloadChunk(filetoken: filetoken, part: part + 1, token: myAccount.jwt, progressDelegate: self) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            guard let fileIndex = weakSelf.registeredFiles.firstIndex(where: {$0.token == filetoken}) else {
                weakSelf.handleFileTurn()
                return
            }
            guard case .SuccessString = responseData else {
                weakSelf.registeredFiles[fileIndex].requestStatus = .failed
                weakSelf.chunkUpdateProgress(Double(weakSelf.PENDING)/100.0, for: file.token, part: part + 1)
                weakSelf.delegate?.finishRequest(file: file, success: false)
                weakSelf.handleFileTurn()
                return
            }
            file.chunksProgress[part] = weakSelf.COMPLETE
            weakSelf.checkCompleteUpload(filetoken: filetoken)
            weakSelf.startRequest(filetoken)
        }
    }
    
    private func mergeFileChunks(filetoken: String) -> Bool {
        guard let file = registeredFiles.first(where: {$0.token == filetoken}) else {
            return false
        }
        let fileURL = CriptextFileManager.getURLForFile(name: file.name)
        try? FileManager.default.removeItem(at: fileURL)
        for part in 1...file.chunksProgress.count {
            guard let chunk = getChunk(file: file, part: part) else {
                return false
            }
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
        return true
    }
    
    private func getChunk(file: File, part: Int) -> Data? {
        let chunkURL = CriptextFileManager.getURLForFile(name: "\(file.token).part\(part)")
        guard let chunkData = try? Data(contentsOf: chunkURL) else {
            return nil
        }
        guard encryption,
            let keys = keyPairs[file.emailId] else {
            return chunkData
        }
        let key = keys.0
        let iv = keys.1
        guard let decryptedChunk = AESCipher.encrypt(data: chunkData, keyData: key, ivData: iv, operation: kCCDecrypt) else {
            return chunkData
        }
        return decryptedChunk
    }
    
    private func checkCompleteUpload(filetoken: String){
        guard let file = registeredFiles.first(where: {$0.token == filetoken}),
            !file.chunksProgress.contains(where: {$0 != COMPLETE}) else {
            return
        }
        file.requestStatus = .finish
        guard (file.requestType == .download) else {
            self.delegate?.finishRequest(file: file, success: true)
            return
        }
        let result = self.mergeFileChunks(filetoken: filetoken)
        if result {
            self.delegate?.finishRequest(file: file, success: true)
        } else {
            self.delegate?.fileError(message: String.localize("FILE_NOT_FOUND", arguments: file.name))
        }
    }
    
    func removeFile(filetoken: String){
        guard let index = registeredFiles.firstIndex(where: {$0.token == filetoken}) else {
            return
        }
        registeredFiles.remove(at: index)
    }
    
    func removeFile(path: String){
        guard let index = registeredFiles.firstIndex(where: {$0.filepath == path}) else {
            return
        }
        registeredFiles.remove(at: index)
    }
    
    func pendingAttachments() -> Bool{
        return registeredFiles.contains(where: {$0.requestStatus != .finish})
    }
    
    func getFilesRequestData() -> [[String: Any]] {
        return registeredFiles.map({ (file) -> [String: Any] in
            return ["token": file.token,
                    "name": file.name,
                    "size": file.size,
                    "mimeType": file.mimeType,
                    "fileKey": file.fileKey]
        })
    }
    
    func setEncryption(id: Int, key: Data, iv: Data){
        keyPairs[id] = (key, iv)
    }
    
    static func getURLForFile(name: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(name)
    }
    
    static func deleteFile(path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
    
    static func deleteFile(url: URL) {
        try? FileManager.default.removeItem(at: url)
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
        file.progress = totalProgress
        delegate?.uploadProgressUpdate(file: file, progress: totalProgress)
    }
}
