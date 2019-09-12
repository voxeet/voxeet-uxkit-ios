//
//  ConferenceViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import VoxeetSDK
import Kingfisher
import MediaPlayer

/*
 *  MARK: - ConferenceViewController
 */

class ConferenceViewController: OverlayViewController {
    
    // MARK: UI properties
    
    @IBOutlet weak private var mainContainer: UIView!
    @IBOutlet weak private var filePresentationContainerView: UIView!
    @IBOutlet weak private var videoPresentationContainerView: UIView!
    
    @IBOutlet weak private var conferenceTimerContainerView: UIView!
    @IBOutlet weak private var conferenceTimerLabel: UILabel!
    
    @IBOutlet weak var minimizeButton: UIButton!
    
    @IBOutlet weak var conferenceStateLabel: UILabel!
    @IBOutlet weak private var conferenceStateLabelLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var ownVideoRenderer: VTVideoView!
    @IBOutlet weak var flipImage: UIImageView!
    
    // MARK: Stored properties
    
    // UX controllers components.
    var usersVC: VTUXUsersViewController!
    private var speakerVC: VTUXSpeakerViewController!
    var speakerVideoVC: VTUXSpeakerVideoViewController!
    private var speakerFilePresentationVC: VTUXSpeakerFilePresentationViewController!
    private var speakerVideoPresentationVC: VTUXSpeakerVideoPresentationViewController!
    var actionBarVC: VTUXActionBarViewController!
    
    // Active speaker updater.
    var activeSpeaker: VTUXActiveSpeakerTimer!
    
    // Conference states.
    private var presenterUserID: String?
    var speakerVideoContentFill = false
    var isMinimized = false
    
    // Conference timer.
    var conferenceStartTimer: Timer?
    private var conferenceTimer: Timer?
    private var conferenceTimerStart: Date!
    private let conferenceTimeInterval: TimeInterval = 1
    private let conferenceTimerQueue = DispatchQueue(label: "com.voxeet.uxkit.conferenceTimer", qos: .background, attributes: .concurrent)
    
    // Hang up timeout timer.
    private var hangUpTimerCount: Int = 0
    private var hangUpTimer: Timer?
    
    // Sounds.
    var outgoingSound: AVAudioPlayer?
    private var joinedSound: AVAudioPlayer?
    private var hangUpSound: AVAudioPlayer?
    
    // MARK: Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case is VTUXUsersViewController:
            usersVC = segue.destination as? VTUXUsersViewController
            usersVC.delegate = self
        case is VTUXSpeakerViewController:
            speakerVC = segue.destination as? VTUXSpeakerViewController
        case is VTUXSpeakerVideoViewController:
            speakerVideoVC = segue.destination as? VTUXSpeakerVideoViewController
        case is VTUXSpeakerFilePresentationViewController:
            speakerFilePresentationVC = segue.destination as? VTUXSpeakerFilePresentationViewController
            speakerFilePresentationVC.delegate = self
        case is VTUXSpeakerVideoPresentationViewController:
            speakerVideoPresentationVC = segue.destination as? VTUXSpeakerVideoPresentationViewController
            speakerVideoPresentationVC.delegate = self
        case is VTUXActionBarViewController:
            actionBarVC = segue.destination as? VTUXActionBarViewController
            actionBarVC.delegate = self
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VoxeetSDK.shared.conference.delegate = self
        
        // Initialization of all UI components.
        initUI()
        
        // Init active speaker switcher.
        activeSpeaker = VTUXActiveSpeakerTimer()
        activeSpeaker.delegate = self
        activeSpeaker.refresh()
        
