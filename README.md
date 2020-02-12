# Voxeet UXKit iOS

<p align="center">
<img src="https://www.voxeet.com/images/VoxeetDolbyLogo.svg" alt="Voxeet SDK logo" title="Voxeet SDK logo" width="100"/>
</p>


## Requirements


* **Operating systems:** iOS 9.0 and later versions
* **IDE:** [Xcode 11+](https://developer.apple.com/xcode/)
* **Languages:** Swift 5+, Objective-C, [React Native](https://github.com/voxeet/voxeet-uxkit-reactnative), [Cordova](https://github.com/voxeet/voxeet-uxkit-cordova)
* **Supported architectures:** armv7, arm64, i386, x86_64

## Sample application

A sample application is available on this [GitHub repository](https://github.com/voxeet/voxeet-uxkit-ios/tree/master/Sample).
**VoxeetUXKit** is a framework based on **VoxeetSDK** ([https://github.com/voxeet/voxeet-sdk-ios](https://github.com/voxeet/voxeet-sdk-ios)).

![CallKit](http://cdn.voxeet.com/images/IncomingCallKit.png "CallKit") ![Conference maximized](http://cdn.voxeet.com/images/OutgoingCall.png "Conference maximized") ![Conference minimized](http://cdn.voxeet.com/images/CallMinimize.png "Conference minimized")


## Installing the iOS SDK


### 1. Get your credentials

Get a consumer key and consumer secret for your app from [your developer account dashboard](https://developer.voxeet.com).

**If you are a new user, you'll need to sign up for a Voxeet developer account and add an app.** You can create one app with a trial account. Upgrade to a paid account for multiple apps and to continue using Voxeet after your trial expires. We will give you dedicated help to get you up and running fast.

### 2. Project setup

Enable **background mode** (go to your target settings -> 'Capabilities' -> 'Background Modes')
- Turn on 'Audio, AirPlay and Picture in Picture'  
- Turn on 'Voice over IP'

If you want to support CallKit (receiving incoming call when application is killed) with VoIP push notification, enable 'Push Notifications' (you will need to upload your [VoIP push certificate](https://developer.apple.com/account/ios/certificate/) to the Voxeet developer portal).

<p align="center">
<img src="http://cdn.voxeet.com/images/VoxeetConferenceKitCapabilitiesXCode2.png" alt="Capabilities" title="Capabilities" width="500"/>
</p>

Privacy **permissions**, add two new keys in the Info.plist: 
- Privacy - Microphone Usage Description
- Privacy - Camera Usage Description

### 3. Installation

#### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate [VoxeetUXKit](https://github.com/voxeet/voxeet-uxkit-ios) into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "voxeet/voxeet-uxkit-ios" ~> 1.0
```

Run `carthage update` to build the frameworks and drag `VoxeetUXKit.framework`, `VoxeetSDK.framework` and `WebRTC.framework` into your Xcode project *(needs to be dropped in 'Embedded Binaries')*.
More information at [https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

#### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Swift and Objective-C Cocoa projects. It has over 70 thousand libraries and is used in over 3 million apps. CocoaPods can help you scale your projects elegantly.

You can install CocoaPods with the following command:

```bash
$ sudo gem install cocoapods
```

To integrate [VoxeetUXKit](https://github.com/voxeet/voxeet-uxkit-ios) into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ogdl
pod 'VoxeetUXKit', '~> 1.0'
```

Run `pod install` to build dependencies.

### Manually

Download the lastest release zip:

**VoxeetUXKit:** https://github.com/voxeet/voxeet-uxkit-ios/releases
*and*
**VoxeetSDK:** https://github.com/voxeet/voxeet-sdk-ios/releases

Unzip and drag and drop frameworks into your project, select 'Copy items if needed' with the right target. Then in the general tab of your target, add the `VoxeetUXKit.framework`, `VoxeetSDK.framework` and `WebRTC.framework` into **'Embedded Binaries'**.

### 4. Dependencies

VoxeetUXKit is also using some external libraries like SDWebImage for downloading and caching images from the web (users' avatars).
You can either download this framework at [this link](https://github.com/SDWebImage/SDWebImage) or install it with Carthage / CocoaPods.

At the end 'Embedded Binaries' and 'Linked Frameworks and Libraries' sections should look like this:

<p align=“center”>
<img src="http://cdn.voxeet.com/images/XCodeFramework.png" alt=“Frameworks” title=“Frameworks” width=“500”/>
</p>

*(WebRTC.framework missing on this screenshot and Kingfisher has been replaced by SDWebImage)*

## Voxeet UXKit usage

### `initialize`

Use these methods to initialize the Voxeet frameworks.

#### Parameters
-   `consumerKey` **String** - The consumer key for your app from [your developer account dashboard](https://developer.voxeet.com).
-   `consumerSecret` **String** - The consumer secret for your app from [your developer account dashboard](https://developer.voxeet.com).

#### Code examples

```swift
import VoxeetSDK
import VoxeetUXKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Voxeet SDKs initialization.
        VoxeetSDK.shared.initialize(consumerKey: "YOUR_CONSUMER_KEY", consumerSecret: "YOUR_CONSUMER_SECRET")
        VoxeetUXKit.shared.initialize()
        
        // Example of public variables to change the conference behavior.
        VoxeetSDK.shared.notification.type = .none
        VoxeetSDK.shared.conference.defaultBuiltInSpeaker = true
        VoxeetSDK.shared.conference.defaultVideo = false
        VoxeetUXKit.shared.appearMaximized = true
        VoxeetUXKit.shared.telecom = false
        
        return true
    }
}
```

#### References

https://voxeet.com/documentation/sdk/reference/ios/voxeetsdk#initialize

### `open`

Opens a new session.

#### Parameters

-   `options` **VTParticipantInfo?** - Information about the current participant (optional)
-   `completion` **((_ error: NSError?) -> Void)?** - A block object to be executed when the server connection sequence ends. This block has no return value and takes a single `NSError` argument that indicates whether or not the connection to the server succeeded

#### Examples

```swift
let participantInfo = VTParticipantInfo(externalID: "1234", name: "Username", avatarURL: "https://voxeet.com/logo.jpg")
VoxeetSDK.shared.session.open(info: participantInfo) { error in }
```

#### References

https://voxeet.com/documentation/sdk/reference/ios/session#open

### `close`

Closes the current session (it will stop the socket and stop receiving VoIP push notification).

#### Parameters

-   `completion` **((_ error: NSError?) -> Void)?** - A block object to be executed when the server connection sequence ends. This block has no return value and takes a single `NSError` argument that indicates whether or not the connection to the server succeeded.

#### Examples

```swift
VoxeetSDK.shared.session.close { error in }
```

#### References

https://voxeet.com/documentation/sdk/reference/ios/session#close

### `start conference`

Start the conference UI.

#### Examples

```swift
// Create a conference (with a custom conference alias).
let options = VTConferenceOptions()
options.alias = conferenceAlias
VoxeetSDK.shared.conference.create(options: options, success: { conference in
    // Join the created conference.
    VoxeetSDK.shared.conference.join(conference: conference, success: { conference in
    }, fail: { error in
    })
}, fail: { error in
})
```

#### References

https://voxeet.com/documentation/sdk/reference/ios/conference#create
https://voxeet.com/documentation/sdk/reference/ios/conference#join

### `stop conference`

Stop the conference UI.

#### Examples

```swift
VoxeetSDK.shared.conference.leave { error in }
```

#### References

https://voxeet.com/documentation/sdk/reference/ios/conference#leave

### `useful variables`

By default, conference appears maximized. If false, the conference will appear minimized.

```swift
VoxeetUXKit.shared.appearMaximized = true
```

If someone hangs up, everybody is kicked out of the conference.

```swift
VoxeetUXKit.shared.telecom = false
```

### `CallKit sound and image`

If `CallKitSound.mp3` is overridden, the ringing sound will be replaced by your mp3. 
Same as `IconMask.png` if overridden, it will replace the default CallKit image by yours (40x40px).

## Tech

The Voxeet iOS SDK and UXKit rely on these open source projects:

* [SDWebImage](https://github.com/SDWebImage/SDWebImage), provides an async image downloader with cache support.
* [Starscream](https://github.com/daltoniam/Starscream), a conforming WebSocket (RFC 6455) client library in Swift for iOS and OSX.
* [Alamofire](https://github.com/Alamofire/Alamofire), an HTTP networking library written in Swift.
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON), a tool for handling JSON data in Swift.

## SDK version

1.3.0

© Voxeet, 2020
