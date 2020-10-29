//
//  VTUXParticipantsViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 18/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public protocol VTUXParticipantsViewControllerDelegate {
    func updated(participant: VTParticipant?)
}

@objc public class VTUXParticipantsViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @objc public var edgeInsets = UIEdgeInsets.zero {
        didSet {
            collectionView.scrollIndicatorInsets = edgeInsets
        }
    }
    private var previousInterfaceOrientation: UIInterfaceOrientation!
    
    @objc public var speakingColor: UIColor!
    @objc public var selectedColor: UIColor!
    private let inactiveAlpha: CGFloat = 0.6
    
    @objc public weak var delegate: VTUXParticipantsViewControllerDelegate?
    
    private var activeParticipants = [VTParticipant]()
    private var inactiveParticipants = [VTParticipant]()
    private var selectedParticipant: VTParticipant?
    private var lockedParticipant: VTParticipant?
    
    private let voiceLevelTimeInterval: TimeInterval = 0.1
    private var voiceLevelTimer: Timer?
    
    @objc override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Device orientation observer to re-center cells.
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Init voice level timer.
        voiceLevelTimer = Timer(timeInterval: voiceLevelTimeInterval, target: self, selector: #selector(refreshVoiceLevel), userInfo: nil, repeats: true)
        voiceLevelTimer?.tolerance = voiceLevelTimeInterval / 2
        RunLoop.current.add(voiceLevelTimer!, forMode: .common)
        
        // Participants list configuration.
        let conferenceConfig = VoxeetUXKit.shared.conferenceController?.configuration
        let participantsConfig = conferenceConfig?.participants
        speakingColor = participantsConfig?.speakingColor ?? .black
        selectedColor = participantsConfig?.selectedColor ?? .black
    }
    
    @objc override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
        // Stop voice level timer.
        voiceLevelTimer?.invalidate()
    }
    
    @objc public func append(participant: VTParticipant) {
        if activeParticipants.filter({ $0.id == participant.id }).isEmpty && inactiveParticipants.filter({ $0.id == participant.id }).isEmpty {
            let index: Int
            let section: Int
            let previousCount = activeParticipants.count
            
            if participant.type == .user && !participant.streams.isEmpty {
                activeParticipants.append(participant)
                section = 0
            } else {
                inactiveParticipants.append(participant)
                section = 1
            }
            
            index = collectionView.numberOfItems(inSection: section)
            let indexPath = IndexPath(row: index, section: section)
            collectionView.insertItems(at: [indexPath])
            collectionView.flashScrollIndicators()
            
            // Reset one-one call optimization.
            if previousCount == 1 && previousCount < activeParticipants.count {
                // Reload the first participant in order to properly attach the video stream.
                let indexPath = IndexPath(row: 0, section: 0)
                collectionView.reloadItems(at: [indexPath])
            }
        } else {
            update(participant: participant)
        }
    }
    
    @objc public func update(participant: VTParticipant) {
        if let index = activeParticipants.firstIndex(where: { $0.id == participant.id }) {
            if !participant.streams.isEmpty { /* Reload participant */
                activeParticipants[index] = participant
                
                // Update / Hide video renderer.
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = collectionView.cellForItem(at: indexPath) as? VTUXParticipantCollectionViewCell {
                    if let stream = participant.streams.first(where: { $0.type == .Camera }), !stream.videoTracks.isEmpty {
                        if collectionView.alpha != 0 { /* One-one call optimization */
                            cell.avatar.isHidden = true
                            cell.videoRenderer.isHidden = false
                            
                            cell.videoRenderer.attach(participant: participant, stream: stream)
                        }
                    } else {
                        cell.avatar.isHidden = false
                        cell.videoRenderer.isHidden = true
                        
                        cell.videoRenderer.unattach()
                    }
                }
            } else { /* Switch participant from active to inactive list */
                activeParticipants.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                
                inactiveParticipants.insert(participant, at: 0)
                collectionView.insertItems(at: [IndexPath(row: 0, section: 1)])
            }
        } else if let index = inactiveParticipants.firstIndex(where: { $0.id == participant.id }) {
            if !participant.streams.isEmpty { /* Switch participant from inactive to active list */
                inactiveParticipants.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(row: index, section: 1)])
                
                activeParticipants.append(participant)
                collectionView.insertItems(at: [IndexPath(row: activeParticipants.count - 1, section: 0)])
            } else { /* Reload participant */
                inactiveParticipants[index] = participant
                
                let indexPath = IndexPath(row: index, section: 1)
                collectionView.reloadItems(at: [indexPath])
            }
        }
        
        if participant.id == selectedParticipant?.id, participant.streams.isEmpty {
            selectedParticipant = nil
            delegate?.updated(participant: nil)
        }
    }
    
    @objc public func remove(participant: VTParticipant) {
        if let index = activeParticipants.firstIndex(where: { $0.id == participant.id }) {
            activeParticipants.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.deleteItems(at: [indexPath])
        } else if let index = inactiveParticipants.firstIndex(where: { $0.id == participant.id }) {
            inactiveParticipants.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: 1)
            collectionView.deleteItems(at: [indexPath])
        }
        
        if participant.id == selectedParticipant?.id {
            selectedParticipant = nil
            delegate?.updated(participant: nil)
        }
    }
    
    @objc public func reload() {
        // Reload collectionView's data asynchronously to avoid an insert item at the same time.
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc public func lock(participant: VTParticipant?) {
        lockedParticipant = participant
        selectedParticipant = lockedParticipant
        
        let indexPaths = collectionView.indexPathsForVisibleItems
        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: indexPaths)
        }
    }
    
    @objc private func refreshVoiceLevel() {
        guard collectionView.alpha != 0 else { return }
        
        DispatchQueue.main.async {
            let indexPaths = self.collectionView.indexPathsForVisibleItems
            for indexPath in indexPaths {
                if let cell = self.collectionView.cellForItem(at: indexPath) as? VTUXParticipantCollectionViewCell, indexPath.section == 0 {
                    let participant = self.participantForItem(at: indexPath)
                    var isParticipantTalking = false
                    
                    if !participant.streams.isEmpty {
                        let isSpeaking = VoxeetSDK.shared.conference.isSpeaking(participant: participant)
                        
                        // Update avatar border width.
                        if isSpeaking || participant.id == self.selectedParticipant?.id {
                            if cell.avatar.layer.borderWidth == 0 {
                                cell.avatar.layer.borderWidth = cell.avatar.frame.width * (4/100) /* 4% */
                                cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
                            }
                            isParticipantTalking = true
                        }
                        
                        // Update name alpha.
                        if isSpeaking && cell.name.alpha != 1 {
                            cell.name.alpha = 1
                        } else if !isSpeaking && cell.name.alpha == 1 {
                            cell.name.alpha = self.inactiveAlpha
                        }
                    }
                    
                    // Reset avatar border width.
                    if !isParticipantTalking && cell.avatar.layer.borderWidth != 0 {
                        cell.avatar.layer.borderWidth = 0
                        cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
                    }
                }
            }
        }
    }
    
    @objc private func deviceOrientationDidChange(notification: Notification) {
        if previousInterfaceOrientation.isPortrait != UIApplication.shared.statusBarOrientation.isPortrait {
            collectionView.reloadData()
        }
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
    }
    
    private func participantForItem(at indexPath: IndexPath) -> VTParticipant {
        if indexPath.section == 0 {
            return activeParticipants[indexPath.row]
        } else {
            return inactiveParticipants[indexPath.row]
        }
    }
}

