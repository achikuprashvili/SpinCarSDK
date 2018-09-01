//
//  SoundEffectPlayer.swift
//  SpinCar
//
//  Created by Ameer Spincar on 6/29/17.
//  Copyright © 2017 SpinCar. All rights reserved.
//

import AVFoundation

class SoundEffectPlayer: AVAudioPlayer {
    
    var player: AVAudioPlayer?
    var crashlyticsLogger = SpinCarCrashlyticsLogger.SpinCarLogger
    
    public enum SoundEffect: String {
        case Warning
        case Success
        case StartRecording
        case StopRecording
        case AppLaunch
        case Accept
    }
    
    func playSound(_ soundEffect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: soundEffect.rawValue, withExtension: "caf") else {
            self.crashlyticsLogger.log("Failed to load sound effect: \(soundEffect.rawValue)")
            return
        }
        if let settings = UserDefaults.standard.object(forKey: "settings") as? [String: AnyObject],
        settings[SettingsConstants.soundEffectsEnabled] as? Bool == false {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                with: [
                    .mixWithOthers,
                    .allowBluetooth,
                    .defaultToSpeaker
                ]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.player = try AVAudioPlayer(contentsOf: url)
            guard let effect = player else { return }
            
            DispatchQueue.main.async {
                effect.prepareToPlay()
                effect.volume = 1.0
                effect.play()
            }
        } catch let error {
            self.crashlyticsLogger.log("Failed to play sound effect: \(error.localizedDescription)")
        }
    }
    
}
