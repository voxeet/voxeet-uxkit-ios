# Voxeet Conference Kit

![Voxeet SDK logo](http://www.voxeet.com/wp-content/uploads/2016/05/SDK-API-768x180.png "Voxeet SDK logo")

The VoxeetConferenceKit is a Swift project allowing users to:

  - Launch a ready to go user interface
  - Customize the conference UI
  - Embed the [VoxeetSDK](https://github.com/voxeet/ios-sdk-sample)

## Table of contents

  1. [Requirements](#requirements)
  1. [Sample application](#sample-application)
  1. [Preparing your project](#preparing-your-project)
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

## Preparing your project

Before importing the VoxeetConferenceKit, you need to do some configurations:

Disable **Bitcode** in your Xcode target settings: 'Build Settings' -> 'Enable Bitcode' -> No

Enable **Background Modes**, go to your target settings -> 'Capabilities' -> 'Background Modes'
- Turn on 'Audio, AirPlay and Picture in Picture'  
- Turn on 'Voice over IP'

If you also want notifications:
- Turn on 'Background fetch'
- Turn on 'Remote notifications'

If you want notifications when the application is killed: (you will need to send your VoIP Services certificate to Voxeet in order to link it to your consumer key/secret)

Enable **Push Notifications**, go to your target settings -> 'Capabilities' -> 'Push Notifications'

![Capabilities](http://cdn.voxeet.com/images/VoxeetConferenceKitCapabilitiesXCode.png "Capabilities")

## Initializing the kit

    Voxeet can open you the entire VoxeetConferenceKit project if you want to have a full custom conference room.

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

And if you want to support notification add this extension to your AppDelegate:

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

Openning a session is like a login for a none voxeet user (or anonymous user). However the SDK needs to be initialized with `automaticallyOpenSession` set to `false`. By passing the user identifier, it will link and save your user into our server.

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.openSession(participant: participant, completion: { (error) in
})
```

You can also open a session with custom user information like this for example: ["externalName": "User", "externalPhotoUrl": "http://voxeet.com/voxeet-logo.jpg", "myCustomInfo": "test", ...].

```swift
VoxeetConferenceKit.shared.openSession(userID: "123456789", userInfo: ["externalName": "John Smith"], completion: { (error) in
})
```

### Update session

Update current user information. You can use this method to update the user name, avatar URL or any other information you want.

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

Closing a session is like a logout. It will stop the socket and stop sending you push notification.

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

Start the conference. As soon as this method is called, it opens the voxeet conference UI.

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

Stop the current conference (leave and close voxeet conference UI).

```swift
VoxeetConferenceKit.shared.stopConference()
```

### Participant management: Add

Add one participant to the conference (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.add(participant: participant)
```

### Participant management: Update

Update one/all participant(s) (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.update(participant: participant)
VoxeetConferenceKit.shared.update(participants: [participant])
```

### Participant management: Remove

Remove one participant to the conference (after starting a conference).

```swift
let participant = VoxeetParticipant(id: "123456789", name: "John Smith", avatarURL: URL(string: "https://www.test.com/my-image.png"))

VoxeetConferenceKit.shared.remove(participant: participant)
```

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