Pod::Spec.new do |spec|
  spec.name = "VoxeetUXKit"
  spec.version = "1.3.3"
  spec.summary = "The Voxeet UXKit is a quick way of adding premium audio, video chats, and other supported options."
  spec.license = "MIT"
  spec.author = "Voxeet"
  spec.homepage = "https://voxeet.com"
  spec.platform = :ios, "9.0"
  spec.swift_version = "5.2.2"
  spec.source = { :git => "https://github.com/voxeet/voxeet-uxkit-ios.git", :tag => spec.version }
  spec.framework = "VoxeetUXKit"
  spec.source_files = "VoxeetUXKit/**/*.{h,m,swift}"
  spec.resources = "VoxeetUXKit/**/*.{mp3,storyboard,xcassets,lproj}"
  spec.framework = "UIKit"
  spec.dependency "VoxeetSDK", "~> 2.0"
  spec.dependency "SDWebImage", "~> 5.0"
end
