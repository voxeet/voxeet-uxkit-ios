//
//  VTUXSpeakerFilePresentationViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 14/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK
import SDWebImage

@objc public protocol VTUXSpeakerFilePresentationViewControllerDelegate {
    func filePresentationStarted(user: VTUser?)
    func filePresentationStopped()
}

@objc public class VTUXSpeakerFilePresentationViewController: UIViewController {
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var fileImageView: UIImageView!
    
    @objc public weak var delegate: VTUXSpeakerFilePresentationViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        // File presentation observers.
        NotificationCenter.default.addObserver(self, selector: #selector(filePresentationStarted), name: .VTFilePresentationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(filePresentationUpdated), name: .VTFilePresentationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(filePresentationStopped), name: .VTFilePresentationStopped, object: nil)
    }
    
    @objc private func filePresentationStarted(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: userInfo) as? [String: Any] {
                if let fileID = json["fileId"] as? String, let page = json["position"] as? Int, let userID = json["userId"] as? String {
                    if let url = VoxeetSDK.shared.filePresentation.getImage(fileID: fileID, page: page) {
                        fileImageView.sd_setImage(with: url)
                        
                        // Started delegate.
                        let user = VoxeetSDK.shared.conference.user(userID: userID)
                        delegate?.filePresentationStarted(user: user)
                        
                        // Reset zoom when image change.
                        scrollView.zoomScale = 1
                    }
                }
            }
        } catch {}
    }
    
    @objc private func filePresentationUpdated(notification: Notification) {
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: userInfo) as? [String: Any] {
                if let fileID = json["fileId"] as? String, let page = json["position"] as? Int {
                    if let url = VoxeetSDK.shared.filePresentation.getImage(fileID: fileID, page: page) {
                        fileImageView.sd_setImage(with: url)
                        
                        // Reset zoom when image change.
                        scrollView.zoomScale = 1
                    }
                }
            }
        } catch {}
    }
    
    @objc private func filePresentationStopped(notification: Notification) {
        fileImageView.image = nil
        
        // Stopped delegate.
        delegate?.filePresentationStopped()
    }
}

extension VTUXSpeakerFilePresentationViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return fileImageView
    }
}
