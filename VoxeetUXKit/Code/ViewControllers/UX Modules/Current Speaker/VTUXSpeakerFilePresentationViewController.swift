//
//  VTUXSpeakerFilePresentationViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 14/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK
import Kingfisher

@objc public protocol VTUXSpeakerFilePresentationViewControllerDelegate {
    func filePresentationStarted(participant: VTParticipant?)
    func filePresentationStopped()
}

@objc public class VTUXSpeakerFilePresentationViewController: UIViewController {
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var fileImageView: UIImageView!
    
    @objc public weak var delegate: VTUXSpeakerFilePresentationViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        VoxeetSDK.shared.filePresentation.delegate = self
        scrollView.delegate = self
    }
}

extension VTUXSpeakerFilePresentationViewController: VTFilePresentationDelegate {
    public func converted(fileConverted: VTFileConverted) {}
    
    public func started(filePresentation: VTFilePresentation) {
        if let url = VoxeetSDK.shared.filePresentation.image(page: filePresentation.position) {
            fileImageView.kf.setImage(with: url)
            
            // Started delegate.
            delegate?.filePresentationStarted(participant: filePresentation.owner)
            
            // Reset zoom when image change.
            scrollView.zoomScale = 1
        }
    }
    
    public func updated(filePresentation: VTFilePresentation) {
        if let url = VoxeetSDK.shared.filePresentation.image(page: filePresentation.position) {
            fileImageView.kf.setImage(with: url)
            
            // Reset zoom when image change.
            scrollView.zoomScale = 1
        }
    }
    
    public func stopped(filePresentation: VTFilePresentation) {
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
