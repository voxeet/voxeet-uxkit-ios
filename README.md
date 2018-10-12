# Voxeet Conference Kit

<p align="center">
<img src="https://www.voxeet.com/wp-content/themes/wp-theme/assets/images/logo.svg" alt="Voxeet SDK logo" title="Voxeet SDK logo" width="100"/>
</p>


## Requirements


* Operating systems: iOS 9.0 and later versions
* IDE: [Xcode 10.0+](https://developer.apple.com/xcode/)
* Languages: Swift 4.2+, Objective-C
* Supported architectures: armv7, arm64

## Sample application

A sample application is available on this [public repository](https://github.com/voxeet/voxeet-ios-conferencekit/tree/master/Sample) on GitHub.

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

To integrate [VoxeetConferenceKit](https://github.com/voxeet/voxeet-ios-conferencekit) into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "voxeet/voxeet-ios-conferencekit" ~> 1.0
```

Or if you just want to integrate [VoxeetSDK](https://github.com/voxeet/voxeet-ios-sdk):

```ogdl
github "voxeet/voxeet-ios-sdk" ~> 1.0
```

Run `carthage update` to build the frameworks and drag `VoxeetConferenceKit.framework`, `VoxeetSDK.framework` and `WebRTC.framework` into your Xcode project *(needs to be dropped in 'Embedded Binaries')*.
More information at [https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

### Manually

Download the lastest release zip:

**VoxeetConferenceKit:** https://github.com/voxeet/voxeet-ios-conferencekit/releases
*or*
**VoxeetSDK:** https://github.com/voxeet/voxeet-ios-sdk/releases

Unzip and drag and drop frameworks into your project, select 'Copy items if needed' with the right target. Then in the general tab of your target, add the `VoxeetConferenceKit.framework`, `VoxeetSDK.framework` and `WebRTC.framework` into **'Embedded Binaries'**.

### 4. Dependencies

VoxeetConferenceKit is also using some external libraries like Kingfisher for downloading and caching images from the web (users' avatars).
You can either download this framework at [this link](https://github.com/onevcat/Kingfisher) or install it with Carthage (or CocoaPods).

At the end 'Embedded Binaries' and 'Linked Frameworks and Libraries' sections should look like this:

<p align=“center”>
<img src="http://cdn.voxeet.com/images/XCodeFramework.png" alt=“Frameworks” title=“Frameworks” width=“500”/>
</p>

## Voxeet Conference Kit usage

### `initialize`

Use this method to initialize the iOS SDK with your Voxeet user information.

#### Parameters
-   `consumerKey` **String** - The consumer key for your app from [your developer account dashboard](https://developer.voxeet.com).
-   `consumerSecret` **String** - The consumer secret for your app from [your developer account dashboard](https://developer.voxeet.com).

#### Code examples

```swift
import VoxeetSDK
import VoxeetConferenceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

            // Initialization of the Voxeet conference kit.
            VoxeetSDK.shared.initialize(consumerKey: "YOUR_CONSUMER_KEY", consumerSecret: "YOUR_CONSUMER_SECRET")
            VoxeetConferenceKit.shared.initialize()

        return true
    }
}
```

### `create conference`

#### Code examples

```swift
// Create a conference (with a custom conference alias).
VoxeetSDK.shared.conference.create(parameters: ["conferenceAlias": "MY_ALIAS"], success: { json in
    guard let confID = json?["conferenceId"] as? String, let isNew = json?["isNew"] as? Bool else {
        return
    }
    
    // Join the created conference.
    VoxeetSDK.shared.conference.join(conferenceID: confID, video: false, userInfo: nil, success: { json in
    }, fail: { error in
    })
    
    // Invite other users if the conference is just created.
    if isNew {
        VoxeetSDK.shared.conference.invite(conferenceID: confID, externalIDs: users.map({ $0.externalID ?? "" }), completion: nil)
    }
}, fail: { error in
})
```
