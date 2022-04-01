//
//  ConferenceViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import VoxeetSDK
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
    var participantsVC: VTUXParticipantsViewController!
    private var speakerVC: VTUXSpeakerViewController!
    var speakerVideoVC: VTUXSpeakerVideoViewController!
    private var speakerFilePresentationVC: VTUXSpeakerFilePresentationViewController!
    private var speakerVideoPresentationVC: VTUXSpeakerVideoPresentationViewController!
    var actionBarVC: VTUXActionBarViewController!
    
    // Active speaker updater.
    var activeSpeaker: VTUXActiveSpeakerTimer!
    
    // Conference states.
    var presenterID: String?
    var speakerVideoContentFill = false
    var isMinimized = false
    var audioPermissionInitiate = false
    
    // Conference timer.
    var conferenceStartTimer: Timer?
    private var conferenceTimer: Timer?
    private var conferenceTimerStart: Date!
    private let conferenceTimeInterval: TimeInterval = 1
    
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
        case is VTUXParticipantsViewController:
            participantsVC = segue.destination as? VTUXParticipantsViewController
            participantsVC.delegate = self
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
        
        // Save date when a participant starts the conference.
        conferenceTimerStart = Date()
        // Start the conference timer.
        conferenceTimer = Timer(timeInterval: conferenceTimeInterval, target: self, selector: #selector(updateConferenceTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(conferenceTimer!, forMode: .common)
        
        // Own video renderer tap gesture.
        let tap = UITapGestureRecognizer(target: self, action: #selector(switchCamera(recognizer:)))
        ownVideoRenderer.addGestureRecognizer(tap)
        
        // Sounds set up.
        if let outgoingSoundURL = Bundle.module.url(forResource: "CallOutgoing", withExtension: "mp3") {
            outgoingSound = try? AVAudioPlayer(contentsOf: outgoingSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            outgoingSound?.numberOfLoops = -1
            if !VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
                outgoingSound?.prepareToPlay()
            }
        }
        if let joinedSoundURL = Bundle.module.url(forResource: "CallJoined", withExtension: "mp3") {
            joinedSound = try? AVAudioPlayer(contentsOf: joinedSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            joinedSound?.volume = 0.4
            if VoxeetSDK.shared.conference.defaultBuiltInSpeaker {
                joinedSound?.prepareToPlay()
            }
        }
        if let hangUpSoundURL = Bundle.module.url(forResource: "CallHangUp", withExtension: "mp3") {
            hangUpSound = try? AVAudioPlayer(contentsOf: hangUpSoundURL, fileTypeHint: AVFileType.mp3.rawValue)
            hangUpSound?.volume = 0.4
            hangUpSound?.prepareToPlay()
        }
        
        // Observer CallKit mute behaviour to update UI.
        NotificationCenter.default.addObserver(self, selector: #selector(callKitMuteToggled), name: .VTCallKitMuteToggled, object: nil)
        // Start / Stop video when application is on foreground/background.
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop timers.
        conferenceStartTimer?.invalidate()
        conferenceTimer?.invalidate()
        activeSpeaker.end()
        
        // Reset: Force the device screen to never going to sleep mode.
        UIApplication.shared.isIdleTimerDisabled = false
        // Reset: Proximity sensor.
        UIDevice.current.isProximityMonitoringEnabled = false
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func initUI() {
        let overlayConfig = VoxeetUXKit.shared.conferenceController?.configuration.overlay
        
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
        
        // Conference timer background color.
        let backgroundMinimizedColor = overlayConfig?.backgroundMinimizedColor ?? .black
        conferenceTimerContainerView.backgroundColor = backgroundMinimizedColor.withAlphaComponent(0.5)
        // Shadow of conference timer.
        conferenceTimerLabel.layer.shadowOpacity = 0.1
        conferenceTimerLabel.layer.shadowRadius = 3
        conferenceTimerLabel.layer.shadowOffset = CGSize(width: -2, height: 0)
        conferenceTimerLabel.layer.shadowPath = UIBezierPath(rect: conferenceTimerLabel.bounds).cgPath
        
        // Minimize button.
        if overlayConfig?.displayAction ?? false {
            // Init participants collection view edge insets.
            participantsVC.edgeInsets = UIEdgeInsets(top: 0, left: minimizeButton.frame.width, bottom: 0, right: 0)
            
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
    
    func updateConferenceStatus(_ status: VTConferenceStatus) {
        switch status {
        case .creating:
            // Update conference state label.
            conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_CALLING")
            conferenceStateLabel.alpha = 0
            conferenceStateLabel.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.conferenceStateLabel.alpha = 1
            }
        case .joined:
            // Update conference state label.
            conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_CALLING")
            
            // Enable conference buttons.
            actionBarVC.buttons(enabled: true)
            if let permissions = VoxeetSDK.shared.conference.current?.permissions {
                permissionsUpdated(permissions: permissions.map { $0.rawValue })
            }
            minimizeButton.isEnabled(true, animated: true)
            
            // Check microphone permission.
            if VoxeetSDK.shared.conference.mode == .standard {
                Permissions.microphone(viewController: self)
            }
        case .leaving:
            // Stop active speaker.
            activeSpeaker.end()
            
            // Update conference state label.
            if conferenceStateLabel.text == nil {
                conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_ENDED")
            }
            conferenceStateLabel.isHidden = false
            
            // Disable conference buttons.
            actionBarVC.buttons(enabled: false)
            minimizeButton.isEnabled(false, animated: true)
            
            // Hide main speaker and collection view.
            participantsVC.view.isHidden = true
            speakerVC.view.isHidden = true
            speakerVideoVC.view.isHidden = true
            filePresentationContainerView.isHidden = true
            videoPresentationContainerView.isHidden = true
            
            // Stop all sounds if they were started.
            // All AVPlayers have to be stopped before call to VoxeetSDK.shared.conference.leave().
            outgoingSound?.stop()
            outgoingSound = nil
            joinedSound?.stop()
            joinedSound = nil
            hangUpSound?.stop()
            hangUpSound = nil
        default: break
        }
    }
    
    func activeParticipants() -> [VTParticipant] {
        let participants = VoxeetSDK.shared.conference.current?.participants
            .filter({ $0.id != VoxeetSDK.shared.session.participant?.id })
            .filter({ $0.type == .user && $0.status == .connected })
        return participants ?? [VTParticipant]()
    }
    
    func startPresentation(participant: VTParticipant?) {
        // Stop active speaker and lock current participant.
        presenterID = participant?.id
        participantsVC.lock(participant: participant)
        activeSpeaker.end()
        
        // Disable screen share button.
        actionBarVC.screenShareButton(state: .on)
        actionBarVC.screenShareButton.isEnabled(false, animated: true)
    }
    
    func stopPresentation() {
        // Reset active speaker and unlock previous participant.
        presenterID = nil
        participantsVC.lock(participant: nil)
        activeSpeaker.begin()
        activeSpeaker.refresh()
        
        // Enable screen share button.
        actionBarVC.screenShareButton(state: .off)
        actionBarVC.screenShareButton.isEnabled(true, animated: true)
    }
    
    /*
     *  MARK: Gesture recognizers
     */
    
    override func tapGesture(recognizer: UITapGestureRecognizer) {
        maximize()
    }
    
    @IBAction private func minimizeAction(_ sender: Any) {
        minimize()
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
        VoxeetSDK.shared.mediaDevice.switchCamera {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.10, animations: {
                    self.ownVideoRenderer.subviews.first?.alpha = 1
                })
            }
        }
    }
    
    /*
     *  MARK: Maximize / Minimize UI updates
     */
    
    func maximize(animated: Bool = true) {
        super.maximize(animated: animated)
        resizeTransitionUI(minimized: false, animated: animated)
        
        // Reset container corner radius.
        view.layer.cornerRadius = 0
        mainContainer.layer.cornerRadius = view.layer.cornerRadius
        
        // Reload collection view layout.
        participantsVC.reload()
    }
    
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
        participantsVC.view.alpha = minimized ? 0 : 1
        actionBarVC.view.alpha = minimized ? 0 : 1
        
        if actionBarVC.cameraButton.tag != 0 && !activeParticipants().isEmpty {
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
        if activeParticipants().isEmpty {
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
                // Close conference UI.
                NotificationCenter.default.post(name: .VTConferenceStatusUpdated, object: nil, userInfo: ["status": VTConferenceStatus.error.rawValue])
            }
            
            return
        }
        
        if VoxeetSDK.shared.conference.current?.status == .joined {
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
                if output?.portType == .headphones {
                    self.actionBarVC.speakerButtonHeadphonesState()
                } else if output?.portType == .bluetoothA2DP || output?.portType == .bluetoothLE || output?.portType == .bluetoothHFP {
                    self.actionBarVC.speakerButtonBluetoothState()
                } else {
                    self.actionBarVC.speakerButton(state: .off)
                }
                UIDevice.current.isProximityMonitoringEnabled = false
            }
        }
    }
    
    @objc private func callKitMuteToggled(notification: NSNotification) {
        guard let isMuted = notification.userInfo?["mute"] as? Bool else { return }
        actionBarVC.muteButton(state: isMuted ? .on : .off)
    }
    
    @objc private func willEnterForegroundNotification() {
        // Unpause current camera.
        if actionBarVC.cameraButton.tag == 2 {
            let isFrontCamera = VoxeetSDK.shared.mediaDevice.isFrontCamera
            VoxeetSDK.shared.conference.startVideo(isDefaultFrontFacing: isFrontCamera) { _ in
                self.actionBarVC.cameraButton.isUserInteractionEnabled = true
            }
        } else {
            actionBarVC.cameraButton.isUserInteractionEnabled = true
        }
        
        // Unpause current screen share.
        let broadcast = VoxeetSDK.shared.appGroup != nil
        if #available(iOS 11.0, *), !broadcast {
            if actionBarVC.screenShareButton.tag == 2 {
                actionBarVC.screenShareButton.tag = 1
                VoxeetSDK.shared.conference.startScreenShare { err in
                    self.actionBarVC.screenShareButton.isUserInteractionEnabled = true
                }
            } else {
                actionBarVC.screenShareButton.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc private func didEnterBackgroundNotification() {
        // Pause current camera.
        let sessionParticipant = VoxeetSDK.shared.session.participant
        let cameraStream = sessionParticipant?.streams.first(where: { $0.type == .Camera })
        if !(cameraStream?.videoTracks.isEmpty ?? true) {
            actionBarVC.cameraButton.tag = 2
            actionBarVC.cameraButton.isUserInteractionEnabled = false
            VoxeetSDK.shared.conference.stopVideo { err in
                if err != nil {
                    self.actionBarVC.cameraButton.isUserInteractionEnabled = true
                }
            }
        }
        
        // Pause current screen share if broadcast is false (app group not set).
        let broadcast = VoxeetSDK.shared.appGroup != nil
        let screenShareStream = sessionParticipant?.streams.first(where: { $0.type == .ScreenShare })
        if #available(iOS 11.0, *), !(screenShareStream?.videoTracks.isEmpty ?? true) && !broadcast {
            actionBarVC.screenShareButton.tag = 2
            actionBarVC.screenShareButton.isUserInteractionEnabled = false
            VoxeetSDK.shared.conference.stopScreenShare { err in
                if err != nil {
                    self.actionBarVC.screenShareButton.isUserInteractionEnabled = true
                }
            }
        }
    }
}

/*
 *  MARK: - VTUXActiveSpeakerTimerDelegate
 */

extension ConferenceViewController: VTUXActiveSpeakerTimerDelegate {
    func activeSpeakerUpdated(participant: VTParticipant?) {
        guard presenterID == nil else { return }
        guard let participant = participant else {
            speakerVideoVC.view.isHidden = true
            speakerVC.view.isHidden = true
            
            // Own video full screen.
            let participant = VoxeetSDK.shared.session.participant
            let stream = participant?.streams.first(where: { $0.type == .Camera })
            if let participant = participant, let stream = stream, !stream.videoTracks.isEmpty {
                speakerVideoVC.attach(participant: participant, stream: stream)
                speakerVideoVC.view.isHidden = false
            } else {
                speakerVideoVC.view.isHidden = true
            }
            
            return
        }
        
        // Attach / Unattach video stream.
        let stream = participant.streams.first(where: { $0.type == .Camera })
        if let stream = stream, !stream.videoTracks.isEmpty {
            speakerVideoVC.attach(participant: participant, stream: stream)
            
            speakerVideoVC.view.isHidden = false
            speakerVC.view.isHidden = true
        } else {
            speakerVideoVC.unattach()
            speakerVC.updateSpeaker(participant: participant)
            
            speakerVideoVC.view.isHidden = true
            speakerVC.view.isHidden = false
        }
    }
}

/*
 *  MARK: - VTUXParticipantsViewControllerDelegate
 */

extension ConferenceViewController: VTUXParticipantsViewControllerDelegate {
    func updated(participant: VTParticipant?) {
        guard presenterID == nil else { return }
        activeSpeaker.lock(participant: participant)
    }
}

/*
 *  MARK: - VTUXActionBarViewControllerDelegate
 */

extension ConferenceViewController: VTUXActionBarViewControllerDelegate {
    func muteAction() {
        let isMuted = actionBarVC.muteButton.tag == 0
        
        // Enable / Disable mute button.
        actionBarVC.muteButton(state: isMuted ? .on : .off)
        
        // Unmuting with empty audio tracks should restart the audio (can happen when `sendAudio` permission is lost).
        actionBarVC.muteButton.isUserInteractionEnabled = false
        if !isMuted && audioPermissionInitiate {
            VoxeetSDK.shared.conference.startAudio { error in
                self.actionBarVC.muteButton.isUserInteractionEnabled = true
                if error != nil {
                    self.actionBarVC.muteButton(state: .off)
                } else {
                    self.audioPermissionInitiate = false
                    
                    // Monkey patch: need to unmute after being invited without audio permission.
                    VoxeetSDK.shared.conference.mute(false) { error in
                        if error != nil {
                            self.actionBarVC.muteButton(state: .off)
                        }
                    }
                }
            }
        } else {
            VoxeetSDK.shared.conference.mute(isMuted) { error in
                self.actionBarVC.muteButton.isUserInteractionEnabled = true
                if error != nil {
                    self.actionBarVC.muteButton(state: .off)
                }
            }
        }
    }
    
    func cameraAction() {
        Permissions.camera(viewController: self) { granted in
            guard granted else { return }
            
            if self.actionBarVC.cameraButton.tag == 0 {
                self.actionBarVC.cameraButton(state: .on)
                self.actionBarVC.cameraButton.isUserInteractionEnabled = false
                VoxeetSDK.shared.conference.startVideo { error in
                    self.actionBarVC.cameraButton.isUserInteractionEnabled = true
                    if error != nil {
                        self.actionBarVC.cameraButton(state: .off)
                    }
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
        actionBarVC.speakerButton(state: actionBarVC.speakerButton.tag == 0 && actionBarVC.speakerButton.isEnabled ? .on : .off)
        
        // Switch device speaker and set the proximity sensor in line with the current speaker.
        let builtInSpeaker = actionBarVC.speakerButton.tag != 0
        UIDevice.current.isProximityMonitoringEnabled = !builtInSpeaker
        actionBarVC.speakerButton.isUserInteractionEnabled = false
        VoxeetSDK.shared.mediaDevice.switchDeviceSpeaker(forceBuiltInSpeaker: builtInSpeaker) {
            self.actionBarVC.speakerButton.isUserInteractionEnabled = true
        }
    }
    
    func screenShareAction() {
        guard presenterID == nil || presenterID == VoxeetSDK.shared.session.participant?.id else {
            return
        }
        
        if #available(iOS 11.0, *) {
            if actionBarVC.screenShareButton.tag == 0 {
                let broadcast = VoxeetSDK.shared.appGroup != nil
                
                // Start screen share.
                actionBarVC.screenShareButton(state: .on)
                VoxeetSDK.shared.conference.startScreenShare(broadcast: broadcast) { error in
                    if error != nil {
                        self.actionBarVC.screenShareButton(state: .off)
                    }
                }
            } else {
                // Stop screen share.
                actionBarVC.screenShareButton(state: .off)
                VoxeetSDK.shared.conference.stopScreenShare { _ in }
            }
        }
    }
    
    func leaveAction() {
        // Block hang up action if the hangUpTimer if currently active.
        guard hangUpTimer == nil else { return }
        
        // Hang up sound.
        hangUpSound?.play()
        sleep(1)
        
        // Remove audio observer to desactivate speakerButton behaviour.
        conferenceStartTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        // Remove mute observer to desactivate muteButton behaviour.
        NotificationCenter.default.removeObserver(self, name: .VTCallKitMuteToggled, object: nil)
        
        // Reset conference state to `disconnecting` and update UI.
        conferenceStateLabel.text = nil
        updateConferenceStatus(.leaving)
        // Hide own video renderer.
        if actionBarVC.cameraButton.tag != 0 {
            ownVideoRenderer.alpha = 0
            flipImage.alpha = ownVideoRenderer.alpha
        }
        
        // Reset action bar.
        actionBarVC.muteButton(state: .on)
        actionBarVC.cameraButton(state: .off)
        actionBarVC.speakerButton(state: .off)
        actionBarVC.screenShareButton(state: .off)
        
        // If the conference isn't connected yet, retry the hang up action after few milliseconds to stop the conference.
        guard VoxeetSDK.shared.conference.current?.status == .joined else {
            hangUpTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(hangUpRetry), userInfo: nil, repeats: true)
            return
        }
        
        // Leave conference.
        VoxeetSDK.shared.conference.leave()
    }
}

/*
 *  MARK: - VTUXSpeakerFilePresentationViewControllerDelegate
 */

extension ConferenceViewController: VTUXSpeakerFilePresentationViewControllerDelegate {
    func filePresentationStarted(participant: VTParticipant?) {
        filePresentationContainerView.isHidden = false
        startPresentation(participant: participant)
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
    func videoPresentationStarted(participant: VTParticipant?) {
        videoPresentationContainerView.isHidden = false
        startPresentation(participant: participant)
    }
    
    func videoPresentationStopped() {
        videoPresentationContainerView.isHidden = true
        stopPresentation()
    }
}
