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
    
    enum RequestType {
        case upload
        case download
    }
    
    func registerFile(file fileData: Data, name: String, mimeType: String){
        let totalChunks = Int(floor(Double(fileData.count) / Double(chunkSize)))
        var chunks = [Data]()
        var chunksProgress = [Int]()
        for chunkNumber in 0...totalChunks {
            let rangeStart = chunkNumber * chunkSize
            let rangeEnd = chunkNumber == totalChunks ? fileData.count : (chunkNumber + 1) * chunkSize
            let range = Range<Data.Index>(rangeStart..<rangeEnd)
            chunks.append(fileData.subdata(in: range))
            chunksProgress.append(PENDING)
        }
        let fileRegistry = self.createRegistry(name: name, size: fileData.count, mimeType: mimeType)
        fileRegistry.requestType = .upload
        fileRegistry.chunks = chunks
        fileRegistry.chunksProgress = chunksProgress
        self.registeredFiles.insert(fileRegistry, at: 0)
        let requestData = [
            "filesize": fileData.count,
            "filename": name,
            "totalChunks": totalChunks + 1,
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
    
    func registerFile(file: File){
        if let myFile = registeredFiles.first(where: {$0.token == file.token}) {
            if(myFile.requestStatus == .failed){
                myFile.requestStatus = .pending
                self.handleFileTurn()
            } else if (myFile.requestStatus == . finish) {
                delegate?.finishRequest(file: myFile, success: true)
            }
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
            var chunksProgress = [Int]()
            for _ in 1...totalChunks {
                chunksProgress.append(self.PENDING)
            }
            file.chunks = [Data]()
            file.chunksProgress = chunksProgress
            self.handleFileTurn()
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
                let chunk = file.chunks[index]
                uploadChunk(chunk, file: file, part: index)
            } else {
                downloadChunk(file: file, part: index)
            }
            return
        }
        handleFileTurn()
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
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file.name)
        for part in 1...file.chunksProgress.count {
            let capacity = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
            let chunkURL = documentsURL.appendingPathComponent("\(filetoken).part\(part)")
            let chunkStream = InputStream(fileAtPath: chunkURL.path)!
            chunkStream.open()
            while (chunkStream.hasBytesAvailable) {
                chunkStream.read(buffer, maxLength: capacity)
                let fileStream = OutputStream(toFileAtPath: fileURL.path, append: true)!
                fileStream.open()
                fileStream.write(buffer, maxLength: capacity)
                fileStream.close()
            }
            chunkStream.close()
        }
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
