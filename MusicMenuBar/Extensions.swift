//
//  Extensions.swift
//  MusicMenuBar
//
//  Created by Lumap on 30/06/2024.
//

import Foundation

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

extension Float {
    var toTimestamp: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