        // Save when a user starts the conference.
        conferenceTimerStart = Date()
        // Start the conference timer.
        conferenceTimerQueue.async { [unowned self] in
            // Start the conference timer.
            self.conferenceTimer = Timer.scheduledTimer(timeInterval: self.conferenceTimeInterval, target: self, selector: #selector(self.updateConferenceTimer), userInfo: nil, repeats: true)
            let currentRunLoop = RunLoop.current
            currentRunLoop.add(self.conferenceTimer!, forMode: .common)
            currentRunLoop.run()
        }
        
        // Own video renderer tap gesture.
        let tap = UITapGestureRecognizer(target: self, action: #selector(switchCamera(recognizer:)))
        ownVideoRenderer.addGestureRecognizer(tap)
        
        // Sounds set up.
        if let outgoingSoundURL = Bundle(for: type(of: self)).url(forResource: "CallOutgoing", withExtension: "mp3") {
            outgoingSound = try? AVAudioPlayer(contentsOf: outgoingSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            outgoingSound?.numberOfLoops = -1
            if !VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
                outgoingSound?.prepareToPlay()
            }
        }
        if let joinedSoundURL = Bundle(for: type(of: self)).url(forResource: "CallJoined", withExtension: "mp3") {
            joinedSound = try? AVAudioPlayer(contentsOf: joinedSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            joinedSound?.volume = 0.4
            if VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
                joinedSound?.prepareToPlay()
            }
        }
        if let hangUpSoundURL = Bundle(for: type(of: self)).url(forResource: "CallHangUp", withExtension: "mp3") {
            hangUpSound = try? AVAudioPlayer(contentsOf: hangUpSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            hangUpSound?.volume = 0.4
            hangUpSound?.prepareToPlay()
        }
        
        // Refresh users list to handle waiting room observer.
        NotificationCenter.default.addObserver(self, selector: #selector(participantAddedNotification), name: .VTParticipantAdded, object: nil)
        // CallKit mute behaviour to update UI observer.
        NotificationCenter.default.addObserver(self, selector: #selector(callKitMuteToggled), name: .VTCallKitMuteToggled, object: nil)
        // Start / Stop video when application is on foreground/background.
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check microphone permission.
        Permissions.microphone(controller: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop timers.
        conferenceStartTimer?.invalidate()
        conferenceTimerQueue.sync { [unowned self] in
            self.conferenceTimer?.invalidate()
            self.conferenceTimer = nil
        }
        activeSpeaker.end()
        
        // Reset: Force the device screen to never going to sleep mode.
        UIApplication.shared.isIdleTimerDisabled = false
        // Reset: Proximity sensor.
        UIDevice.current.isProximityMonitoringEnabled = false
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func initUI() {
        // Hide by default minimized elements.
        alphaTransitionUI(minimized: false)
        
        // Disable buttons until the end of join process.
        actionBarVC.buttons(enabled: false)
        minimizeButton.isEnabled(false, animated: true)
        
        // Disable automatic screen lock.
        UIApplication.shared.isIdleTimerDisabled = true
        // Proximity sensor.
        if !VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
            UIDevice.current.isProximityMonitoringEnabled = true
        }
        
        // Conference timer's shadow.
        conferenceTimerLabel.layer.shadowOpacity = 0.1
        conferenceTimerLabel.layer.shadowRadius = 3
        conferenceTimerLabel.layer.shadowOffset = CGSize(width: -2, height: 0)
        conferenceTimerLabel.layer.shadowPath = UIBezierPath(rect: conferenceTimerLabel.bounds).cgPath
        
        // Minimize button.
        let overlayConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.overlay
        if overlayConfiguration?.displayAction ?? false {
            // Init users collection view edge insets.
            usersVC.edgeInsets = UIEdgeInsets(top: 0, left: minimizeButton.frame.width, bottom: 0, right: 0)
            
            // Minimize button's shadow (not optimized).
            minimizeButton.layer.shadowOpacity = 0.25
            minimizeButton.layer.shadowRadius = 2
            minimizeButton.layer.shadowOffset = CGSize.zero
        } else {
            minimizeButton.isHidden = true
        }
        
        // Hide UX modules.
        speakerVC.view.isHidden = true
        speakerVideoVC.view.isHidden = true
        filePresentationContainerView.isHidden = true
        videoPresentationContainerView.isHidden = true
    }
    
    func updateConferenceState(_ state: VTConferenceState) {
        switch state {
        case .connecting:
            // Update conference state label.
            conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_CALLING")
            conferenceStateLabel.alpha = 0
            conferenceStateLabel.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.conferenceStateLabel.alpha = 1
            }
        case .connected:
            actionBarVC.buttons(enabled: true)
            minimizeButton.isEnabled(true, animated: true)
        case .disconnecting:
            // Stop active speaker.
            activeSpeaker.end()
            
            // Update conference state label.
            if conferenceStateLabel.text == nil {
                conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_ENDED")
            }
            conferenceStateLabel.isHidden = false
            
            // Disable buttons when leaving.
            actionBarVC.buttons(enabled: false)
            minimizeButton.isEnabled(false, animated: true)
            
            // Hide main speaker and collection view.
            usersVC.view.isHidden = true
            speakerVC.view.isHidden = true
            speakerVideoVC.view.isHidden = true
            filePresentationContainerView.isHidden = true
            videoPresentationContainerView.isHidden = true
            
            // Stop outgoing sounds if they were started.
            outgoingSound?.stop()
            outgoingSound = nil
            joinedSound?.stop()
            joinedSound = nil
        case .disconnected:
            break
        }
    }
    
    func startPresentation(user: VTUser?) {
        // Stop active speaker and lock current user.
        presenterUserID = user?.id
        usersVC.lock(user: user)
        activeSpeaker.end()
        
        // Disable screen share button.
        actionBarVC.screenShareButton(state: .on)
        actionBarVC.screenShareButton.isEnabled(false, animated: true)
    }
    
    func stopPresentation() {
        // Reset active speaker and unlock previous user.
        presenterUserID = nil
        usersVC.lock(user: nil)
        activeSpeaker.begin()
        activeSpeaker.refresh()
        
        // Enable screen share button.
        actionBarVC.screenShareButton(state: .off)
        actionBarVC.screenShareButton.isEnabled(true, animated: true)
    }
    
    /*
     *  MARK: Gesture recognizers
     */
    
    @IBAction func minimizeAction(_ sender: Any) {
        minimize()
    }
    
    override func tapGesture(recognizer: UITapGestureRecognizer) {
        super.tapGesture(recognizer: recognizer)
        resizeTransitionUI(minimized: false, animated: true)
        
        // Reset container corner radius.
        view.layer.cornerRadius = 0
        mainContainer.layer.cornerRadius = view.layer.cornerRadius
        
        // Reload collection view layout.
        usersVC.reload()
    }
    
    @objc private func switchCamera(recognizer: UITapGestureRecognizer) {
        let mirrorEffectTransformation = self.ownVideoRenderer.layer.transform.m11 * -1
        flipImage.isHidden = true
        ownVideoRenderer.isUserInteractionEnabled = false
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
        
        ownVideoRenderer.subviews.first?.alpha = 0
        VoxeetSDK.shared.conference.switchCamera {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.10, animations: {
                    self.ownVideoRenderer.subviews.first?.alpha = 1
                })
            }
        }
    }
    
    /*
     *  MARK: Minimize / Maximize UI updates
     */
    
    func minimize(animated: Bool = true) {
        super.minimize(animated: animated)
        resizeTransitionUI(minimized: true, animated: animated)
        
        // Set container corner radius.
        view.layer.cornerRadius = 6
        mainContainer.layer.cornerRadius = view.layer.cornerRadius
    }
    
    private func resizeTransitionUI(minimized: Bool, animated: Bool) {
        let animationDuration = 0.125
        isMinimized = minimized
        
        // Update all UI components (with an animation or not).
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.alphaTransitionUI(minimized: minimized)
            }
        } else {
            alphaTransitionUI(minimized: minimized)
        }
        conferenceStateLabelLeadingConstraint.constant = minimized ? 8 : 16
        
        // Enable / Disable gesture recognizer to not override minimize tap event.
        speakerVideoVC.view.isUserInteractionEnabled = !minimized
    }
    
