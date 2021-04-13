//
//  RecognitionRequestAmiVoice.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation
import Starscream
import AVFoundation
import SwiftyBeaver

protocol RecognitionRequestAmiVoiceDelegate: class {
    func failedToRequest(request: RecognitionRequestAmiVoice, error: Error)
    func didUpdateStatement(request: RecognitionRequestAmiVoice, statement: String)
    func didEndStatement(request: RecognitionRequestAmiVoice, statement: String)
}

class RecognitionRequestAmiVoice: WebSocketDelegate {
    enum State {
        case idle
        case connected
        case processing
        case ending
        case didEnd
        case disconnected
        case cancel
        case error
    }
    
    let id: String
    let apiKey: String
    weak var delegate: RecognitionRequestAmiVoiceDelegate?
    private var statements = [String]()
    private var state = State.idle
    private var endTimer: Timer?
    private let updateInterval = TimeInterval(1)
    private var previousNotifyUpdateDate = Date()
    private let endingInterval = TimeInterval(1)
    private let socket: WebSocket
    private var bufferList = [AVAudioPCMBuffer]()
    private let requestBufferCount = 5
    private let downFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 16000.0, channels: 1, interleaved: true)!
    private let errorHeader = "AmiVoiceError: "
    
    init(id: String, apiKey: String) {
        self.id = id
        self.apiKey = apiKey
        var request = URLRequest(url: URL(string: "wss://acp-api.amivoice.com/v1/")!)
        request.timeoutInterval = 30
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    private func startRequest() {
        guard state == .connected else { return}
        socket.write(string: "s lsb16k -a-general authorization=\(apiKey)")
    }
    
    private func endRequest() {
        guard state == .ending else { return}
        socket.write(string: "e")
    }
    
    private func request(buffer: AVAudioPCMBuffer) throws {
        guard let converter = AVAudioConverter(from: buffer.format, to: downFormat) else {
            throw NSError(domain: "\(errorHeader)Failed to create an audio converter.", code: -1, userInfo: nil)
        }
        
        guard let newbuffer = AVAudioPCMBuffer(pcmFormat: downFormat,
                                               frameCapacity: AVAudioFrameCount(Float(buffer.frameCapacity) * Float(downFormat.sampleRate / buffer.format.sampleRate))) else {
            throw NSError(domain: "\(errorHeader)Failed to create an pcm buffer.", code: -1, userInfo: nil)
        }
        let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            let audioBuffer : AVAudioBuffer = buffer
            return audioBuffer
        }
        var error : NSError?
        converter.convert(to: newbuffer, error: &error, withInputFrom: inputBlock)
        if let _error = error {
            throw _error
        }
        bufferList.append(newbuffer)
        guard state == .processing else { return}
        if bufferList.count >= requestBufferCount {
            sendData()
        }
    }
    
    private func sendData() {
        socket.write(data: createRequestData())
        bufferList.removeAll()
    }
    
    private func createRequestData() -> Data {
        var data = "p".data(using: .utf8)!
        bufferList.forEach { (buffer) in
            if let channelData = buffer.int16ChannelData?[0] {
                let appendData = Data(buffer: UnsafeBufferPointer(start:channelData, count: Int(buffer.frameLength)))
                data = data + appendData
            }
        }
        return data
    }
    
    private func end(forced: Bool = false) {
        if forced || state == .ending {
            state = .didEnd
            socket.disconnect()
            delegate?.didEndStatement(request: self, statement: joinedStatement())
        }
    }
    
    private func notifyUpdate() {
        if Date().timeIntervalSince1970 - previousNotifyUpdateDate.timeIntervalSince1970 > updateInterval {
            delegate?.didUpdateStatement(request: self, statement: joinedStatement())
            previousNotifyUpdateDate = Date()
        }
    }
    
    private func parseRecievedText(text: String) throws -> Bool {
        let firstChar = text.first
        if firstChar == "s" {
            if text.count > 1 {
                throw NSError(domain: "\(errorHeader)\(text)", code: -1, userInfo: nil)
            } else {
                state = .processing
            }
        } else if firstChar == "p" && text.count > 1 {
            throw NSError(domain: "\(errorHeader)\(text)", code: -1, userInfo: nil)
        } else if firstChar == "e" {
            if text.count > 1 {
                throw NSError(domain: "\(errorHeader)\(text)", code: -1, userInfo: nil)
            } else {
                end()
            }
        } else if firstChar == "C" {
            statements.append("")
        } else if firstChar == "A" {
            if let json = try JSONSerialization.jsonObject(with: removeCommandString(text: text).data(using: .utf8)!) as? [String: Any] {
                if let message = json["message"] as? String, !message.isEmpty {
                    SwiftyBeaver.self.error("\(errorHeader)\(message)")
                    return false
                } else {
                    statements[statements.count - 1] = (json["text"] as? String) ?? ""
                    return true
                }
            }
        } else if firstChar == "U" {
            if let json = try JSONSerialization.jsonObject(with: removeCommandString(text: text).data(using: .utf8)!) as? [String: Any] {
                statements[statements.count - 1] = (json["text"] as? String) ?? ""
                return true
            }
        }
        return false
    }
    
    private func removeCommandString(text: String) -> String {
        return String(text[text.index(text.startIndex, offsetBy: 2)...])
    }
    
    private func joinedStatement() -> String {
        return statements.joined(separator: "\n")
    }
    
    func append(buffer: AVAudioPCMBuffer) {
        if state != .didEnd {
            do {
                try request(buffer: buffer)
            } catch {
                SwiftyBeaver.self.error(error)
            }
        }
    }
    
    func endAudio() {
        state = .ending
        endRequest()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        do {
            switch event {
                case .connected(_):
                    state = .connected
                    startRequest()
                case .disconnected(_, _):
                    state = .disconnected
                    end(forced: true)
                case .text(let text):
                    if try parseRecievedText(text: text) {
                        notifyUpdate()
                    }
                case .binary(_):
                    break
                case .ping(_):
                    break
                case .pong(_):
                    break
                case .viabilityChanged(_):
                    break
                case .reconnectSuggested(_):
                    break
                case .cancelled:
                    state = .cancel
                case .error(let error):
                    state = .error
                    if let _error = error {
                        throw _error
                    }
                }
        } catch {
            socket.disconnect()
            delegate?.failedToRequest(request: self, error: error)
        }
    }
}
