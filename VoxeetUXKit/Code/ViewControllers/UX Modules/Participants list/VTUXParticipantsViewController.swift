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

@objcMembers public class VTUXParticipantsViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    public var edgeInsets = UIEdgeInsets.zero {
        didSet {
            collectionView.scrollIndicatorInsets = edgeInsets
        }
    }
    private var previousInterfaceOrientation: UIInterfaceOrientation!
    
    public var speakingColor: UIColor!
    public var selectedColor: UIColor!
    private let inactiveAlpha: CGFloat = 0.6
    
    public weak var delegate: VTUXParticipantsViewControllerDelegate?
    
    private var activeParticipants = [VTParticipant]()
    private var listenerParticipants = [VTParticipant]()
    private var leftParticipants = [VTParticipant]()
    private var selectedParticipant: VTParticipant?
    private var lockedParticipant: VTParticipant?
    
    private let voiceLevelTimeInterval: TimeInterval = 0.1
    private var voiceLevelTimer: Timer?
    
    private enum ParticipantSection: Int {
        case active
        case listener
        case left
    }
    
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
    
    public func append(participant: VTParticipant) {
        if activeParticipants.filter({ $0.id == participant.id }).isEmpty && listenerParticipants.filter({ $0.id == participant.id }).isEmpty && leftParticipants.filter({ $0.id == participant.id }).isEmpty {
            let index: Int
            let section: ParticipantSection
            let previousCount = activeParticipants.count
            
            if participant.type == .user && participant.status == .connected {
                activeParticipants.append(participant)
                section = .active
            } else if participant.type == .listener && participant.status == .connected {
                listenerParticipants.append(participant)
                section = .listener
            } else {
                leftParticipants.append(participant)
                section = .left
            }
            
            index = collectionView.numberOfItems(inSection: section.rawValue)
            let indexPath = IndexPath(row: index, section: section.rawValue)
            collectionView.insertItems(at: [indexPath])
            collectionView.flashScrollIndicators()
            
            // Reset one-one call optimization.
            if previousCount == 1 && previousCount < activeParticipants.count {
                // Reload the first participant in order to properly attach the video stream.
                let indexPath = IndexPath(row: 0, section: ParticipantSection.active.rawValue)
                collectionView.reloadItems(at: [indexPath])
            }
        } else {
            update(participant: participant)
        }
    }
    
    public func update(participant: VTParticipant) {
        // Reset selected participant.
        if participant.id == selectedParticipant?.id, participant.status != .connected {
            selectedParticipant = nil
            delegate?.updated(participant: nil)
        }
        
        if let index = activeParticipants.firstIndex(where: { $0.id == participant.id }) { /* Active participant update */
            if participant.type == .user && participant.status == .connected { /* Reload active participant */
                activeParticipants[index] = participant
                
                reloadCell(participant: participant)
            } else { /* Switch participant from active to left list */
                switchParticipant(participant, fromSection: .active, toSection: .left, fromIndex: index, toIndex: 0)
            }
        } else if let index = listenerParticipants.firstIndex(where: { $0.id == participant.id }) { /* Listener participant update */
            if participant.status == .left { /* Switch participant from listener to left list */
                switchParticipant(participant, fromSection: .listener, toSection: .left, fromIndex: index, toIndex: 0)
            } else { /* Reload listener participant */
                listenerParticipants[index] = participant
                
                let indexPath = IndexPath(row: index, section: ParticipantSection.listener.rawValue)
                collectionView.reloadItems(at: [indexPath])
            }
        } else if let index = leftParticipants.firstIndex(where: { $0.id == participant.id }) { /* Left participant update */
            if participant.type == .user && participant.status == .connected { /* Switch participant from left to active list */
                switchParticipant(participant, fromSection: .left, toSection: .active, fromIndex: index)
            } else if participant.type == .listener && participant.status == .connected { /* Switch participant from left to listener list */
                switchParticipant(participant, fromSection: .left, toSection: .listener, fromIndex: index)
            } else { /* Reload left participant */
                leftParticipants[index] = participant
                
                let indexPath = IndexPath(row: index, section: ParticipantSection.left.rawValue)
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    public func remove(participant: VTParticipant) {
        // Reset selected participant.
        if participant.id == selectedParticipant?.id {
            selectedParticipant = nil
            delegate?.updated(participant: nil)
        }
        
        if let index = activeParticipants.firstIndex(where: { $0.id == participant.id }) {
            activeParticipants.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: ParticipantSection.active.rawValue)
            collectionView.deleteItems(at: [indexPath])
        } else if let index = listenerParticipants.firstIndex(where: { $0.id == participant.id }) {
            listenerParticipants.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: ParticipantSection.listener.rawValue)
            collectionView.deleteItems(at: [indexPath])
        } else if let index = leftParticipants.firstIndex(where: { $0.id == participant.id }) {
            leftParticipants.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: ParticipantSection.left.rawValue)
            collectionView.deleteItems(at: [indexPath])
        }
    }
    
    public func reload() {
        // Reload collectionView's data asynchronously to avoid an insert item at the same time.
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    public func reloadCell(participant: VTParticipant) {
        // Update / Hide video renderer.
        if let index = activeParticipants.firstIndex(where: { $0.id == participant.id }) {
            let indexPath = IndexPath(row: index, section: ParticipantSection.active.rawValue)
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
        }
    }
    
    public func lock(participant: VTParticipant?) {
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
                if let cell = self.collectionView.cellForItem(at: indexPath) as? VTUXParticipantCollectionViewCell, indexPath.section == ParticipantSection.active.rawValue {
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
    
    private func participantForItem(at indexPath: IndexPath) -> VTParticipant {
        switch ParticipantSection(rawValue: indexPath.section) {
        case .active: return activeParticipants[indexPath.row]
        case .listener: return listenerParticipants[indexPath.row]
        default: return leftParticipants[indexPath.row]
        }
    }
    
    private func switchParticipant(_ participant: VTParticipant, fromSection: ParticipantSection, toSection: ParticipantSection, fromIndex: Int, toIndex: Int? = nil) {
        if fromSection == .active {
            activeParticipants.remove(at: fromIndex)
        } else if fromSection == .listener {
            listenerParticipants.remove(at: fromIndex)
        } else if fromSection == .left {
            leftParticipants.remove(at: fromIndex)
        }
        collectionView.deleteItems(at: [IndexPath(row: fromIndex, section: fromSection.rawValue)])
        
        if toSection == .active {
            if let toIndex = toIndex {
                activeParticipants.insert(participant, at: toIndex)
                collectionView.insertItems(at: [IndexPath(row: toIndex, section: toSection.rawValue)])
            } else {
                activeParticipants.append(participant)
                collectionView.insertItems(at: [IndexPath(row: activeParticipants.count - 1, section: toSection.rawValue)])
            }
        } else if toSection == .listener {
            if let toIndex = toIndex {
                listenerParticipants.insert(participant, at: toIndex)
                collectionView.insertItems(at: [IndexPath(row: toIndex, section: toSection.rawValue)])
            } else {
                listenerParticipants.append(participant)
                collectionView.insertItems(at: [IndexPath(row: listenerParticipants.count - 1, section: toSection.rawValue)])
            }
        } else if toSection == .left {
            if let toIndex = toIndex {
                leftParticipants.insert(participant, at: toIndex)
                collectionView.insertItems(at: [IndexPath(row: toIndex, section: toSection.rawValue)])
            } else {
                leftParticipants.append(participant)
                collectionView.insertItems(at: [IndexPath(row: leftParticipants.count - 1, section: toSection.rawValue)])
            }
        }
    }
    
    @objc private func deviceOrientationDidChange(notification: Notification) {
        if previousInterfaceOrientation.isPortrait != UIApplication.shared.statusBarOrientation.isPortrait {
            collectionView.reloadData()
        }
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
    }
}

extension VTUXParticipantsViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let participants = activeParticipants + listenerParticipants + leftParticipants
        
        // Hide collection view if there is just one participant live (one-one call).
        var collectionViewAlpha: CGFloat = 1
        if let participant = participants.first, participant.type == .user && participant.status == .connected && participants.count == 1 {
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
        
        switch ParticipantSection(rawValue: section) {
        case .active: return activeParticipants.count
        case .listener: return listenerParticipants.count
        default: return leftParticipants.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VTUXParticipantCollectionViewCell", for: indexPath) as! VTUXParticipantCollectionViewCell
        cell.avatar.alpha = inactiveAlpha
        cell.name.alpha = cell.avatar.alpha
        
        // Get participant.
        let participant = participantForItem(at: indexPath)
        
        // Cell data.
        let avatarURL = participant.info.avatarURL ?? ""
        let imageURLStr = avatarURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let placeholderImage = UIImage(named: "UserPlaceholder", in: .module, compatibleWith: nil)
        cell.avatar.kf.setImage(with: URL(string: imageURLStr), placeholder: placeholderImage, options: nil, progressBlock: nil, completionHandler: nil)
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
        
        // Participant is currently in conference and is active.
        if indexPath.section == ParticipantSection.active.rawValue {
            cell.avatar.alpha = 1
        }
        
        return cell
    }
}

extension VTUXParticipantsViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == ParticipantSection.active.rawValue else { return }
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
        guard indexPath.section == ParticipantSection.active.rawValue else { return }
        guard let cell = cell as? VTUXParticipantCollectionViewCell else { return }
        
        // Hide video renderer.
        cell.avatar.isHidden = false
        cell.videoRenderer.isHidden = true
        
        // Unattach video renderer stream.
        cell.videoRenderer.unattach()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard lockedParticipant == nil else { return }
        
        let participant = participantForItem(at: indexPath)
        var indexPaths = [indexPath]
        
        // Get participants index paths that need to be reloaded.
        var selectedIndexPath: IndexPath?
        if let row = activeParticipants.firstIndex(where: { $0.id == selectedParticipant?.id }) {
            selectedIndexPath = IndexPath(row: row, section: ParticipantSection.active.rawValue)
        } else if let row = listenerParticipants.firstIndex(where: { $0.id == selectedParticipant?.id }) {
            selectedIndexPath = IndexPath(row: row, section: ParticipantSection.listener.rawValue)
        } else if let row = leftParticipants.firstIndex(where: { $0.id == selectedParticipant?.id }) {
            selectedIndexPath = IndexPath(row: row, section: ParticipantSection.left.rawValue)
        }
        if let selectedIndexPath = selectedIndexPath, selectedIndexPath != indexPath {
            indexPaths.append(selectedIndexPath)
        }
        
        // Select / Unselect a participant.
        if indexPath.section == ParticipantSection.active.rawValue && participant.id != selectedParticipant?.id {
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
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let window = UIApplication.keyWindow
        let safeArea: UIEdgeInsets
        if #available(iOS 11.0, *) {
            safeArea = window?.safeAreaInsets ?? .zero
        } else {
            safeArea = .zero
        }
        
        if section == ParticipantSection.active.rawValue {
            let numberOfItems = CGFloat(activeParticipants.count + listenerParticipants.count + leftParticipants.count)
            let combinedItemWidth = (numberOfItems * flowLayout.itemSize.width) + ((numberOfItems - 1) * flowLayout.minimumLineSpacing)
            
            let paddingLeft = (view.frame.width - combinedItemWidth) / 2 - safeArea.left
            if paddingLeft >= edgeInsets.left {
                return UIEdgeInsets(top: edgeInsets.top, left: paddingLeft, bottom: edgeInsets.bottom, right: 0)
            } else {
                return UIEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: 0)
            }
        } else {
            var paddingLeft: CGFloat = 0
            let activeSectionCount = collectionView.numberOfItems(inSection: ParticipantSection.active.rawValue)
            let previousSectionCount = collectionView.numberOfItems(inSection: section - 1)
            let currentSectionCount = collectionView.numberOfItems(inSection: section)
            
            if (activeSectionCount != 0 || previousSectionCount != 0) && currentSectionCount != 0 {
                paddingLeft = flowLayout.minimumLineSpacing
            }
            
            return UIEdgeInsets(top: edgeInsets.top, left: paddingLeft, bottom: edgeInsets.bottom, right: edgeInsets.right)
        }
    }
}
