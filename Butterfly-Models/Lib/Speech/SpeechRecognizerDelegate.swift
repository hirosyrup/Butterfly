//
//  SpeechRecognizerDelegate.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation

protocol SpeechRecognizerDelegate: class {
    func didChangeAvailability(recognizer: SpeechRecognizer)
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error)
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String)
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String)
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String)
    func didChangeSpeekingState(recognizer: SpeechRecognizer, isSpeeking: Bool)
}
