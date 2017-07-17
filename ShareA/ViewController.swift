//
//  ViewController.swift
//  ShareA
//
//  Created by Home on 7/14/17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AVEngineDelegate {
    
    let pioneerPlayer = PioneerAudioPlayer()

    @IBOutlet weak var playButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        pioneerPlayer.delegate = self
    }
    
    func stopPlay(engine: AVEngine) {
        playButton.toggleTitle(state: false)
    }
}

//MARK: - Actions
extension ViewController {
    @IBAction func segCtrlTapped(_ sender: UISegmentedControl) {
        let song = Song.all[sender.selectedSegmentIndex]
        if let fileURL = getSongURL(song: song) {
            if pioneerPlayer.playSoundFromURL(url: fileURL) {
                print("Setup Audio to play")
            }
        }
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if pioneerPlayer.hasAudio() {
            if sender.title(for: .normal) == "Play" {
                pioneerPlayer.resume()
            } else {
                pioneerPlayer.pause()
            }
        } else {
            if let fileURL = getSongURL(song: Song.one) {
                if pioneerPlayer.playSoundFromURL(url: fileURL) {
                    print("Setup Audio to play")
                }
            }
        }
    }
    
    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
        pioneerPlayer.setVolume(volume: sender.value)
    }
    
    func getSongURL(song: Song) -> URL? {
        return Bundle.main.url(forResource: song.description, withExtension: "mp3")

    }
}


extension ViewController: PioneerAudioPlayerDelegate {
    
    func player(player: PioneerAudioPlayer, statusChanged status: PioneerAudioPlayerStatus) {
        print("Audio Player Status Changed: \(status)")

        DispatchQueue.main.async {
            self.playButton.setTitle(status.title, for: .normal)
        }
        
      /*  switch status {
        case .playing:
            playButton.setTitle("Pause", for: .normal)
            break
        case .paused:
            playButton.setTitle("Play", for: .normal)
            break
        case .stopped:
            playButton.setTitle("Play", for: .normal)
            break
        case .interuptionBegan:
            playButton.setTitle("Wait", for: .normal)
            break
        case .interuptionEnded:
            playButton.setTitle("Pause", for: .normal)
            break
        case .finished:
            playButton.setTitle("Play", for: .normal)
            break
        }*/
        
    }
    
    func player(player: PioneerAudioPlayer, switchedAudioOutputType output: PioneerAudioOutputType) {
        print("Audio Player Output Changed: \(output)")
        if output == .speaker {
            player.stop()
        }
    }
}

//MARK: - Button Title
extension PioneerAudioPlayerStatus {
    var title: String {
        let buttonTitleDict: [PioneerAudioPlayerStatus : String] = [.playing : "Pause",
                                                            .paused: "Play",
                                                            .stopped : "Play",
                                                            .interuptionBegan : "Wait",
                                                            .interuptionEnded : "Pause",
                                                            .secondaryAudioHint : "Play",
                                                            .finished : "Play"]
        return buttonTitleDict[self]!}
}

//MARK: - UIButton
extension UIButton {
    func toggleTitle(state: Bool) {
        let title = state ? "Stop" : "Play"
        self.setTitle(title, for: .normal)
    }
}

