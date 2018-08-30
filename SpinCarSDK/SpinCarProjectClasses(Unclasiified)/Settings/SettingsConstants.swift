//
//  SettingsConstants.swift
//  SpinCar
//

import UIKit

struct SettingsConstants {

    // Main Settings Screen
    static let sectionHeaderHeight: CGFloat = 40.0
    static let settingsCellHeight: CGFloat = 55.0
    static let settingsTextLabelFont = UIFont.spinCarFont(size: 11, style: .SemiBold)
    static let settingsSubtitleLabelFont = UIFont.spinCarFont(size: 16, style: .Light)
    static let settingsHeaderFont = UIFont.spinCarFont(size: 20, style: .Light)
    static let signoutCellIndexPath = IndexPath(row: 1, section: 2)
    
    //Navigation Bar
    static let titleFont = UIFont.spinCarFont(size: 24, style: .Light)
    static let navigationBarTextColor = UIColor.darkGray
    
    //Settings Subsection Screens
    static let settingsSubsectionTextLabelFont = UIFont.spinCarFont(size: 16, style: .Light)
    static let settingsSubsectionCellHeight: CGFloat = 60.0
    
    // User Defaults Settings Keys
    static let gridEnabled = "gridEnabled"
    static let numberOfExteriorPhotos = "numberOfExteriorPhotos"
    static let soundEffectsEnabled = "soundEffectsEnabled"
    static let seamReductionEnabled = "seamReductionEnabled"
    static let tripodModeEnabled = "tripodModeEnabled"
    static let cellularUploadEnabled = "cellularUploadEnabled"
    static let hdrEnabled = "HDREnabled"
    static let cameraSettings = "cameraSettings"
    static let loginEmail = "loginEmail"
    static let preferredBlurStrength = "preferredBlurStrength"
    static let preferredBlurTransition = "preferredBlurTransition"
    
    // Exterior Photos Constants
    static let exteriorPhotosStartingOffset = "exteriorPhotosStartingOffset"
    static let exteriorOverlayOffset = "exteriorOverlayOffset"

    // Localized Strings
    static let cameraSettingsHeader = NSLocalizedString("Camera_Settings", comment: "Section title indicating that this section is for camera-related settings")
    static let spinSettingsHeader = NSLocalizedString("Spin_Settings", comment: "Section title indicating that this section is for spin-related settings")
    static let userSettingsHeader = NSLocalizedString("User_Settings", comment: "Section title indicating that this section is for user-related settings")
    static let settingsLocked = NSLocalizedString("Settings_Locked", comment: "Label indicating the user has chosen the setting 'locked'")
    static let settingsContinuous = NSLocalizedString("Settings_Continuous", comment: "Label indicating the user has chosen the setting 'continuous'")
    static let settingsAutomatic = NSLocalizedString("Settings_Automatic", comment: "Label indicating the user has chosen the setting 'automatic'")
    static let settingsOff = NSLocalizedString("Settings_Off", comment: "Label indicating the user has chosen the setting 'off'")
    static let settingsTorch = NSLocalizedString("Settings_Torch", comment: "Label indicating the user has chosen the setting 'torch'")
    
}
