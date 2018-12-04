//
//  VCKViewController.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import UIKit
import VoxeetSDK
import Kingfisher
import MediaPlayer

class VCKViewController: UIViewController {
    
    /* UI */
    
    @IBOutlet weak private var mainContainer: UIView!
    
    @IBOutlet weak var mainVideoRenderer: VTVideoView!
    @IBOutlet weak var ownVideoRenderer: VTVideoView!
    @IBOutlet weak private var screenShareVideoRenderer: VTVideoView!
    
    @IBOutlet weak private var conferenceTimerContainerView: UIView!
    @IBOutlet weak private var conferenceTimerLabel: UILabel!
    @IBOutlet weak var conferenceStateLabel: UILabel!
    
    @IBOutlet weak private var topView: UIView!
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var usersCollectionView: UICollectionView!
    
    @IBOutlet weak private var mainAvatarContainer: UIView!
    @IBOutlet weak private var mainAvatar: UIImageView!
    @IBOutlet weak private var voiceIndicatorConstraintLeading: NSLayoutConstraint!
    
    @IBOutlet weak var flipImage: UIImageView!
    
    @IBOutlet weak private var bottomContainerView: UIView!
    @IBOutlet weak private var microphoneButton: UIButton!
    @IBOutlet weak private var cameraButton: UIButton!
    @IBOutlet weak private var switchBuiltInSpeakerButton: UIButton!
    @IBOutlet weak private var screenShareButton: UIButton!
    @IBOutlet weak private var hangUpButton: UIButton!
    
    /* Stored */
    
    var mainUser: VTUser?
    var selectedUser: VTUser?
    var screenShareUserID: String?
    
    // Timers.
    var conferenceStartTimer: Timer?
    var activeSpeakerTimer: Timer?
    private var voiceLevelTimer: Timer?
    private var conferenceTimer: Timer?
    private var conferenceTimerStart: Date!
    private var conferenceTimerQueue = DispatchQueue(label: "com.voxeet.conferencekit.conferenceTimer", qos: .background, attributes: .concurrent)
    private var hangUpTimerCount: Int = 0
    private var hangUpTimer: Timer?
    
    // Sounds.
    var outgoingSound: AVAudioPlayer?
    private var hangUpSound: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VoxeetSDK.shared.conference.delegate = self
        
        // Initialization of all UI components.
        initUI()
        
        // Save when the user start the conference.
        conferenceTimerStart = Date()
        
