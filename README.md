# Voxeet Conference Kit

<p align="center">
<img src="http://www.voxeet.com/wp-content/uploads/2016/05/SDK-API-768x180.png" alt="Voxeet SDK logo" title="Voxeet SDK logo" width="700"/>
</p>

The VoxeetConferenceKit is a Swift project allowing users to:

  - Launch a ready to go user interface
  - Customize the conference UI
  - Embed the [VoxeetSDK](https://github.com/voxeet/ios-sdk-sample)

## Table of contents

  1. [Requirements](#requirements)
  1. [Sample application](#sample-application)
  1. [Project setup](#project-setup)
  1. [Initializing the kit](#initializing-the-kit)
  1. [Integrating to your project](#integrating-to-your-project)
  1. [VoxeetConferenceKit usage](#voxeetconferencekit-usage)

## Requirements

  - iOS 9+
  - Xcode 8+
  - Swift 3.1+

## Sample application

A sample application is available on this [public repository](https://github.com/voxeet/ios-conferencekit-sample/tree/master/Sample) on GitHub.

![CallKit](http://cdn.voxeet.com/images/IncomingCallKit.png "CallKit") ![Conference maximized](http://cdn.voxeet.com/images/OutgoingCall.png "Conference maximized") ![Conference minimized](http://cdn.voxeet.com/images/CallMinimize.png "Conference minimized")

## Project setup

Before importing the VoxeetConferenceKit, here is a few things to do:

Disable **Bitcode** in your Xcode target settings: 'Build Settings' -> 'Enable Bitcode' -> No

Enable **Background Modes**, go to your target settings -> 'Capabilities' -> 'Background Modes'
- Turn on 'Audio, AirPlay and Picture in Picture'  
- Turn on 'Voice over IP'

To enable notifications:
- Turn on 'Background fetch'
- Turn on 'Remote notifications'

To get notifications when the application is killed: (The VoIP Services certificate have to be uploaded to Voxeet in order to link it to your consumer key/secret)

Enable **Push Notifications**, go to your target settings -> 'Capabilities' -> 'Push Notifications'

![Capabilities](http://cdn.voxeet.com/images/VoxeetConferenceKitCapabilitiesXCode.png "Capabilities")

## Initializing the kit

**The VoxeetConferenceKit is Carthage compatible.**

    You can get access to the entire VoxeetConferenceKit project if you want to have a full custom conference room. Only thing to do is to request access by sending an email.

Once the repo is cloned, find the `VoxeetConferenceKit.framework` into the VoxeetConferenceKit folder.
Drag and drop it into your project, select 'Copy items if needed' with the right target.
Then in the general tab of your target, add the `VoxeetConferenceKit.framework` **AND** `VoxeetSDK.framework` into 'Embedded Binaries' and 'Linked Frameworks and Libraries'.

The kit is also using some external libraries like Kingfisher for downloading and caching images from the web (the avatars).
You can either download this framework at this link [Kingfisher](https://github.com/onevcat/Kingfisher) or install it with Carthage or CocoaPods.

![Frameworks](http://cdn.voxeet.com/images/XCodeFramework.png "Frameworks")

## Integrating to your project

In your `AppDelegate.swift` initialize the conference kit like this:

```swift
import VoxeetConferenceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialization of the Voxeet conference kit (open session later).
        VoxeetConferenceKit.shared.initialize(consumerKey: "consumerKey", consumerSecret: "consumerSecret", automaticallyOpenSession: false)
        
        return true
    }
}
```

To support notifications add this extension to your AppDelegate:

```swift
/*
 *  MARK: - Voxeet VoIP push notifications
 */

extension AppDelegate {
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        VoxeetConferenceKit.shared.application(application, didRegister: notificationSettings)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        VoxeetConferenceKit.shared.application(application, didReceive: notification)
    }
    
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

If you want to manage your user IDs, set automaticallyOpenSession to false. If true, the SDK will automatically manage your user (anonymously identified).

```swift
VoxeetConferenceKit.shared.initialize(consumerKey: "consumerKey", consumerSecret: "consumerSecret", automaticallyOpenSession: false)
```

### Open session

Opening a session is like a login for a non-voxeet user (or anonymous user). However the SDK needs to be initialized with `automaticallyOpenSession` set to `false`. By passing the user identifier, it will link and save your user into our server.

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.openSession(participant: participant, completion: { (error) in
})
```

It is also possible to open a session with custom user information like this for example: ["externalName": "User", "externalPhotoUrl": "http://voxeet.com/voxeet-logo.jpg", "myCustomInfo": "test", ...].

```swift
VoxeetConferenceKit.shared.openSession(userID: "123456789", userInfo: ["externalName": "John Smith"], completion: { (error) in
})
```

### Update session

Updates current user information. You can use this method to update the user name, avatar URL or any other information you want.

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Bis", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.updateSession(participant: participant, completion: { (error) in
})
```

Or

```swift
VoxeetConferenceKit.shared.updateSession(userID: "123456789", userInfo: ["externalName": "John Bis"], completion: { (error) in
})
```

### Close session

Closing a session is like a logout. It will close the socket and will no longer receive push notifications.

```swift
VoxeetConferenceKit.shared.closeSession(completion: { (error) in
})
```

### Initialize conference

Once the session is opened (automatically or manually) we can now initialized the conference.

You can optionnally set some participants, they will appear in an inactive state as long as they don't join the conference.
You can also update participants later with `add`, `remove` and `update` methods.

```swift
let participant1 = VoxeetParticipant(id: "11", name: "User 1", avatarURL: nil)
let participant2 = VoxeetParticipant(id: "22", name: "User 2", avatarURL: nil)

VoxeetConferenceKit.shared.initializeConference(id: "conferenceID", participants: [participant1, participant2])
```

### Start conference

Starts the conference. As soon as this method is called, the voxeet conference UI is displayed.

```swift
VoxeetConferenceKit.shared.startConference(success: { (confID) in
}, fail: { (error) in
})
```

You can also invite all participants previously initialized with sendInvitation set true. If you have correctly generated a VoIP certificate, it will ring through CallKit (above iOS 10) or with a classic VoIP push notification on the other hand.

```swift
VoxeetConferenceKit.shared.startConference(sendInvitation: true, success: { (confID) in
}, fail: { (error) in
})
```

### Stop conference

Stops the current conference (leave and close voxeet conference UI).

```swift
VoxeetConferenceKit.shared.stopConference()
```

### Participant management: Add

Adds one participant to the conference (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.add(participant: participant)
```

### Participant management: Update

Updates one/all participant(s) (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.update(participant: participant)
VoxeetConferenceKit.shared.update(participants: [participant])
```

### Participant management: Remove

Removes one participant from the conference (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.remove(participant: participant)
```

### Useful variables

Conference appear animation default starts maximized. If false, the conference will appear minimized.

```swift
VoxeetConferenceKit.shared.appearMaximized = false
```

The default behavior (true) start the conference on the built in speaker (main). If false, it will start on the built in receiver.

```swift
VoxeetConferenceKit.shared.defaultBuiltInSpeaker = false
```

Disable the screen automatic lock of the device if setted to false (in all case when the camera is activated, the screen can’t go to sleep).

```swift
VoxeetConferenceKit.shared.screenAutoLock = false
```

### CallKit sound and image

If `CallKitSound.mp3` is override, the ringing sound will be your mp3 sound.
Same as `IconMask.png`, if override it will replace the CallKit default one by your image (40x40 px).

## Version

1.0

## Tech

The Voxeet iOS SDK and Conference Kit use a number of open source projects to work properly:

* [Kingfisher](https://github.com/onevcat/Kingfisher) - Kingfisher is a lightweight, pure-Swift library for downloading and caching images from the web.
* [Starscream](https://github.com/daltoniam/Starscream) - Starscream is a conforming WebSocket (RFC 6455) client library in Swift for iOS and OSX.
* [Alamofire](https://github.com/Alamofire/Alamofire) - Alamofire is an HTTP networking library written in Swift.
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - SwiftyJSON makes it easy to deal with JSON data in Swift.
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - Crypto related functions and helpers for Swift implemented in Swift.

© Voxeet, 2017