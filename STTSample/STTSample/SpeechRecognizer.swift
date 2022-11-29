//
/******************************************************************************
 * Copyright (c) 2022 KineMaster Corp. All rights reserved.
 * https://www.kinemastercorp.com/
 *
 * THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
 * PURPOSE.
 ******************************************************************************/

import AVFoundation
import Foundation
import Speech
import SwiftUI

final class SpeechRecognizer: ObservableObject {
    enum Error: Swift.Error {
        case notAuthorized
        case recognizerUnavailable
        
        var message: String {
            switch self {
            case .notAuthorized: return "Not authorized to recognize speech"
            case .recognizerUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    @Published var transcript: String = ""
    @Published var report: Report = .empty
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var startTime: Date?
    private var endTime: Date?
    
    deinit {
        reset()
    }
    
    func transcribeFile(url: URL, locale: Locale) async throws {
        guard await SFSpeechRecognizer.hasAuthorization() else {
            throw Error.recognizerUnavailable
        }
        
        reset()
        
        recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw Error.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        startTime = .init()
        DispatchQueue.global().async {
            self.task = recognizer.recognitionTask(with: request, resultHandler: self.recognitionHandler(result:error:))
        }
    }

    private func recognitionHandler(result: SFSpeechRecognitionResult?, error: Swift.Error?) {
        guard let result = result else { return }
        endTime = .init()
        DispatchQueue.main.async {
            self.transcript = result.bestTranscription.formattedString
            self.report = .init(
                responseTime: self.endTime!.timeIntervalSince(self.startTime!),
                transcript: result.bestTranscription.formattedString,
                sentences: result.bestTranscription.segments.map {
                    .init(text: $0.substring, startTime: $0.timestamp, endTime: $0.timestamp + $0.duration)
                }
            )
            print(self.report)
        }
    }
    
    func reset() {
        task?.cancel()
        request = nil
        task = nil
        startTime = nil
        endTime = nil
    }
    
    struct Report {
        let responseTime: TimeInterval
        var transcript: String
        var sentences: [Sentence]
        
        struct Sentence: Identifiable {
            let id: String = UUID().uuidString
            let text: String
            let startTime: TimeInterval
            let endTime: TimeInterval
        }
    }
}

extension SpeechRecognizer.Report {
    static var empty = Self(
        responseTime: 0.0,
        transcript: "",
        sentences: []
    )
}

extension SFSpeechRecognizer {
    static func hasAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