        // Active speaker mode.
        resetActiveSpeakerTimer()
        // Voice level.
        voiceLevelTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refreshVoiceLevel), userInfo: nil, repeats: true)
        // Start the conference timer.
        conferenceTimerQueue.async { [unowned self] in
            // Start the conference timer.
            self.conferenceTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateConferenceTimer), userInfo: nil, repeats: true)
            let currentRunLoop = RunLoop.current
            currentRunLoop.add(self.conferenceTimer!, forMode: RunLoop.Mode.common)
            currentRunLoop.run()
        }
        
        // Own video renderer tap gesture.
        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCamera(recognizer:)))
        ownVideoRenderer.addGestureRecognizer(tap)
        // Main video renderer swipe gesture.
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(mainContainerPinchGesture(recognizer:)))
        mainVideoRenderer.addGestureRecognizer(pinch)
        
        // Sounds set up.
        if let outgoingSoundURL = Bundle(for: type(of: self)).url(forResource: "CallOutgoing", withExtension: "mp3") {
            outgoingSound = try? AVAudioPlayer(contentsOf: outgoingSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            outgoingSound?.numberOfLoops = 3
        }
        if let hangUpSoundURL = Bundle(for: type(of: self)).url(forResource: "CallHangUp", withExtension: "mp3") {
            hangUpSound = try? AVAudioPlayer(contentsOf: hangUpSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
        }
        
        // Hide switch speaker button on other device than iPhone.
        if UIDevice.current.userInterfaceIdiom != .phone {
            switchBuiltInSpeakerButton.isHidden = true
        }
        
        // Device orientation.
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        // Refresh users list to handle waiting room.
        NotificationCenter.default.addObserver(self, selector: #selector(participantAddedNotification), name: .VTParticipantAdded, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Checks microphone permission.
        VCKPermission.microphonePermission(controller: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop timers.
        conferenceStartTimer?.invalidate()
        activeSpeakerTimer?.invalidate()
        voiceLevelTimer?.invalidate()
        conferenceTimerQueue.sync { [unowned self] in
            self.conferenceTimer?.invalidate()
            self.conferenceTimer = nil
        }
        
        // Reset: Force the device screen to never going to sleep mode.
        UIApplication.shared.isIdleTimerDisabled = false
        // Reset: Proxymity sensor.
        UIDevice.current.isProximityMonitoringEnabled = false
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func initUI() {
        // Hide by default the main avatar, own camera (with flip image) & conference timer.
        mainAvatarContainer.alpha = 0
        ownVideoRenderer.alpha = 0
        flipImage.alpha = 0
        conferenceTimerContainerView.alpha = 0
        
        // Selfie camera is mirror by default.
        ownVideoRenderer.mirrorEffect = true
        
        // Default behavior to choose the internal or external speaker (UI update).
        if !VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
            switchBuiltInSpeakerAction()
        }
        
        // Default behavior to check if the video is enable by default.
        if VoxeetSDK.shared.conference.defaultVideo == true {
            cameraButton.tag = 1
            cameraButton.setImage(UIImage(named: "CameraOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        }
        
        // Desactivate the automatic screen lock of the device.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Hide screen share button for devices below iOS 11.
        if #available(iOS 11.0, *) {} else {
            screenShareButton.isHidden = true
        }
    }
    
    /*
     *  MARK: Maximize / minimize UI
     */
    
    func maximize(animated: Bool = true) {
        resizeTransitionUIAnimation(minimize: false, animated: animated)
        
        // Reset container corner radius.
        self.view.layer.cornerRadius = 0
        mainContainer.layer.cornerRadius = self.view.layer.cornerRadius
        
        // Reload collection view layout.
        usersCollectionView.reloadData()
    }
    
    func minimize(animated: Bool = true) {
        resizeTransitionUIAnimation(minimize: true, animated: animated)
        
        // Set container corner radius.
        self.view.layer.cornerRadius = 6
        mainContainer.layer.cornerRadius = self.view.layer.cornerRadius
    }
    
    private func resizeTransitionUIAnimation(minimize: Bool, animated: Bool) {
        // Update all UI components (with an animation or not).
        if animated {
            UIView.animate(withDuration: 0.20) {
                self.resizeTransitionUI(minimize: minimize)
            }
        } else {
            resizeTransitionUI(minimize: minimize)
        }
        
        // Update main avatar corner radius (with an animation or not).
        DispatchQueue.main.async {
            if animated {
                let mainAvatarAnimation = CABasicAnimation(keyPath: "cornerRadius")
                mainAvatarAnimation.duration = 0.20
                mainAvatarAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                mainAvatarAnimation.fromValue = self.mainAvatar.layer.cornerRadius
                mainAvatarAnimation.toValue = self.mainAvatar.frame.width / 2
                self.mainAvatar.layer.add(mainAvatarAnimation, forKey: "cornerRadius")
            }
            self.mainAvatar.layer.cornerRadius = self.mainAvatar.frame.width / 2
        }
    }
    
    private func resizeTransitionUI(minimize: Bool) {
        topView.alpha = minimize ? 0 : 1
        bottomContainerView.alpha = minimize ? 0 : 1
        conferenceTimerContainerView.alpha = minimize ? 1 : 0
        
        if cameraButton.tag != 0 {
            ownVideoRenderer.alpha = minimize ? 0 : 1
            flipImage.alpha = minimize ? 0 : 1
        }
    }
    
    /*
     *  MARK: Actions
     */
    
    @IBAction func minimizeAction(_ sender: Any) {
        VoxeetConferenceKit.shared.minimize()
    }
    
    @IBAction func microphoneAction(_ sender: Any) {
        if let userID = VoxeetSDK.shared.session.user?.id {
            let isMuted = VoxeetSDK.shared.conference.toggleMute(userID: userID)
            microphoneButton.setImage(UIImage(named: isMuted ? "MicrophoneOff" : "MicrophoneOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        }
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        VCKPermission.cameraPermission(controller: self) { granted in
            guard let userID = VoxeetSDK.shared.session.user?.id, granted else { return }
            
            if self.cameraButton.tag == 0 {
                self.cameraButton.tag = 1
                self.cameraButton.setImage(UIImage(named: "CameraOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                
                VoxeetSDK.shared.conference.startVideo(userID: userID)
            } else {
                self.cameraButton.tag = 0
                self.cameraButton.setImage(UIImage(named: "CameraOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                
                VoxeetSDK.shared.conference.stopVideo(userID: userID)
            }
        }
    }
    
    @IBAction func switchBuiltInSpeakerAction(_ sender: Any? = nil) {
        if switchBuiltInSpeakerButton.tag == 0 {
            switchBuiltInSpeakerButton.tag = 1
            switchBuiltInSpeakerButton.setImage(UIImage(named: "BuiltInSpeakerOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        } else {
            switchBuiltInSpeakerButton.tag = 0
            switchBuiltInSpeakerButton.setImage(UIImage(named: "BuiltInSpeakerOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        }
        
        // Switch device speaker and set the proximity sensor in line with the current speaker.
        UIDevice.current.isProximityMonitoringEnabled = switchBuiltInSpeakerButton.tag != 0
        VoxeetSDK.shared.conference.switchDeviceSpeaker(forceBuiltInSpeaker: switchBuiltInSpeakerButton.tag == 0)
    }
    
    @IBAction func screenShareAction(_ sender: Any) {
        guard screenShareUserID == nil || screenShareUserID == VoxeetSDK.shared.session.user?.id else {
            return
        }
        
        if #available(iOS 11.0, *) {
            if screenShareButton.tag == 0 {
                screenShareButton.tag = 1
                screenShareButton.setImage(UIImage(named: "ScreenShareOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                
                VoxeetSDK.shared.conference.startScreenShare { (error) in
                    if let _ = error {
                        self.screenShareButton.setImage(UIImage(named: "ScreenShareOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                        return
                    }
                }
            } else {
                screenShareButton.tag = 0
                screenShareButton.setImage(UIImage(named: "ScreenShareOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                
                VoxeetSDK.shared.conference.stopScreenShare { (error) in
                    if let _ = error {
                        return
                    }
                }
            }
        }
    }
    
    @IBAction func hangUpAction(_ sender: Any? = nil) {
        // Block hang up action if the hangUpTimer if currently active.
        guard hangUpTimer == nil else {
            return
        }
        
        // Hang up sound.
        hangUpSound?.play()
        
        // Block the hang up button.
        hangUpButton.isEnabled = false
        
        // Hide conference state before stopping the conference.
        conferenceStateLabel.isHidden = true
        conferenceStateLabel.text = nil
        
        // If the conference is not connected yet, retry the hang up action after few milliseconds to stop the conference.
        guard VoxeetSDK.shared.conference.state == .connected else {
            hangUpTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(hangUpRetry), userInfo: nil, repeats: true)
            return
        }
        VoxeetSDK.shared.conference.leave()
    }
    
    /*
     *  MARK: Gesture recognizers
     */
    
    @objc private func flipCamera(recognizer: UITapGestureRecognizer) {
        VoxeetSDK.shared.conference.flipCamera()
        
        flipImage.isHidden = true
        ownVideoRenderer.isUserInteractionEnabled = false
        
        // Apply a mirror effect to the own video renderer.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.38) {
            let mirrorEffectTransformation = self.ownVideoRenderer.layer.transform.m11 * -1
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
                self.ownVideoRenderer.transform = CGAffineTransform(scaleX: 1.2 * mirrorEffectTransformation, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.10, delay: 0, options: .curveEaseOut, animations: {
                    self.ownVideoRenderer.transform = CGAffineTransform(scaleX: 1 * mirrorEffectTransformation, y: 1)
                }) { _ in
                    self.flipImage.isHidden = false
                    self.ownVideoRenderer.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    @objc private func mainContainerPinchGesture(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .ended {
            // Main video view content fill/fit.
            mainVideoRenderer.contentFill = recognizer.scale > 1 ? true : false
            mainVideoRenderer.setNeedsLayout()
        }
    }
    
    /*
     *  MARK: Timers
     */
    
    @objc func conferenceStart() {
        // Register to audio route changing.
        if UIDevice.current.userInterfaceIdiom == .phone {
            NotificationCenter.default.addObserver(self, selector: #selector(self.audioSessionRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        }
        
        // Set minimum audio.
        if AVAudioSession.sharedInstance().outputVolume < 0.1 {
            MPVolumeView.setVolume(0.1)
        }
        
        // Play outgoing sound only if the caller didn't join the conference yet.
        if VoxeetSDK.shared.conference.users.filter({ $0.asStream }).isEmpty {
            // Play outgoing sound.
            outgoingSound?.play()
        }
    }
    
    @objc private func activeSpeaker() {
        var loudestUser: VTUser?
        var loudestVoiceLevel: Double = 0
        
        // Getting the loudest speaker.
        for user in VoxeetSDK.shared.conference.users.filter({ $0.asStream }) {
            if let userID = user.id {
                let currentVoiceLevel = VoxeetSDK.shared.conference.voiceLevel(userID: userID)
                
                if (mainUser == nil || currentVoiceLevel >= 0.01) && currentVoiceLevel >= loudestVoiceLevel {
                    loudestUser = user
                    loudestVoiceLevel = currentVoiceLevel
                }
            }
        }
        
        if let user = loudestUser {
            updateMainUser(user: user)
        }
    }
    
    @objc private func refreshVoiceLevel() {
        // Optimization: refresh the voice level only if the application is active and the proximity sensor in not active.
        if case UIApplication.shared.applicationState = UIApplication.State.active {} else {
            return
        }
        guard let userID = mainUser?.id, !UIDevice.current.proximityState else {
            return
        }
        
        let voiceLevel = VoxeetSDK.shared.conference.voiceLevel(userID: userID)
        
        if voiceLevel >= 0.01 { // Avoid useless animations.
            // y = ax + b.
            let a: CGFloat = (mainAvatar.frame.origin.x - 0) / (0 - 1)
            let b: CGFloat = mainAvatar.frame.origin.x - a * 0
            let x: CGFloat = CGFloat(voiceLevel)
            let y: CGFloat = a * x + b
            
            // Animate voice indicator.
            voiceIndicatorConstraintLeading.constant = y
            UIView.animate(withDuration: 0.1) {
                self.mainAvatarContainer.layoutIfNeeded()
            }
        } else {
            voiceIndicatorConstraintLeading.constant = mainAvatar.frame.origin.x
        }
    }
    
    @objc private func updateConferenceTimer() {
        let date = Date().timeIntervalSince(conferenceTimerStart)
        let hour = date / 3600
        let minute = (date / 60).truncatingRemainder(dividingBy: 60)
        let second = date.truncatingRemainder(dividingBy: 60)
        
        DispatchQueue.main.async {
            if hour >= 1 {
                self.conferenceTimerLabel.text = String(format: "%02.0f:%02.0f:%02.0f", floor(hour), floor(minute), floor(second))
            } else {
                self.conferenceTimerLabel.text = String(format: "%02.0f:%02.0f", floor(minute), floor(second))
            }
        }
    }
    
    @objc private func hangUpRetry() {
        guard hangUpTimerCount < 50 else {
            hangUpTimer?.invalidate()
            hangUpTimer = nil
            hangUpTimerCount = 0
            
            // Force leave.
            VoxeetSDK.shared.conference.leave { _ in
                VoxeetConferenceKit.shared.hide()
            }
            
            return
        }
        
        if VoxeetSDK.shared.conference.state == .connected {
            hangUpTimer?.invalidate()
            hangUpTimer = nil
            hangUpTimerCount = 0
            
            hangUpAction()
        } else {
            hangUpTimerCount += 1
        }
    }
    
    /*
     *  MARK: Timers helpers
     */
    
    func resetActiveSpeakerTimer() {
        activeSpeakerTimer?.invalidate()
        activeSpeakerTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(activeSpeaker), userInfo: nil, repeats: true)
        activeSpeakerTimer?.fire()
    }
    
    func updateMainUser(user: VTUser?) {
        let previousMainUser = mainUser
        
        mainUser = user
        if let photoURL = URL(string: user?.avatarURL ?? "") {
            mainAvatar.kf.setImage(with: photoURL)
        } else if user != nil {
            mainAvatar.image = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
        
        let userID = user?.id
        let stream = VoxeetSDK.shared.conference.mediaStream(userID: userID ?? "")
        let screenStream = VoxeetSDK.shared.conference.screenShareMediaStream()
        
        // Unattaching the old main stream.
        if let previousStream = VoxeetSDK.shared.conference.mediaStream(userID: previousMainUser?.id ?? ""), !previousStream.videoTracks.isEmpty && (previousMainUser?.id != userID || userID == screenShareUserID) {
            VoxeetSDK.shared.conference.unattachMediaStream(previousStream, renderer: mainVideoRenderer)
        }
        
        if !(stream?.videoTracks.isEmpty ?? true) || (!(screenStream?.videoTracks.isEmpty ?? true) && userID == screenShareUserID) {
            // Attaching the new one.
            if let screenStream = screenStream, userID == screenShareUserID {
                mainVideoRenderer.isHidden = true
                screenShareVideoRenderer.isHidden = false
                VoxeetSDK.shared.conference.attachMediaStream(screenStream, renderer: screenShareVideoRenderer)
            } else if let stream = stream {
                mainVideoRenderer.isHidden = false
                screenShareVideoRenderer.isHidden = true
                VoxeetSDK.shared.conference.attachMediaStream(stream, renderer: mainVideoRenderer)
            }
            
            // Update conferenceTimer view's background color.
            conferenceTimerContainerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            
            // Hide main avatar and stop voice level timer.
            voiceLevelTimer?.invalidate()
            mainAvatarContainer.alpha = 0
        } else {
            // Hide main video renderer & update the conferenceTimer view's background color.
            mainVideoRenderer.isHidden = true
            screenShareVideoRenderer.isHidden = true
            conferenceTimerContainerView.backgroundColor = UIColor.clear
            
            // Relaunch voice level timer.
            if user != nil && mainAvatarContainer.alpha == 0 {
                voiceLevelTimer?.invalidate()
                voiceLevelTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refreshVoiceLevel), userInfo: nil, repeats: true)
                voiceLevelTimer?.fire()
            }
            
            // Hide / unhide main avatar.
            if mainAvatarContainer.alpha != (user != nil ? 1 : 0) {
                UIView.animate(withDuration: 0.10, animations: {
                    self.mainAvatarContainer.alpha = user != nil ? 1 : 0
                })
            }
        }
    }
    
    /*
     *  MARK: Observer
     */
    
    @objc private func audioSessionRouteChange(notification: Notification) {
        // SwitchBuiltInSpeakerButton state.
        DispatchQueue.main.async {
            let output = AVAudioSession.sharedInstance().currentRoute.outputs.first
            if output?.portType == .builtInReceiver || output?.portType == .builtInSpeaker {
                self.switchBuiltInSpeakerButton.isEnabled = true
                
                if output?.portType == .builtInSpeaker {
                    self.switchBuiltInSpeakerButton.tag = 0
                    self.switchBuiltInSpeakerButton.setImage(UIImage(named: "BuiltInSpeakerOn", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                } else {
                    self.switchBuiltInSpeakerButton.tag = 1
                    self.switchBuiltInSpeakerButton.setImage(UIImage(named: "BuiltInSpeakerOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                }
            } else {
                self.switchBuiltInSpeakerButton.isEnabled = false
                self.switchBuiltInSpeakerButton.setImage(UIImage(named: "BuiltInSpeakerOff", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
            }
        }
    }
    
    @objc private func deviceOrientationDidChange(notification: Notification) {
        // Re-center cells.
        usersCollectionView.reloadData()
    }
    
    @objc private func participantAddedNotification(_ notification: Notification) {
        // Refresh invited users.
        usersCollectionView.reloadData()
        DispatchQueue.main.async {
            self.usersCollectionView.flashScrollIndicators()
        }
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
