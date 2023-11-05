//
//  MicMonitor.swift
//  YandexCup23
//
//  Created by Владимир Занков on 01.11.2023.
//

import Foundation
import AVFoundation

final class MicMonitor: NSObject {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelsHandler: ((Float) -> Void)?
    
    override init() {
        //    let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent("Микрофон.wav")
        let settings: [String: Any] = [
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
            AVLinearPCMIsNonInterleaved: false,
        ]
        
        let audioSession = AVAudioSession.sharedInstance()
        
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission {success in
                print("microphone permission: \(success)")
            }
        }
        
        do {
            try recorder = AVAudioRecorder(url: url, settings: settings)
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [])
        } catch {
            print("Couldn't initialize the mic input")
        }
        
        if let recorder = recorder {
            // start observing mic levels
            recorder.prepareToRecord()
            recorder.isMeteringEnabled = true
        }
    }
    
    func startMonitoringWithHandler(_ handler: ((Float) -> Void)?) {
        levelsHandler = handler
        
        // start meters
        timer = Timer.scheduledTimer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(MicMonitor.handleMicLevel(_:)),
            userInfo: nil,
            repeats: true)
        recorder?.record()
    }
    
    func stopMonitoring() {
        levelsHandler = nil
        timer?.invalidate()
        recorder?.stop()
    }
    
    @objc func handleMicLevel(_ timer: Timer) {
        recorder?.updateMeters()
        levelsHandler?(recorder?.averagePower(forChannel: 0) ?? 0)
    }
    
    deinit {
        stopMonitoring()
    }
}
