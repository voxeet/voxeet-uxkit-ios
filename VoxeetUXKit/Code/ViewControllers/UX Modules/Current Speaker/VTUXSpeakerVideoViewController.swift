//
//  VTUXSpeakerVideoViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 21/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public class VTUXSpeakerVideoViewController: UIViewController {
    @IBOutlet weak private(set) var videoRenderer: VTVideoView!
    
    @objc override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Tap gesture.
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tapGesture))
        tap.numberOfTapsRequired = 1
        videoRenderer.addGestureRecognizer(tap)
        
        // Double tap gesture.
        let doubleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(doubleTapGesture))
        doubleTap.numberOfTapsRequired = 2
        videoRenderer.addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)
        
        // Pinch gesture.
        let pinch = UIPinchGestureRecognizer(target: self,
                                             action: #selector(pinchGesture))
        videoRenderer.addGestureRecognizer(pinch)
        
        // Speaker configuration.
        let speakerConfig = VoxeetUXKit.shared.conferenceController?.configuration.speaker
        videoRenderer.contentFill = speakerConfig?.videoAspect == .fill ? true : false
    }
    
    @objc public func attach(participant: VTParticipant, stream: MediaStream) {
        videoRenderer.attach(participant: participant, stream: stream)
    }
    
    @objc public func unattach() {
        videoRenderer.unattach()
    }
    
    @objc public func contentFill(_ fill: Bool, animated: Bool) {
        videoRenderer.contentFill(fill, animated: animated)
        videoRenderer.setNeedsLayout()
    }
    
    @objc private func tapGesture(recognizer: UIPinchGestureRecognizer) {
        let sessionParticipantID = VoxeetSDK.shared.session.participant?.id
        if let participantID = sessionParticipantID, participantID == videoRenderer.userID {
            videoRenderer.isUserInteractionEnabled = false
            videoRenderer.subviews.first?.alpha = 0
            VoxeetSDK.shared.mediaDevice.switchCamera {
                DispatchQueue.main.async {
                    self.videoRenderer.mirrorEffect.toggle()
                    self.videoRenderer.isUserInteractionEnabled = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.videoRenderer.subviews.first?.alpha = 1
                }
            }
        }
    }
    
    @objc private func doubleTapGesture(recognizer: UIPinchGestureRecognizer) {
        // Video renderer content fill/fit.
        contentFill(!videoRenderer.contentFill, animated: true)
    }
    
    @objc private func pinchGesture(recognizer: UIPinchGestureRecognizer) {
        let fill = recognizer.scale > 1 ? true : false
        
        // Video renderer content fill/fit.
        if fill != videoRenderer.contentFill {
            contentFill(fill, animated: true)
        }
    }
}
