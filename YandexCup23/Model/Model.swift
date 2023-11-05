//
//  Model.swift
//  YandexCup23
//
//  Created by Занков Владимир Владимирович on 02.11.2023.
//

import Foundation
import UIKit
import AVFoundation

class Sound {
    var category: Category
    var name: String
    var fileURL: URL {
        if category == .mic {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return documentsDirectory.appendingPathComponent("\(name).wav")
        } else {
            return Bundle.main.url(forResource: name, withExtension: "wav")!
        }
    }
    var isMuted: Bool = false
    var isPlaying: Bool = false
    var volume: Float = 0.5
    var speed: Float = 1.0
    var player: AVAudioPlayerNode? = nil
    
    init(category: Category, name: String) {
        self.category = category
        self.name = name
    }
}

enum Category: String {
    case guitar = "Гитара"
    case drums = "Ударные"
    case brass = "Духовые"
    case mic = "Микрофон"
}

class Model {
    
    let dict: [Category: [String]] = [
        .guitar: [
            "Гитара 1",
            "Гитара 2"
        ],
        .drums: [
            "Ударные 1",
            "Ударные 2"
            
        ],
        .brass: [
            "Духовые 1",
            "Духовые 2",
            "Духовые 3"
        ]
    ]
}

let model = Model()
