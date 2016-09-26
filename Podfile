use_frameworks!
target 'OpenHumansUpload' do
	pod "HealthKitSampleGenerator", :git => 'https://github.com/blackbear/healthkit-sample-generator.git'
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end

end
workspace 'OpenHumans'
project 'OpenHumansUpload/OpenHumansUpload.xcodeproj'
