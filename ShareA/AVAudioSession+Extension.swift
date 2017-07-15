//
//  AVAudioSession+Extension.swift
//  ShareA
//
//  Created by Phil Scarfi on 7/14/17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioSession {
    func setAudioSessionCategory(category: String) -> Bool{
        do {
            try self.setCategory(category)
            return true
        } catch {
            print("category \(error)")
            return false
        }
    }
    
    func setAudioSession(active: Bool) -> Bool {
        do {
            try self.setActive(active)
            return true
        } catch {
            print("category \(error)")
        }
        return false
    }
}
