use_frameworks!
inhibit_all_warnings!
source 'https://github.com/CocoaPods/Specs.git'
target 'iOS-Email-Client' do
  pod 'Google/SignIn'
  pod 'GoogleAPIClientForREST/Gmail', '~> 1.1.1'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'FLAnimatedImage'
  pod 'Alamofire'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'CLTokenInputView', :git => 'https://github.com/danieltigse/CLTokenInputView.git', :branch => 'master'
  pod 'Material', '~> 2.10.3'
  pod 'CICropPicker'
  pod 'SDWebImage', '~>3.8'
  pod 'M13Checkbox'
  pod 'TPCustomSwitch', '~> 2.1.4'
  pod 'MonkeyKit'
  pod 'SwiftWebSocket'
  pod 'SwiftSoup'
  pod 'MMMaterialDesignSpinner'
  pod "MIBadgeButton-Swift", :git => 'https://github.com/mustafaibrahim989/MIBadgeButton-Swift.git', :branch => 'master'
  pod "MMMaterialDesignSpinner"
  pod 'RichEditorView', :git => 'https://github.com/cjwirth/RichEditorView', :branch => 'swift-4'
  pod 'IQKeyboardManagerSwift'
  pod 'UIImageView-Letters'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end
