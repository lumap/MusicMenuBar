//
//  MusicMenuBarApp.swift
//  MusicMenuBar
//
//  Created by Lumap on 30/06/2024.
//

import SwiftUI

@main
struct MusicMenuBarApp: App {
    @ObservedObject var model = MusicMenuBarModel.shared
    
    var body: some Scene {
        MenuBarExtra {
            MusicMenuBarView()
                .padding(.all, 25)
                .frame(minWidth: 350, idealHeight: 260)
        } label: {
            Text(model.menuBarTitle)
                .onAppear {
                    model.startTimer()
                }
                .onDisappear {
                    model.stopTimer()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
