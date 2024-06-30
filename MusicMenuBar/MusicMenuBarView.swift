//
//  MusicMenuBarView.swift
//  MusicMenuBar
//
//  Created by Lumap on 30/06/2024.
//

import SwiftUI

struct MusicMenuBarView: View {
    @ObservedObject var model = MusicMenuBarModel.shared

    var body: some View {
        
        #if DEBUG
        if isPreview {
            Text("The preview is broken, don't trust it")
        }
        #endif

        AsyncImage(url: URL(string: model.albumCover)) {frame in
            frame.image?
                .resizable()
                .scaledToFit()
        }
        .frame(width: 230, height: 230)
        .clipShape(.rect(cornerRadius: 8.0))
        
        Spacer()
            .frame(height: 20)
        
        HStack {
            Button {
                model.previousTrack()
            } label: {
                Label("Back", systemImage: "backward")
            }
            
            if model.isPlaying {
                Button {
                    model.playPause()
                } label: {
                    Label("Pause", systemImage: "pause")
                }
            } else {
                Button {
                    model.playPause()
                } label: {
                    Label("Play", systemImage: "play")
                }
                
            }
            
            
            Button {
                model.nextTrack()
            } label: {
                Label("Next", systemImage: "forward")
            }
        }
        
        Slider(value: Binding(
                get: { self.model.songPosition },
                set: { self.model.songPosition = $0 }
        ), in: 0...model.songDuration) {
            // this slider has no label
        } minimumValueLabel: {
            Text(model.songPosition.toTimestamp)
        } maximumValueLabel: {
            Text(model.songDuration.toTimestamp)
        } onEditingChanged: { isEditing in
            if isEditing == true {
                return
            }
            
            model.setPlayerPosition(pos: self.model.songPosition)
        }
            
        Divider()
            .padding(.vertical, 15)
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

#Preview {
    MusicMenuBarView()
}
