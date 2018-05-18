//
//  FileManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol CriptextFileDelegate {
    func uploadProgressUpdate(filetoken: String, progress: Int)
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
    
    private func createRegistry(name: String, size: Int, mimeType: String) -> File {
        let attachment = File()
        attachment.name = name
        attachment.size = size
        attachment.mimeType = mimeType
        
        return attachment
    }
    
    private func handleFileTurn(){
        for file in registeredFiles.reversed() {
            if(file.requestStatus == .pending){
                startUpload(file.token)
                break
            }
            if(file.requestStatus == .uploading){
                break
            }
        }
    }
    
    private func startUpload(_ filetoken: String){
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
            let chunk = file.chunks[index]
            registeredFiles[fileIndex].requestStatus = .uploading
            uploadChunk(chunk, filetoken: filetoken, part: index)
            return
        }
        handleFileTurn()
    }
    
    private func uploadChunk(_ chunk: Data, filetoken: String, part: Int){
        let params = [
            "part": part,
            "filetoken": filetoken
        ] as [String: Any]
        APIManager.uploadChunk(chunk: chunk, params: params, token: self.token, progressDelegate: self) { (requestError, response) in
            guard let fileIndex = self.registeredFiles.index(where: {$0.token == filetoken}) else {
                self.handleFileTurn()
                return
            }
            if let error = requestError {
                print(error.localizedDescription)
                self.registeredFiles[fileIndex].requestStatus = .failed
                self.handleFileTurn()
                return
            }
            self.checkCompleteUpload(filetoken: filetoken)
            self.startUpload(filetoken)
        }
    }
    
    private func checkCompleteUpload(filetoken: String){
        guard let fileIndex = registeredFiles.index(where: {$0.token == filetoken}) else {
            return
        }
        if !registeredFiles[fileIndex].chunksProgress.contains(where: {$0 != COMPLETE}){
            registeredFiles[fileIndex].requestStatus = .finish
        }
    }
    
    func removeFile(filetoken: String){
        guard let index = registeredFiles.index(where: {$0.token == filetoken}) else {
            return
        }
        registeredFiles.remove(at: index)
    }
}

extension CriptextFileManager: ProgressDelegate {
    func updateProgress(_ percent: Double, for id: String) {
        
    }
    
    func chunkUpdateProgress(_ percent: Double, for token: String, part: Int) {
        guard let fileIndex = registeredFiles.index(where: {$0.token == token}) else {
            return
        }
        registeredFiles[fileIndex].chunksProgress[part] = Int(percent * 100)
        let totalProgress = registeredFiles[fileIndex].chunksProgress.reduce(0) { (sum, individualProgress) -> Int in
            guard individualProgress != PENDING else {
                return sum
            }
            return sum + individualProgress
        } / registeredFiles[fileIndex].chunksProgress.count
        delegate?.uploadProgressUpdate(filetoken: token, progress: totalProgress)
    }
}
