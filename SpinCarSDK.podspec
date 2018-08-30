

Pod::Spec.new do |s|


  s.name         = "SpinCarSDK"
  s.version      = "0.1.0"
  s.summary      = "A short description of SpinCarSDK."

  s.description  = <<-DESC
                     Spin Car SDK
                   DESC

  s.homepage     = "http://EXAMPLE/SpinCarSDK"

  s.license      = "MIT"


  s.author       = { "Archil Kuprashvili" => "achiko93@gmail.com" }
 
  s.source       = { :git => "https://github.com/achikuprashvili/SpinCarSDK.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "11.4"

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

    s.source_files = "SpinCarSDK/**/*.{h,m,swift}"

    s.dependency 'Alamofire', '~> 4.5.1'
    s.dependency 'Fabric', '~> 1.6.13'
    s.dependency 'Crashlytics', '~> 3.8.6'
    s.dependency 'Mixpanel', '~> 3.2.1'
    s.dependency 'IGListKit', '~> 3.1.1'
    s.dependency 'SwipeCellKit'#, :git => 'https://github.com/ameerSpincar/SwipeCellKit.git'
    s.dependency 'OpenCV'
    #, :git => 'https://github.com/swipetospin/openCV-SpinCar.git'
    s.dependency 'SwiftLint'

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
