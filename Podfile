target 'Cloudship' do
  use_frameworks!
  pod 'Google-Mobile-Ads-SDK'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
    end
  end

  # Inject Secrets.xcconfig into Pods xcconfigs so API keys are available
  # at build time. This runs on every `pod install` so it's self-healing.
  secrets_include = '#include? "../../../Secrets.xcconfig"'
  Dir.glob("Pods/Target Support Files/Pods-Cloudship/*.xcconfig").each do |xcconfig_path|
    content = File.read(xcconfig_path)
    unless content.include?(secrets_include)
      File.write(xcconfig_path, "#{secrets_include}\n#{content}")
    end
  end
end