    private func alphaTransitionUI(minimized: Bool) {
        conferenceTimerContainerView.alpha = minimized ? 1 : 0
        minimizeButton.alpha = minimized ? 0 : 1
        usersVC.view.alpha = minimized ? 0 : 1
        actionBarVC.view.alpha = minimized ? 0 : 1
        
        let conferenceService = VoxeetSDK.shared.conference
        if actionBarVC.cameraButton.tag != 0 && !conferenceService.users.filter({ $0.hasStream }).isEmpty {
            ownVideoRenderer.alpha = minimized ? 0 : 1
            flipImage.alpha = minimized ? 0 : 1
        } else {
            ownVideoRenderer.alpha = 0
            flipImage.alpha = 0
        }
    }
    
    /*
     *  MARK: Timers
     */
    
    @objc func conferenceStarted() {
        // Register to audio route changing.
        if UIDevice.current.userInterfaceIdiom == .phone {
            NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
            
            // Update audio button.
            audioSessionRouteChange()
        }
        
        // Play joined/outgoing sound only if the caller didn't join the conference yet.
        if VoxeetSDK.shared.conference.users.filter({ $0.hasStream }).isEmpty {
            if VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
                joinedSound?.play()
            } else {
                outgoingSound?.play()
            }
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
                super.hide()
            }
            
