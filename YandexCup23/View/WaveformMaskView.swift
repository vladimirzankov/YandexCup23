//
//  WaveformView.swift
//  YandexCup23
//
//  Created by Владимир Занков on 03.11.2023.
//

import Foundation
import UIKit
import AVFoundation

final class WaveformMaskView: UIImageView {
    var audioURL: URL? {
        didSet {
            guard let url = audioURL else {
                return
            }
            generateWaveImage(from: url, imageSize: self.frame.size, strokeColor: color, backgroundColor: .clear, waveWidth: waveWidth, waveSpacing: waveSpacing) { image in
                self.image = image
            }
        }
    }
    
    var onCalculateDuration: ((Double) -> Void)?
    
    private var color: UIColor
    private var waveWidth: CGFloat = 1
    private var waveSpacing: CGFloat
    
    init(color: UIColor, waveWidth: CGFloat = 2, waveSpacing: CGFloat = 2) {
        self.color = color
        self.waveWidth = waveWidth
        self.waveSpacing = waveSpacing
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func generateWaveImage(from audioUrl: URL,
                           imageSize: CGSize,
                           strokeColor: UIColor,
                           backgroundColor: UIColor,
                           waveWidth: CGFloat,      // Width of each wave
                           waveSpacing: CGFloat,    // Space between waveform items
                           completion: @escaping (_ image: UIImage?) -> Void) {
        readBuffer(audioUrl) { samples in
            guard let samples = samples else {
                completion(nil)
                return
            }
            
            autoreleasepool {
                UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
                guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                    completion(nil)
                    return
                }
                
                let middleY = imageSize.height / 2
                
                context.setFillColor(backgroundColor.cgColor)
                context.setAlpha(1.0)
                context.fill(CGRect(origin: .zero, size: imageSize))
                context.setLineWidth(waveWidth)
                context.setLineJoin(.round)
                context.setLineCap(.round)
                
                let maxAmplitude = samples.max() ?? 0
                let heightNormalizationFactor = Float(imageSize.height) / maxAmplitude / 2
                
                var x: CGFloat = 0.0
                let samplesCount = samples.count
                let sizeWidth = Int(self.frame.size.width)
                var index = 0
                var sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
                while sampleAtIndex != nil {
                    
                    sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
                    let normalizedSample = CGFloat(sampleAtIndex ?? 0) * CGFloat(heightNormalizationFactor)
                    let waveHeight = normalizedSample * middleY

                    context.move(to: CGPoint(x: x, y: middleY - waveHeight))
                    context.addLine(to: CGPoint(x: x, y: middleY + waveHeight))
                    
                    x += waveSpacing + waveWidth
                    
                    index += 1
                }
                    
                context.setStrokeColor(strokeColor.cgColor)
                context.strokePath()
                
                guard let soundWaveImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    UIGraphicsEndImageContext()
                    completion(nil)
                    return
                }
                
                UIGraphicsEndImageContext()
                completion(soundWaveImage)
            }
        }
    }

    private func readBuffer(_ audioUrl: URL,completion:@escaping (_ wave:UnsafeBufferPointer<Float>?)->Void)  {
        DispatchQueue.global(qos: .utility).async {
            guard let file = try? AVAudioFile(forReading: audioUrl) else {
                completion(nil)
                return
            }
            let audioFormat = file.processingFormat
            let audioFrameCount = UInt32(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
            else { return completion(UnsafeBufferPointer<Float>(_empty: ())) }
            
            let sampleRate: Double = audioFormat.sampleRate
            let val = 1 / sampleRate * Double(audioFrameCount)
            
            do {
                try file.read(into: buffer)
                self.onCalculateDuration?(val)
            } catch {
                print(error)
            }
            
            let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            
            DispatchQueue.main.sync {
                completion(floatArray)
            }
        }
    }
}

extension UnsafeBufferPointer {
    func item(at index: Int) -> Element? {
        if index >= self.count {
            return nil
        }
        
        return self[index]
    }
}
