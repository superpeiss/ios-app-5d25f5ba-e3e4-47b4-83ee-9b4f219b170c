import Foundation
import Speech
import NaturalLanguage
import AVFoundation

class LyricsTranscriptionService {
    static let shared = LyricsTranscriptionService()

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Public Methods

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }

    func transcribe(audioURL: URL, completion: @escaping (Result<LyricsData, TranscriptionError>) -> Void) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            completion(.failure(.recognizerNotAvailable))
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.transcriptionFailure(error)))
                }
                return
            }

            guard let result = result else {
                return
            }

            if result.isFinal {
                let transcription = result.bestTranscription
                let fullText = transcription.formattedString

                // Create timed segments
                var timedSegments: [LyricsData.TimedLyric] = []

                for segment in transcription.segments {
                    let timedLyric = LyricsData.TimedLyric(
                        text: segment.substring,
                        startTime: segment.timestamp,
                        duration: segment.duration
                    )
                    timedSegments.append(timedLyric)
                }

                // Extract themes and keywords
                let themes = self?.extractThemes(from: fullText) ?? []
                let keywords = self?.extractKeywords(from: fullText) ?? []

                let lyricsData = LyricsData(
                    fullText: fullText,
                    timedSegments: timedSegments,
                    themes: themes,
                    keywords: keywords
                )

                DispatchQueue.main.async {
                    completion(.success(lyricsData))
                }
            }
        }
    }

    func cancel() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // MARK: - Private Methods

    private func extractThemes(from text: String) -> [String] {
        var themes: [String] = []

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, tag == .noun {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 && !themes.contains(word) {
                    themes.append(word)
                }
            }
            return true
        }

        return Array(themes.prefix(10))
    }

    private func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            if word.count > 2 && !keywords.contains(word) {
                keywords.append(word)
            }
            return true
        }

        // Also add significant verbs and adjectives
        let wordTagger = NLTagger(tagSchemes: [.lexicalClass])
        wordTagger.string = text

        wordTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, (tag == .verb || tag == .adjective) {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 && !keywords.contains(word) {
                    keywords.append(word)
                }
            }
            return true
        }

        return Array(keywords.prefix(20))
    }
}

// MARK: - Error Types

enum TranscriptionError: LocalizedError {
    case recognizerNotAvailable
    case transcriptionFailure(Error)
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available."
        case .transcriptionFailure(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .authorizationDenied:
            return "Speech recognition authorization was denied."
        }
    }
}