            return
        }
        
        if VoxeetSDK.shared.conference.state == .connected {
            hangUpTimer?.invalidate()
            hangUpTimer = nil
            hangUpTimerCount = 0
            
            leaveAction()
        } else {
            hangUpTimerCount += 1
        }
    }
    
    /*
     *  MARK: Observers
     */
    
    @objc func audioSessionRouteChange() {
        // Update `speakerButton` state.
        DispatchQueue.main.async {
            // Check if the button is available before updating it.
            if self.actionBarVC.speakerButton.isUserInteractionEnabled == false { return }
            
            // Check current audio route to update UI.
            let output = AVAudioSession.sharedInstance().currentRoute.outputs.first
            if output?.portType == .builtInReceiver || output?.portType == .builtInSpeaker {
                self.actionBarVC.speakerButton.isEnabled(true, animated: true)
                
                if output?.portType == .builtInSpeaker {
                    self.actionBarVC.speakerButton(state: .on)
                    UIDevice.current.isProximityMonitoringEnabled = false
                } else {
                    self.actionBarVC.speakerButton(state: .off)
                    UIDevice.current.isProximityMonitoringEnabled = true
                }
            } else {
                self.actionBarVC.speakerButton.isEnabled(false, animated: true)
                self.actionBarVC.speakerButton(state: .off)
                UIDevice.current.isProximityMonitoringEnabled = false
            }
        }
    }
    
    @objc private func participantAddedNotification(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        let json = try? JSONSerialization.jsonObject(with: userInfo, options: .mutableContainers) as? [String: Any]
        
        if let userID = json?["user_id"] as? String, let user = VoxeetSDK.shared.conference.user(userID: userID) {
            let usersConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.users
            if user.status == .reserved || (usersConfiguration?.displayLeftUsers ?? false) { /* Only show invited users */
                usersVC.append(user: user)
            }
        }
    }
    
    @objc private func callKitMuteToggled(notification: NSNotification) {
        guard let isMuted = notification.userInfo?["mute"] as? Bool else { return }
        actionBarVC.muteButton(state: isMuted ? .on : .off)
    }
    
    @objc private func willEnterForegroundNotification() {
        // Unpause current camera.
        if actionBarVC.cameraButton.tag == 1 {
            let isFrontCamera = VoxeetSDK.shared.conference.isFrontCamera
            actionBarVC.cameraButton.isUserInteractionEnabled = false
            VoxeetSDK.shared.conference.startVideo(isDefaultFrontFacing: isFrontCamera) { _ in
                self.actionBarVC.cameraButton.isUserInteractionEnabled = true
            }
        }
        
        //        // Unpause current screen share.
        //        if #available(iOS 11.0, *), actionBarVC.screenShareButton.tag == 1 {
        //            actionBarVC.screenShareButton.isUserInteractionEnabled = false
        //            VoxeetSDK.shared.conference.startScreenShare { _ in
        //                self.actionBarVC.screenShareButton.isUserInteractionEnabled = true
        //            }
        //        }
    }
    
    @objc private func didEnterBackgroundNotification() {
        // Pause current camera.
        if actionBarVC.cameraButton.tag == 1 {
            actionBarVC.cameraButton.isUserInteractionEnabled = false
            VoxeetSDK.shared.conference.stopVideo { _ in
                self.actionBarVC.cameraButton.isUserInteractionEnabled = true
            }
        }
        
        //        // Pause current screen share.
        //        if #available(iOS 11.0, *), actionBarVC.screenShareButton.tag == 1 {
        //            actionBarVC.screenShareButton.isUserInteractionEnabled = false
        //            VoxeetSDK.shared.conference.stopScreenShare { _ in
        //                self.actionBarVC.screenShareButton.isUserInteractionEnabled = true
        //            }
        //        }
    }
}

