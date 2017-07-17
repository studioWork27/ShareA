//
//  PhilsAudioPlayer.swift
//  ShareA
//
//  Created by Phil Scarfi on 7/16/17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import AVFoundation

enum PioneerAudioOutputType {
    case speaker
    case headphone
    case other
}

enum PioneerAudioPlayerStatus {
    case playing
    case paused
    case stopped
    case interuptionBegan
    case interuptionEnded
    case finished
}

protocol PioneerAudioPlayerDelegate {
    func player(player: PioneerAudioPlayer, switchedAudioOutputType output: PioneerAudioOutputType)
    func player(player: PioneerAudioPlayer, statusChanged status: PioneerAudioPlayerStatus)
}


public class PioneerAudioPlayer: NSObject {
    fileprivate var player: AVAudioPlayer?
    var status = PioneerAudioPlayerStatus.stopped
    var delegate: PioneerAudioPlayerDelegate?
    
    override init() {
        super.init()
        setupObservers()
    }
    
    func setupObservers() {
        //Output Change
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChanged), name: .AVAudioSessionRouteChange, object: nil)
        
        //Interuptions
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: .AVAudioSessionInterruption,
                                               object: AVAudioSession.sharedInstance())
    }  
}

//MARK: - Observer Functions
extension PioneerAudioPlayer {
    func audioRouteChanged(notification: Notification) {
        let session = AVAudioSession.sharedInstance()
        for output in session.currentRoute.outputs {
            if output.portType == AVAudioSessionPortHeadphones {
                delegate?.player(player: self, switchedAudioOutputType: .headphone)
            } else if output.portType == AVAudioSessionPortBuiltInSpeaker {
                delegate?.player(player: self, switchedAudioOutputType: .speaker)
            } else {
                delegate?.player(player: self, switchedAudioOutputType: .other)
            }
        }
    }
    
    func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            delegate?.player(player: self, statusChanged: .interuptionBegan)
        }
        else if type == .ended {
            delegate?.player(player: self, statusChanged: .interuptionEnded)
        }
    }
}

//MARK: - User Functions
extension PioneerAudioPlayer {
    
    func playSoundFromURL(url: URL) -> Bool {
        player?.stop()
        player = nil
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            guard let _ = player else {
                return false
            }
            resume()
        } catch let error {
            print(error.localizedDescription)
            return false
        }
        return true
    }
    
    func hasAudio() -> Bool {
        return player != nil
    }
    
    func resume() {
        player?.play()
        if player?.isPlaying == true {
            self.status = .playing
            delegate?.player(player: self, statusChanged: .playing)
        }
    }
    
    func stop() {
        player?.stop()
        if player?.isPlaying == false {
            self.status = .stopped
            delegate?.player(player: self, statusChanged: .stopped)
        }
    }
    
    func pause() {
        player?.pause()
        if player?.isPlaying == false {
            self.status = .paused
            delegate?.player(player: self, statusChanged: .paused)
        }
    }
    
    func setVolume(volume: Float) {
        player?.volume = volume
    }
}

//MARK: - AVAudioPlayer Delegate
extension PioneerAudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.player(player: self, statusChanged: .finished)
    }
}
