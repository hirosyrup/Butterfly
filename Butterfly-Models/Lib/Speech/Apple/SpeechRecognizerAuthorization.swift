//
//  SpeechRecognizerAuthorization.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation
import Speech

class SpeechRecognizerAuthorization {
    private(set) var authStatus = SFSpeechRecognizerAuthorizationStatus.notDetermined
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                self.authStatus = authStatus
            }
        }
    }
}
