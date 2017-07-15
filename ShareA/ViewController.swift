//
//  ViewController.swift
//  ShareA
//
//  Created by Home on 7/14/17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AVEngineDelegate {

    let audioEngine = AVEngine()
    
    @IBOutlet weak var playButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine.delegate = self
    }
    
    func stopPlay(engine: AVEngine) {
        playButton.toggleTitle(state: false)
    }
}

//MARK: - Actions
extension ViewController {
    @IBAction func segCtrlTapped(_ sender: UISegmentedControl) {
        audioEngine.loadCurrentSong(index: sender.selectedSegmentIndex)
        playButton.toggleTitle(state: audioEngine.isPlaying)
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        audioEngine.startStopPlayer()
        sender.toggleTitle(state: audioEngine.isPlaying)
    }
    
    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
         audioEngine.setVolume(volume: sender.value)
    }
}

//MARK: - UIButton
extension UIButton {
    func toggleTitle(state: Bool) {
        let title = state ? "Stop" : "Play"
        self.setTitle(title, for: .normal)
    }
}