extension VTUXParticipantsViewController: UICollectionViewDataSource {
    @objc public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let participants = activeParticipants + inactiveParticipants
        
        // Hide collection view if there is just one participant live (one-one call).
        var collectionViewAlpha: CGFloat = 1
        if let participant = participants.first, !participant.streams.isEmpty && participants.count == 1 {
            let mediaStream = participant.streams.first(where: { $0.type == .Camera })
            let screenShareMediaStream = participant.streams.first(where: { $0.type == .ScreenShare })
            
            if screenShareMediaStream != nil && mediaStream?.videoTracks.count != 0 {
                collectionViewAlpha = 1
            } else {
                collectionViewAlpha = 0
            }
        } else if participants.isEmpty {
            collectionViewAlpha = 0
        } else {
            collectionViewAlpha = 1
        }
        // Hide collection view animation.
        if collectionView.alpha != collectionViewAlpha {
            UIView.animate(withDuration: 0.5) {
                collectionView.alpha = collectionViewAlpha
            }
        }
        
        return section == 0 ? activeParticipants.count : inactiveParticipants.count
    }
    
    @objc public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VTUXParticipantCollectionViewCell", for: indexPath) as! VTUXParticipantCollectionViewCell
        cell.avatar.alpha = inactiveAlpha
        cell.name.alpha = cell.avatar.alpha
        
        // Get participant.
        let participant = participantForItem(at: indexPath)
        
        // Cell data.
        let avatarURL = participant.info.avatarURL ?? ""
        let imageURLStr = avatarURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let placeholderImage = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        cell.avatar.sd_setImage(with: URL(string: imageURLStr), placeholderImage: placeholderImage)
        cell.name.text = participant.info.name
        
        // Cell border property.
        cell.avatar.layer.borderColor = speakingColor.cgColor
        if let id = participant.id, id == selectedParticipant?.id {
            cell.avatar.layer.borderColor = selectedColor.cgColor
            cell.avatar.layer.borderWidth = cell.avatar.frame.width * (4/100) /* 4% */
        } else {
            cell.avatar.layer.borderWidth = 0
        }
        cell.videoRenderer.layer.borderColor = cell.avatar.layer.borderColor
        cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
        
        // Participant is currently in conference.
        if !participant.streams.isEmpty {
            cell.avatar.alpha = 1
        }
        
        return cell
    }
}