/*
 *  MARK: - VTUXActiveSpeakerTimerDelegate
 */

extension ConferenceViewController: VTUXActiveSpeakerTimerDelegate {
    func activeSpeakerUpdated(user: VTUser?) {
        guard presenterUserID == nil else { return }
        guard let user = user, let userID = user.id else {
            speakerVideoVC.view.isHidden = true
            speakerVC.view.isHidden = true
            
            // Own video full screen.
            if let sessionUserID = VoxeetSDK.shared.session.user?.id, let stream = VoxeetSDK.shared.conference.mediaStream(userID: sessionUserID), !stream.videoTracks.isEmpty {
                speakerVideoVC.attach(userID: sessionUserID, stream: stream)
                speakerVideoVC.view.isHidden = false
            } else {
                speakerVideoVC.view.isHidden = true
            }
            
            return
        }
        
        let stream = VoxeetSDK.shared.conference.mediaStream(userID: userID)
        if let stream = stream, !stream.videoTracks.isEmpty {
            speakerVideoVC.attach(userID: userID, stream: stream)
            
            speakerVideoVC.view.isHidden = false
            speakerVC.view.isHidden = true
        } else {
            speakerVideoVC.unattach()
            speakerVC.updateSpeaker(user: user)
            
            speakerVideoVC.view.isHidden = true
            speakerVC.view.isHidden = false
        }
    }
}

/*
 *  MARK: - VTUXUsersViewControllerDelegate
 */

extension ConferenceViewController: VTUXUsersViewControllerDelegate {
    func selectedUserUpdated(user: VTUser?) {
        guard presenterUserID == nil else { return }
        activeSpeaker.lock(user: user)
    }
}

/*
 *  MARK: - VTUXActionBarViewControllerDelegate
 */

extension ConferenceViewController: VTUXActionBarViewControllerDelegate {
    func muteAction() {
        if let userID = VoxeetSDK.shared.session.user?.id {
            let isMuted = VoxeetSDK.shared.conference.toggleMute(userID: userID)
            actionBarVC.muteButton(state: isMuted ? .on : .off)
        }
    }
    
