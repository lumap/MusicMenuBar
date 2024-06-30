//
//  MusicMenuBarModel.swift
//  MusicMenuBar
//
//  Created by Lumap on 30/06/2024.
//

import Foundation
import Combine // needed for AnyCancellable type
import SwiftUI // needed for NSWorkspace

class MusicMenuBarModel: ObservableObject {
    
    
    // MARK: - Variables
    
    static let shared = MusicMenuBarModel()
    
    @Published var menuBarTitle = "Hello!"
    @Published var isPlaying = false
    @Published var albumCover = ""
    @Published var songPosition: Float = 0.0
    @Published var songDuration: Float = 0.0
    
    private var timer: AnyCancellable?
    private var songName = ""
    private var songArtist = ""
    private var songAlbum = ""
    
    private init() { }
    
    
    // MARK: - Public functions

    func startTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchUpdate()
            }
    }
    
    func stopTimer() {
        timer?.cancel()
    }
    
    func playPause() {
        let source = """
            tell app "Music"
                playpause
            end tell
        """
        
        execAppleScript(with: source) { _ in

        }
        
        self.isPlaying = !self.isPlaying
    }
    
    func previousTrack() {
        let source = """
            tell app "Music"
                back track
            end tell
        """
        
        execAppleScript(with: source) { _ in
            
        }
    }
    
    func nextTrack() {
        let source = """
            tell app "Music"
                next track
            end tell
        """
        
        execAppleScript(with: source) { _ in
            
        }
    }
    
    func setPlayerPosition(pos: Float) {
        let source = """
            tell app "Music"
                set player position to \(pos)
            end tell
        """
        
        execAppleScript(with: source) { _ in
            
        }
    }
    
    
    // MARK: - Private functions - Utils
    
    private func isMusicAppRunning() -> Bool {
        let musicAppBundleID = "com.apple.Music"
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == musicAppBundleID {
                return true
            }
        }
        return false
    }
    
    private func updateMenuBarTitle(title: String) {
        DispatchQueue.main.async {
            self.menuBarTitle = title
        }
    }
    
    private func execAppleScript(with source: String, completion: @escaping (_ output: String) -> Void) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                DispatchQueue.main.async {
                    completion(output)
                }
            }
        }
    }
    
    private func fetchAlbumArtwork(query: String) {
        let appleMusicSearchURLString = "https://tools.applemediaservices.com/api/apple-media/music/US/search.json?types=songs&limit=1&term=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let appleMusicSearchURL = URL(string: appleMusicSearchURLString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: appleMusicSearchURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let parsedResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let songs = parsedResult["songs"] as? [String: Any],
                   let dataArray = songs["data"] as? [[String: Any]] {
                    
                    if let firstSong = dataArray.first,
                       let attributes = firstSong["attributes"] as? [String: Any],
                       let artwork = attributes["artwork"] as? [String: Any],
                       let artworkUrl = artwork["url"] as? String {
                        
                        let artworkUrlWithSize = artworkUrl.replacingOccurrences(of: "{w}", with: "512").replacingOccurrences(of: "{h}", with: "512")
                        
                        DispatchQueue.main.async {
                            self.albumCover = artworkUrlWithSize
                        }
                    } else {
                        print("Failed to find artwork URL in JSON")
                    }
                } else {
                    print("Failed to find data array in JSON")
                }
            } catch let parseError {
                print("JSON Parsing Error: \(parseError)")
            }
        }
        
        task.resume()
    }

    
    // MARK: - Functions - Fetch Update
    
    
    private func fetchUpdate() {
        DispatchQueue.global(qos: .background).async { [self] in // Run allat in the background
            
            let isRunning = isMusicAppRunning()
            if !isRunning {
                updateMenuBarTitle(title: "Apple Music is not running")
                return;
            }
            
            var source = """
                tell app "Music"
                    get player state
                end tell
            """
            
            execAppleScript(with: source) { output in
                self.isPlaying = output == "kPSP" // AppleScript is weird... the last character is either "p" when paused or "P" when playing.
            }
            
            if isPlaying == false {
                if self.menuBarTitle == "Apple Music is not running" || self.menuBarTitle == "Hello!" {
                    updateMenuBarTitle(title: "Nothing is currently playing")
                }
                return;
            }

            source = """
                set output to ""
                tell app "Music"
                    set song_name to name of current track
                    set song_artist to artist of current track
                    set song_duration to duration of current track
                    set song_position to player position
                    set song_album to album of current track
                    set output to "" & song_name & "\\n" & song_artist & "\\n" & song_duration & "\\n" & song_position & "\\n" & song_album
                end tell
                return output
            """
            
            execAppleScript(with: source) { output in
                let tempArray = output.split(separator: "\n")
                if tempArray.count != 5 {
                    return;
                }
                let tempObj = [
                    "name": String(tempArray[0]),
                    "artist": String(tempArray[1]),
                    "duration": String(tempArray[2]).floatValue,
                    "position": String(tempArray[3]).floatValue,
                    "album": String(tempArray[4])
                ]
                
                if self.songName != (tempObj["name"]!) as! String {
                    self.fetchAlbumArtwork(query: "\(tempObj["name"] ?? "") - \(tempObj["artist"] ?? "") - \(tempObj["album"] ?? "")")
                }
                
                self.songName = String(tempArray[0])
                self.songArtist = String(tempArray[1])
                self.songDuration = String(tempArray[2]).floatValue
                self.songPosition = String(tempArray[3]).floatValue
//                print(tempArray[4])
            }
            
            if self.songName == "" { // If the app boots while a song is playing, Apple Music might send empty infos for some reason.
                return;
            }

            updateMenuBarTitle(title: "\(songName) - \(songArtist) (\(songPosition.toTimestamp) / \(songDuration.toTimestamp))")
        }
    }
}
