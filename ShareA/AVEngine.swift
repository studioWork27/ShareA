//
//  AudioEngine.swift
//  ShareA
//
//  Created by Home on 7/14/17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol AVEngineDelegate: class {
    func stopPlay(engine: AVEngine)
}

class AVEngine: NSObject {
    weak var delegate: AVEngineDelegate?
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    var mixer: AVAudioMixerNode {return engine.mainMixerNode}
//    var songNameArray: [Song] = [.one, .two, .three, .four]
    var audioFileDict = [Song : AVAudioFile!]()
    var audioSessionActive = false
    var engineInit = false
    var isPlaying = false
    var currentSongIndex = 0
    var song: Song {return Song.all[currentSongIndex]}
    var currentSongAudio: AVAudioFile {return audioFileDict[song]!}
    var headphonesConnected = false
    
    override init() {
        super.init()
        initEngine()
        setAudioSessionCategory()
        setAudioSession(active: true)
        postNotifications()
        for name in Song.all {
            audioFileDict[name] = loadAudioFile(title: name.description)
        }
    }
    
    deinit {
        stopEngine()
    }
    
    func initEngine() {
        print("Init engine...")
        engine.attach(playerNode)
        engine.connect(playerNode, to: mixer, format: mixer.outputFormat(forBus: 0))
    }
    
    func stopEngine() {
        print("Stopping Engine")
        playerNode.stop()
        engine.stop()
        engine.detach(playerNode)
        setAudioSession(active: false)
        isPlaying = false
        engineInit = false
        audioSessionActive = false
    }
    
    func loadCurrentSong(index: Int) {
        currentSongIndex = index
        if isPlaying {
            isPlaying = false
            playerNode.stop()
        }
    }
    
    func setVolume(volume: Float) {
        mixer.outputVolume = volume
    }
}

//MARK: - Play
extension AVEngine {
    func startStopPlayer() {
    
        
        
        isPlaying = !isPlaying
        switch isPlaying {
        case false:
            playerNode.stop()
            engine.pause()
            setAudioSession(active: false)
        case true:
            checkEngineInit()
            if !audioSessionActive {
                setAudioSession(active: true)
            }
            playerPlay()
        }
    }
    
    func playerPlay() {
        if isPlaying {
            weak var weakSelf = self
            let time = AVAudioTime(hostTime: 0)
            playerNode.scheduleFile(currentSongAudio, at: time, completionHandler: {
                DispatchQueue.global(qos: .userInitiated).sync {
                    weakSelf?.finishedPlaying()
                }
            })
            playerNode.play()
        }
    }
    
    func finishedPlaying() {
        print("\n\n\nfinishedPlaying\n\n\n")
        isPlaying = false
        setAudioSession(active: false)
        DispatchQueue.main.async {
            self.delegate?.stopPlay(engine: self)
        }
    }
}

//MARK: - Notification
extension AVEngine {
    func  postNotifications() {
        registerForRouteChangeNotification()
        registerForInterruptionNotification()
        registerForSecondaryAudioNotifications()
    }
    
    //MARK: - RouteChange
    func registerForRouteChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: .AVAudioSessionRouteChange,
                                               object: AVAudioSession.sharedInstance())
        
    }
    
    func handleRouteChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                headphonesConnected = true
            }

            if headphonesConnected {
                print("headphonesConnected")
                print(engine)
//                do {
//                    try engine.start()
//                } catch {
//                    print(error)
//                }
//                if !engine.isRunning {
//                    do {
//                        try engine.start()
//                    } catch {
//                        print(error)
//                    }
//                }
                playerNode.pause()
                playerNode.play()
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                
                for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                    headphonesConnected = false
                }
                if !headphonesConnected {
                    isPlaying = false
                    self.delegate?.stopPlay(engine: self)
                }
            }
            
        default:
            print(reason)
            
        }
    }
    
    //MARK: - Interruption
    func registerForInterruptionNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: .AVAudioSessionInterruption,
                                               object: AVAudioSession.sharedInstance())
    }
    
    func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            // Interruption began, take appropriate actions (save state, update user interface)
            isPlaying = false
            self.delegate?.stopPlay(engine: self)
        }
        else if type == .ended {
            guard let optionsValue =
                info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return}
            
            let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption Ended - playback should resume
            }
        }
    }
    
    //MARK: - SecondaryAudio
    func registerForSecondaryAudioNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSecondaryAudio),
                                               name: .AVAudioSessionSilenceSecondaryAudioHint,
                                               object: AVAudioSession.sharedInstance())
    }
    
    func handleSecondaryAudio(notification: Notification) {
        // Determine hint type
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let type = AVAudioSessionSilenceSecondaryAudioHintType(rawValue: typeValue) else {
                return
        }
        
        if type == .begin {
            // Other app audio started playing - mute secondary audio
            isPlaying = false
            self.delegate?.stopPlay(engine: self)
        } else {
            // Other app audio stopped playing - restart secondary audio
        }
    }
}

//MARK: - Init & AudioSession
extension AVEngine {
    func setAudioSessionCategory() {
        _ = AVAudioSession.sharedInstance().setAudioSessionCategory(category: AVAudioSessionCategoryPlayback)
        
        
        
        
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
//        } catch {
//            print("category \(error)")
//        }
    }
    
    func setAudioSession(active: Bool) {
        if AVAudioSession.sharedInstance().setAudioSession(active: active) {
            audioSessionActive = active
        }
        
        
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setActive(active)
//            audioSessionActive = active
//        } catch {
//            print("category \(error)")
//        }
//        print("setAudioSession: \(audioSessionActive)")
    }
    
    func startEngine() {
        if engine.isRunning {return}
        engine.prepare()
        do {
            try engine.start()
            engineInit = true
        }
        catch {print("audioEngine \(error)")}
    }
    
    func checkEngineInit() {
        if !engine.isRunning {
            self.startEngine()
            print("checkEngine called")
        }
    }
    
    //MARK: - Load AudioFile
    func loadAudioFile(title: String) -> AVAudioFile? {
        var audioFile: AVAudioFile!
        guard let fileURL = Bundle.main.url(forResource: title, withExtension: "mp3") else {
            print("could not read audio file")
            return nil
        }
        do {audioFile = try AVAudioFile(forReading: fileURL)}
        catch {
            print("audioFile \(error)")
            return nil
        }
        return audioFile
    }
}

//MARK: - Song
enum Song{
    case one, two, three, four
    var description: String {return String(describing: self)}
    static let all = [one, two, three, four]
}












