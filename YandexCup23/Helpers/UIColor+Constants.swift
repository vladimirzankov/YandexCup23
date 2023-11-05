//
//  UIColor+Constants.swift
//  YandexCup23
//
//  Created by Владимир Занков on 31.10.2023.
//

import UIKit

extension UIColor {
    
    class var customFuchsia: UIColor { .init(hex: "#A8DB10") }
    
    class var customGray: UIColor { .init(hex: "#323232") }
    
    class var customRed: UIColor { .init(hex: "#FF0849") }
    
    class var customIndigo: UIColor { .init(hex: "#5A50E2") }
}

extension UIColor {
    
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexValue = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexValue.hasPrefix("#") {
            hexValue.remove(at: hexValue.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
