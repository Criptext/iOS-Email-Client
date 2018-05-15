//
//  FileManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

struct UploadFile {
    var name: String
    var file: Data
    var chunks: [Data]
    var chunksProgress: [Int]
    var status : CriptextFileManager.uploadStatus
    var filetoken: String
}

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
    var registeredFiles = [UploadFile]()
    var delegate : CriptextFileDelegate?
    
    func registerFile(file fileData: Data, name: String, completion: @escaping ((Error?, String?) -> Void)){
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
        let requestData = [
            "filesize": fileData.count,
            "filename": name,
            "totalChunks": totalChunks + 1,
            "chunkSize": chunkSize
            ] as [String : Any]
        APIManager.registerFile(parameters: requestData, token: token) { (requestError, responseData) in
            if let error = requestError {
                completion(error, nil)
                print(error)
                return
            }
            let fileResponse = responseData as! Dictionary<String, Any>
            let filetoken = fileResponse["filetoken"] as! String
            let fileRegistry = UploadFile.init(name: name, file: fileData, chunks: chunks, chunksProgress: chunksProgress, status: .pending, filetoken: filetoken)
            self.registeredFiles.append(fileRegistry)
            self.handleFileTurn()
            completion(nil, filetoken)
        }
    }
    
    private func handleFileTurn(){
        for file in registeredFiles {
            if(file.status == .pending){
                startUpload(file.filetoken)
                break
            }
            if(file.status == .uploading){
                break
            }
        }
    }
    
    private func startUpload(_ filetoken: String){
        guard let fileIndex = registeredFiles.index(where: {$0.filetoken == filetoken}) else {
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
            registeredFiles[fileIndex].status = .uploading
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
            if let error = requestError {
                print(error.localizedDescription)
                return
            }
            guard self.registeredFiles.contains(where: {$0.filetoken == filetoken}) else {
                self.handleFileTurn()
                return
            }
            self.checkCompleteUpload(filetoken: filetoken)
            self.startUpload(filetoken)
        }
    }
    
    private func checkCompleteUpload(filetoken: String){
        guard let fileIndex = registeredFiles.index(where: {$0.filetoken == filetoken}) else {
            return
        }
        if !registeredFiles[fileIndex].chunksProgress.contains(where: {$0 != COMPLETE}){
            registeredFiles[fileIndex].status = .finish
            print("FINISH UPLOAD \(filetoken)")
        }
    }
    
    func removeFile(filetoken: String){
        guard let index = registeredFiles.index(where: {$0.filetoken == filetoken}) else {
            return
        }
        registeredFiles.remove(at: index)
    }
    
    enum uploadStatus {
        case pending
        case uploading
        case finish
    }
}

extension CriptextFileManager: ProgressDelegate {
    func updateProgress(_ percent: Double, for id: String) {
        
    }
    
    func chunkUpdateProgress(_ percent: Double, for token: String, part: Int) {
        guard let fileIndex = registeredFiles.index(where: {$0.filetoken == token}) else {
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
