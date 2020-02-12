//
//  VTUXSpeakerVideoPresentationViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 13/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK
import MediaPlayer

@objc public protocol VTUXSpeakerVideoPresentationViewControllerDelegate {
    func videoPresentationStarted(participant: VTParticipant?)
    func videoPresentationStopped()
}

@objc public class VTUXSpeakerVideoPresentationViewController: UIViewController {
    
    // Player for video presentation.
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    @objc public weak var delegate: VTUXSpeakerVideoPresentationViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        VoxeetSDK.shared.videoPresentation.delegate = self
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer?.frame = view.bounds
    }
}

extension VTUXSpeakerVideoPresentationViewController: VTVideoPresentationDelegate {
    public func started(videoPresentation: VTVideoPresentation) {
        player = AVPlayer(url: videoPresentation.url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = view.bounds
        playerLayer!.backgroundColor = UIColor.black.cgColor
        view.layer.addSublayer(playerLayer!)
        
        player?.play()
        player?.seek(to: CMTimeMakeWithSeconds(Double(videoPresentation.timestamp) / 1000, preferredTimescale: 1000))
        
        delegate?.videoPresentationStarted(participant: videoPresentation.participant)
    }
    
    public func stopped(videoPresentation: VTVideoPresentation) {
        player?.pause()
        playerLayer = nil
        player = nil
        
        delegate?.videoPresentationStopped()
    }
    
    public func played(videoPresentation: VTVideoPresentation) {
        player?.play()
        player?.seek(to: CMTimeMakeWithSeconds(Double(videoPresentation.timestamp) / 1000, preferredTimescale: 1000))
    }
    
    public func paused(videoPresentation: VTVideoPresentation) {
        player?.pause()
    }
    
    public func sought(videoPresentation: VTVideoPresentation) {
        player?.seek(to: CMTimeMakeWithSeconds(Double(videoPresentation.timestamp) / 1000, preferredTimescale: 1000))
    }
}
