# Uncomment the next line to define a global platform for your project
 

target 'SpinCarSDK' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    
    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '11.4'

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
pre_install do |installer|
	# workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
	Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end