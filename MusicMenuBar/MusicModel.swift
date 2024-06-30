//
//  MusicModel.swift
//  MusicMenuBar
//
//  Created by Lumap on 30/06/2024.
//

import Foundation

class MusicModel: ObservableObject {
    static let shared = MusicModel()
    var currentStatus: String = "Nothing is playing..."
        
    private 
    
    private init() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            getCurrentStatus()
        }
    }
}
