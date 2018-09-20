# Voxeet Conference Kit

<p align="center">
<img src="https://www.voxeet.com/wp-content/themes/wp-theme/assets/images/logo.svg" alt="Voxeet SDK logo" title="Voxeet SDK logo" width="100"/>
</p>

The VoxeetConferenceKit is a Swift project allowing users to:

  - Launch a ready to go user interface
  - Customize the conference UI
  - Embed the [VoxeetSDK](https://github.com/voxeet/voxeet-ios-sdk)

## Table of contents

  1. [Requirements](#requirements)
  1. [Sample application](#sample-application)
  1. [Project setup](#project-setup)
  1. [Initializing the kit](#initializing-the-kit)
  1. [Integrating to your project](#integrating-to-your-project)
  1. [VoxeetConferenceKit usage](#voxeetconferencekit-usage)

## Requirements

  - iOS 9.0+
  - Xcode 9.0+
  - Swift 4.0+ / Objective-C

## Sample application

A sample application is available on this [public repository](https://github.com/voxeet/voxeet-ios-conferencekit/tree/master/Sample) on GitHub.

![CallKit](http://cdn.voxeet.com/images/IncomingCallKit.png "CallKit") ![Conference maximized](http://cdn.voxeet.com/images/OutgoingCall.png "Conference maximized") ![Conference minimized](http://cdn.voxeet.com/images/CallMinimize.png "Conference minimized")

## Project setup

Before implementing the VoxeetConferenceKit, there are a few things to do first:

You need to disable **Bitcode** in your Xcode target settings: 'Build Settings' -> 'Enable Bitcode' -> No

Enable **background mode** (go to your target settings -> 'Capabilities' -> 'Background Modes')
- Turn on 'Audio, AirPlay and Picture in Picture'  
- Turn on 'Voice over IP' ([Xcode 9 bug missing](https://stackoverflow.com/a/46463150))

If you want to support CallKit (receiving incoming call when application is killed) with VoIP push notification, enable 'Push Notifications' (you will need to send your [VoIP push certificate](https://developer.apple.com/account/ios/certificate/) to Voxeet).

<p align=“center”>
<img src="http://cdn.voxeet.com/images/VoxeetConferenceKitCapabilitiesXCode2.png" alt=“Capabilities” title=“Capabilities” width=“500”/>
</p>

Privacy **permissions**, in your plist add two new keys: 
- Privacy - Microphone Usage Description
- Privacy - Camera Usage Description

## Initializing the kit

    You can access to the entire VoxeetConferenceKit code if you want to custom the conference room. The only thing to do is to request access by sending us an email.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate VoxeetConferenceKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "voxeet/voxeet-ios-conferencekit" ~> 1.0
```

Run `carthage update` to build the framework and drag `VoxeetConferenceKit.framework` and `VoxeetSDK.framework` builds into your Xcode project *(needs to be dropped in 'Embedded Binaries' and 'Linked Frameworks and Libraries')*.
More information at [https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

### Manually

Once the repo is cloned, find the `VoxeetConferenceKit.framework` and `VoxeetSDK.framework` into the **VoxeetConferenceKit** folder.

Drag and drop them into your project, select 'Copy items if needed' with the right target.
Then in the general tab of your target, add the `VoxeetConferenceKit.framework` **AND** `VoxeetSDK.framework` into 'Embedded Binaries' and 'Linked Frameworks and Libraries'.

### Dependencies

VoxeetConferenceKit is also using some external libraries like Kingfisher for downloading and caching images from the web (users' avatars).
You can either download this framework at [this link](https://github.com/onevcat/Kingfisher) or install it with Carthage (or CocoaPods).

At the end 'Embedded Binaries' and 'Linked Frameworks and Libraries' sections should look like this:

<p align=“center”>
<img src="http://cdn.voxeet.com/images/XCodeFramework.png" alt=“Frameworks” title=“Frameworks” width=“500”/>
</p>

## Integrating to your project

In your `AppDelegate.swift` initialize the kit like this:

```swift
import VoxeetConferenceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialization of the Voxeet conference kit (connect the session later).
        VoxeetConferenceKit.shared.initialize(consumerKey: "consumerKey", consumerSecret: "consumerSecret")
        
        return true
    }
}
```

To support push notifications add this extension to your AppDelegate:

```swift
/*
 *  MARK: - Voxeet VoIP push notifications
 */

extension AppDelegate {
    /// Useful bellow iOS 10.
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        VoxeetConferenceKit.shared.application(application, didReceive: notification)
    }
    
    /// Useful bellow iOS 10.
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        VoxeetConferenceKit.shared.application(application, handleActionWithIdentifier: identifier, for: notification, completionHandler: completionHandler)
    }
}

```

## VoxeetConferenceKit usage

### Initializing

```swift
VoxeetConferenceKit.shared.initialize(consumerKey: "consumerKey", consumerSecret: "consumerSecret")
```

### Openning a session *(manually)*

Openning a session is like a login. However you need to have initialized the SDK with `connectSession` sets to **false**.

```swift
import VoxeetSDK
import VoxeetConferenceKit

let user = VTUser(id: "111", name: "Benoit", photoURL: "https://cdn.voxeet.com/images/team-benoit-senard.png")

VoxeetConferenceKit.shared.openSession(user: user, completion: { (error) in
})
```

It is also possible to open a session with custom user information like this: ["externalName": "User", "externalPhotoUrl": "http://voxeet.com/voxeet-logo.jpg", "myCustomInfo": "test", ...].

```swift
VoxeetConferenceKit.shared.openSession(userID: "123456789", userInfo: ["externalName": "John Smith"], completion: { (error) in
})
```

### Updating a session *(manually)*

Updates current user information. You can use this method to update the user name, photo URL or any other information you want.

```swift
let user = VTUser(id: "111", name: "John", photoURL: "https://cdn.voxeet.com/images/team-benoit-senard.png")

VoxeetConferenceKit.shared.updateSession(user: user, completion: { (error) in
})
```

Or

```swift
VoxeetConferenceKit.shared.updateSession(userID: "123456789", userInfo: ["externalName": "John"], completion: { (error) in
})
```

### Closing a session *(manually)*

Closing a session is like a logout, it stops the socket and it also stops sending VoIP push notification.

```swift
VoxeetConferenceKit.shared.closeSession(completion: { (error) in
})
```

### Start conference

Starts the conference. As soon as this method is called, the voxeet conference UI is displayed.

```swift
VoxeetConferenceKit.shared.startConference(id: "conferenceID", success: { (json) in
}, fail: { (error) in
})
```

You can optionnally pass some users (they will appear in an inactive state if they haven't join the conference yet).
You can also update users later with `add`, `remove` and `update` methods.

If you have correctly generated a VoIP certificate and invite is true, it will ring through CallKit (above iOS 10) or with a classic VoIP push notification.

```swift
var users = [VTUser]()

users.append(VTUser(id: "111", name: "Benoit", photoURL: "https://cdn.voxeet.com/images/team-benoit-senard.png"))
users.append(VTUser(id: "222", name: "Stephane", photoURL: "https://cdn.voxeet.com/images/team-stephane-giraudie.png"))
users.append(VTUser(id: "333", name: "Thomas", photoURL: "https://cdn.voxeet.com/images/team-thomas.png"))

VoxeetConferenceKit.shared.startConference(id: "conferenceID", users: users, invite: true, success: { (json) in
}, fail: { (error) in
})
```

### Stop conference

Stops the current conference (leave and close voxeet conference UI).

```swift
VoxeetConferenceKit.shared.stopConference(completion: { (error) in
})
```

### Useful variables

Conference appear animation default starts maximized. If false, the conference will appear minimized.

```swift
VoxeetConferenceKit.shared.appearMaximized = false
```

The default behavior (false) start the conference on the built in receiver. If true, it will start on the built in speaker.

```swift
VoxeetConferenceKit.shared.defaultBuiltInSpeaker = true
```

Disable the screen automatic lock of the device if setted to false (if a camera is active, the screen won't go to sleep).

```swift
VoxeetConferenceKit.shared.screenAutoLock = false
```

### CallKit sound and image

If `CallKitSound.mp3` is overridden, the ringing sound will be your mp3 sound.
Same as `IconMask.png`, if overridden it will replace the CallKit default image by yours (40x40 px).

## Version

1.0.7

## Tech

The Voxeet iOS SDK and conference Kit use a number of open source projects to work properly:

* [Kingfisher](https://github.com/onevcat/Kingfisher) - Kingfisher is a lightweight, pure-Swift library for downloading and caching images from the web.
* [Starscream](https://github.com/daltoniam/Starscream) - Starscream is a conforming WebSocket (RFC 6455) client library in Swift for iOS and OSX.
* [Alamofire](https://github.com/Alamofire/Alamofire) - Alamofire is an HTTP networking library written in Swift.
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - SwiftyJSON makes it easy to deal with JSON data in Swift.
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - Crypto related functions and helpers for Swift implemented in Swift.

© Voxeet, 2017
