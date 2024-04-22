# Uncomment the next line to define a global platform for your project
# platform :ios, '16.0'
use_frameworks!
project 'SightSense.xcodeproj'

pod 'GoogleMLKit/Translate', '3.2.0'
# To recognize Latin script
pod 'GoogleMLKit/TextRecognition', '3.2.0'
# To recognize Chinese script
pod 'GoogleMLKit/TextRecognitionChinese', '3.2.0'
# To recognize Devanagari script
pod 'GoogleMLKit/TextRecognitionDevanagari', '3.2.0'
# To recognize Japanese script
pod 'GoogleMLKit/TextRecognitionJapanese', '3.2.0'
# To recognize Korean script
pod 'GoogleMLKit/TextRecognitionKorean', '3.2.0'

target 'SightSense' do
  # Comment the next line if you don't want to use dynamic frameworks
  # use_frameworks!

  # Pods for SightSense

  target 'SightSenseTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SightSenseUITests' do
    # Pods for testing
  end

end



# post install
post_install do |installer|
  # fix xcode 15 DT_TOOLCHAIN_DIR - remove after fix oficially - https://github.com/CocoaPods/CocoaPods/issues/12065
  installer.aggregate_targets.each do |target|
      target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
          xcconfig_path = config.base_configuration_reference.real_path
          IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end
end
