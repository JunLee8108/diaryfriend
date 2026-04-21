//
//  SpeechRecognitionService.swift
//  DiaryFriend
//
//  음성 → 텍스트 변환 서비스. SFSpeechRecognizer 래핑.
//

import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognitionService: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var transcribedText: String = ""
    @Published private(set) var errorMessage: String?

    // MARK: - Private
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var silenceTimer: Timer?
    private var hardLimitTimer: Timer?

    /// 2초 무음 감지 후 자동 정지
    private let silenceTimeout: TimeInterval = 2.0
    /// 60초 하드 리밋
    private let hardLimit: TimeInterval = 60.0

    // MARK: - Authorization

    /// 음성 인식 + 마이크 권한 요청. 둘 다 승인돼야 true.
    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { return false }

        let micGranted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return micGranted
    }

    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized &&
            AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Recording

    func startRecording(locale: Locale) throws {
        // 이미 녹음 중이면 중복 방지
        guard !isRecording else { return }

        // 이전 태스크 정리
        cleanup()

        // Recognizer 준비
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        self.recognizer = recognizer

        // Audio session — 음악 재생 중이어도 섞이도록
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // Request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.recognitionRequest = request

        // Audio engine tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        transcribedText = ""
        errorMessage = nil
        isRecording = true

        // 인식 태스크
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                    self.resetSilenceTimer()

                    if result.isFinal {
                        self.stopRecording()
                    }
                }

                if error != nil {
                    // 무음으로 태스크가 종료되면 .error 로 들어오는 경우도 있음 — 조용히 정지
                    self.stopRecording()
                }
            }
        }

        scheduleHardLimit()
        resetSilenceTimer()
    }

    func stopRecording() {
        guard isRecording else { return }
        cleanup()
        isRecording = false
    }

    // MARK: - Cleanup

    private func cleanup() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        hardLimitTimer?.invalidate()
        hardLimitTimer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Timers

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
    }

    private func scheduleHardLimit() {
        hardLimitTimer?.invalidate()
        hardLimitTimer = Timer.scheduledTimer(withTimeInterval: hardLimit, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
    }

    deinit {
        silenceTimer?.invalidate()
        hardLimitTimer?.invalidate()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
    }
}

// MARK: - Error

enum SpeechError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available for this language."
        }
    }
}