    func cameraAction() {
        Permissions.camera(controller: self) { granted in
            guard granted else { return }
            
            if self.actionBarVC.cameraButton.tag == 0 {
                self.actionBarVC.cameraButton(state: .on)
                self.actionBarVC.cameraButton.isUserInteractionEnabled = false
                VoxeetSDK.shared.conference.startVideo { error in
                    self.actionBarVC.cameraButton.isUserInteractionEnabled = true
                }
                
                // Switch to the built in speaker when video starts.
                if self.actionBarVC.speakerButton.tag == 0 {
                    self.switchDeviceSpeakerAction()
                }
            } else {
                self.actionBarVC.cameraButton(state: .off)
                self.actionBarVC.cameraButton.isUserInteractionEnabled = false
                VoxeetSDK.shared.conference.stopVideo { error in
                    self.actionBarVC.cameraButton.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    func switchDeviceSpeakerAction() {
        actionBarVC.speakerButton(state: actionBarVC.speakerButton.tag == 0 ? .on : .off)
        
        // Switch device speaker and set the proximity sensor in line with the current speaker.
        let builtInSpeaker = actionBarVC.speakerButton.tag != 0
        UIDevice.current.isProximityMonitoringEnabled = !builtInSpeaker
        actionBarVC.speakerButton.isUserInteractionEnabled = false
        VoxeetSDK.shared.conference.switchDeviceSpeaker(forceBuiltInSpeaker: builtInSpeaker) {
            self.actionBarVC.speakerButton.isUserInteractionEnabled = true
        }
    }
    
    func screenShareAction() {
        guard presenterUserID == nil || presenterUserID == VoxeetSDK.shared.session.user?.id else {
            return
        }
        
        if #available(iOS 11.0, *) {
            if actionBarVC.screenShareButton.tag == 0 {
                actionBarVC.screenShareButton(state: .on)
                
                VoxeetSDK.shared.conference.startScreenShare { error in
                    if let _ = error {
                        self.actionBarVC.screenShareButton(state: .off)
                        return
                    }
                }
            } else {
                actionBarVC.screenShareButton(state: .off)
                VoxeetSDK.shared.conference.stopScreenShare { error in
                    if let _ = error {
                        return
                    }
                }
            }
        }
    }
    
    func leaveAction() {
        // Block hang up action if the hangUpTimer if currently active.
        guard hangUpTimer == nil else { return }
        
        // Hang up sound.
        hangUpSound?.play()
        
        // Remove audio observer to desactivate speakerButton behaviour.
        conferenceStartTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        // Reset conference state to `disconnecting` and update UI.
        conferenceStateLabel.text = nil
        updateConferenceState(.disconnecting)
        // Hide own video renderer.
        if actionBarVC.cameraButton.tag != 0 {
            ownVideoRenderer.alpha = 0
            flipImage.alpha = ownVideoRenderer.alpha
        }
        
        // If the conference isn't connected yet, retry the hang up action after few milliseconds to stop the conference.
        guard VoxeetSDK.shared.conference.state == .connected else {
            hangUpTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(hangUpRetry), userInfo: nil, repeats: true)
            return
        }
        
        // Leave conference (monkey patch to play sound on the same audio route).
        if let userID = VoxeetSDK.shared.session.user?.id {
            NotificationCenter.default.removeObserver(self, name: .VTCallKitMuteToggled, object: nil)
            VoxeetSDK.shared.conference.mute(userID: userID, isMuted: true)
        }
        VoxeetSDK.shared.conference.stopVideo()
        let leaveTimeout = hangUpSound?.duration ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + (leaveTimeout < 1 ? leaveTimeout : 1)) {
            VoxeetSDK.shared.conference.leave()
        }
    }
}

/*
 *  MARK: - VTUXSpeakerFilePresentationViewControllerDelegate
 */

extension ConferenceViewController: VTUXSpeakerFilePresentationViewControllerDelegate {
    func filePresentationStarted(user: VTUser?) {
        filePresentationContainerView.isHidden = false
        startPresentation(user: user)
    }
    
    func filePresentationStopped() {
        filePresentationContainerView.isHidden = true
        stopPresentation()
    }
}

/*
 *  MARK: - VTUXSpeakerVideoPresentationViewControllerDelegate
 */

extension ConferenceViewController: VTUXSpeakerVideoPresentationViewControllerDelegate {
    func videoPresentationStarted(user: VTUser?) {
        videoPresentationContainerView.isHidden = false
        startPresentation(user: user)
    }
    
    func videoPresentationStopped() {
        videoPresentationContainerView.isHidden = true
        stopPresentation()
    }
}
