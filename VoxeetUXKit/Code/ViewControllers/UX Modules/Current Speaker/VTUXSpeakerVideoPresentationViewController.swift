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
    func videoPresentationStarted(user: VTUser?)
    func videoPresentationStopped()
}

@objc public class VTUXSpeakerVideoPresentationViewController: UIViewController {
    
    // Player for video presentation.
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    @objc public weak var delegate: VTUXSpeakerVideoPresentationViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Video presentation observers.
        NotificationCenter.default.addObserver(self, selector: #selector(videoPresentationStarted), name: .VTVideoPresentationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPresentationStopped), name: .VTVideoPresentationStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPresentationPlay), name: .VTVideoPresentationPlay, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPresentationPause), name: .VTVideoPresentationPause, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPresentationSeek), name: .VTVideoPresentationSeek, object: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer?.frame = view.bounds
    }
    
    @objc private func videoPresentationStarted(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: userInfo) as? [String: Any] {
                if let url = URL(string: json["url"] as? String ?? ""), let timestamp = json["timestamp"] as? Int, let userID = json["userId"] as? String {
                    player = AVPlayer(url: url)
                    playerLayer = AVPlayerLayer(player: player)
                    playerLayer!.frame = view.bounds
                    playerLayer!.backgroundColor = UIColor.black.cgColor
                    view.layer.addSublayer(playerLayer!)
                    
                    player?.play()
                    player?.seek(to: CMTimeMakeWithSeconds(Double(timestamp) / 1000, preferredTimescale: 1000))
                    
                    let user = VoxeetSDK.shared.conference.user(userID: userID)
                    delegate?.videoPresentationStarted(user: user)
                }
            }
        } catch {}
    }
    
    @objc private func videoPresentationStopped(notification: Notification) {
        player?.pause()
        playerLayer = nil
        player = nil
        
        delegate?.videoPresentationStopped()
    }
    
    @objc private func videoPresentationPlay(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: userInfo) as? [String: Any] {
                if let timestamp = json["timestamp"] as? Int {
                    player?.play()
                    player?.seek(to: CMTimeMakeWithSeconds(Double(timestamp) / 1000, preferredTimescale: 1000))
                }
            }
        } catch {}
    }
    
    @objc private func videoPresentationPause(notification: Notification) {
        player?.pause()
    }
    
    @objc private func videoPresentationSeek(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: userInfo) as? [String: Any] {
                if let timestamp = json["timestamp"] as? Int {
                    player?.seek(to: CMTimeMakeWithSeconds(Double(timestamp) / 1000, preferredTimescale: 1000))
                }
            }
        } catch {}
    }
}
