# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SpinCarSDK' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  use_frameworks!

    pod 'Alamofire', '~> 4.5.1'
    pod 'Fabric', '~> 1.6.13'
    pod 'Crashlytics', '~> 3.8.6'
    pod 'Mixpanel', '~> 3.2.1'
    pod 'IGListKit', '~> 3.1.1'
    pod 'SwipeCellKit', :git => 'https://github.com/ameerSpincar/SwipeCellKit.git'
    pod 'OpenCV'
    #, :git => 'https://github.com/swipetospin/openCV-SpinCar.git'
    pod 'SwiftLint'

    # ignore all warnings from all pods
    inhibit_all_warnings!

end
post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