extension VTUXParticipantsViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        guard let cell = cell as? VTUXParticipantCollectionViewCell else { return }
        
        // Unhide video renderer and attach stream.
        let participant = participantForItem(at: indexPath)
        if let stream = participant.streams.first(where: { $0.type == .Camera }), !stream.videoTracks.isEmpty {
            cell.avatar.isHidden = true
            cell.videoRenderer.isHidden = false
            
            cell.videoRenderer.attach(participant: participant, stream: stream)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        guard let cell = cell as? VTUXParticipantCollectionViewCell else { return }
        
        // Hide video renderer.
        cell.avatar.isHidden = false
        cell.videoRenderer.isHidden = true
        
        // Unattach video renderer stream.
        cell.videoRenderer.unattach()
    }
    
    @objc public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard lockedParticipant == nil else { return }
        
        let participant = participantForItem(at: indexPath)
        var indexPaths = [indexPath]
        
        // Get participants index paths that need to be reloaded.
        var selectedIndexPath: IndexPath?
        if let row = activeParticipants.firstIndex(where: { $0.id == selectedParticipant?.id }) {
            selectedIndexPath = IndexPath(row: row, section: 0)
        } else if let row = inactiveParticipants.firstIndex(where: { $0.id == selectedParticipant?.id })  {
            selectedIndexPath = IndexPath(row: row, section: 1)
        }
        if let selectedIndexPath = selectedIndexPath, selectedIndexPath != indexPath {
            indexPaths.append(selectedIndexPath)
        }
        
        // Select / Unselect a participant.
        if !participant.streams.isEmpty && participant.id != selectedParticipant?.id {
            selectedParticipant = participant
        } else {
            selectedParticipant = nil
        }
        
        // Reload collection view.
        collectionView.reloadItems(at: indexPaths)
        
        // Update selected participant.
        delegate?.updated(participant: selectedParticipant)
    }
}

extension VTUXParticipantsViewController: UICollectionViewDelegateFlowLayout {
    @objc public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let window = UIApplication.shared.keyWindow
        let safeArea: UIEdgeInsets
        if #available(iOS 11.0, *) {
            safeArea = window?.safeAreaInsets ?? .zero
        } else {
            safeArea = .zero
        }
        
        if section == 0 {
            let numberOfItems = CGFloat(activeParticipants.count + inactiveParticipants.count)
            let combinedItemWidth = (numberOfItems * flowLayout.itemSize.width) + ((numberOfItems - 1) * flowLayout.minimumLineSpacing)
            
            let paddingLeft = (view.frame.width - combinedItemWidth) / 2 - safeArea.left
            if paddingLeft >= edgeInsets.left {
                return UIEdgeInsets(top: edgeInsets.top, left: paddingLeft, bottom: edgeInsets.bottom, right: 0)
            } else {
                return UIEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: 0)
            }
        } else {
            let paddingLeft: CGFloat = collectionView.numberOfItems(inSection: 0) != 0 ? flowLayout.minimumLineSpacing : 0
            return UIEdgeInsets(top: edgeInsets.top, left: paddingLeft, bottom: edgeInsets.bottom, right: edgeInsets.right)
        }
    }
}
