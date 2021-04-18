//
//  SpeechRecognizer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation
import AVFoundation

protocol SpeechRecognizer {
    func setRmsThreshold(threshold: Float)
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime)
    func setDelegate(delegate: SpeechRecognizerDelegate?)
}
