Pod::Spec.new do |spec|
  spec.name = "VoxeetUXKit"
  spec.version = "1.3.7"
  spec.summary = "The Voxeet UXKit is a quick way of adding premium audio, video chats, and other supported options."
  spec.license = "Dolby Software License Agreement"
  spec.author = "Voxeet"
  spec.homepage = "https://dolby.io"
  spec.platform = :ios, "11.0"
  spec.swift_version = "5.3"
  spec.source = { :git => "https://github.com/voxeet/voxeet-uxkit-ios.git", :tag => spec.version }
  spec.framework = "VoxeetUXKit"
  spec.source_files = "VoxeetUXKit/**/*.{h,m,swift}"
  spec.resources = "VoxeetUXKit/**/*.{mp3,storyboard,xcassets,lproj}"
  spec.framework = "UIKit"
  spec.dependency "VoxeetSDK", "~> 3.0"
  spec.dependency "SDWebImage", "~> 5.0"

  # MacBook arm simulator isn't supported.
  spec.pod_target_xcconfig = { 
    'VALID_ARCHS[sdk=iphonesimulator*]' => '',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' 
  }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
