//
//  VTUXUsersViewController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 18/06/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public protocol VTUXUsersViewControllerDelegate {
    func selectedUserUpdated(user: VTUser?)
}

@objc public class VTUXUsersViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @objc public var edgeInsets = UIEdgeInsets.zero {
        didSet {
            collectionView.scrollIndicatorInsets = edgeInsets
        }
    }
    private var previousInterfaceOrientation: UIInterfaceOrientation!
    
    @objc public var speakingUserColor: UIColor!
    @objc public var selectedUserColor: UIColor!
    private let inactiveAlpha: CGFloat = 0.6
    
    @objc public weak var delegate: VTUXUsersViewControllerDelegate?
    
    private var activeUsers = [VTUser]()
    private var inactiveUsers = [VTUser]()
    private var selectedUser: VTUser?
    private var lockedUser: VTUser?
    
    private var voiceLevelTimerQueue = DispatchQueue(label: "com.voxeet.uxkit.voiceLevelTimer", qos: .background, attributes: .concurrent)
    private var voiceLevelTimer: Timer?
    
    @objc override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Device orientation observer to re-center cells.
        previousInterfaceOrientation = UIApplication.shared.statusBarOrientation
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Init voice level timer.
        voiceLevelTimerQueue.async { [unowned self] in
            self.voiceLevelTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.refreshVoiceLevel), userInfo: nil, repeats: true)
            let currentRunLoop = RunLoop.current
            currentRunLoop.add(self.voiceLevelTimer!, forMode: .common)
            currentRunLoop.run()
        }
        
        // Users list configuration.
        let usersConfiguration = VoxeetUXKit.shared.conferenceController?.configuration.users
        speakingUserColor = usersConfiguration?.speakingUserColor ?? .black
        selectedUserColor = usersConfiguration?.selectedUserColor ?? .black
    }
    
    @objc override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
        // Stop voice level timer.
        if voiceLevelTimer != nil {
            voiceLevelTimerQueue.sync { [unowned self] in
                self.voiceLevelTimer?.invalidate()
                self.voiceLevelTimer = nil
            }
        }
    }
    
    @objc public func append(user: VTUser) {
        if activeUsers.filter({ $0.id == user.id }).isEmpty && inactiveUsers.filter({ $0.id == user.id }).isEmpty {
            let index: Int
            let section: Int
            
            if user.hasStream {
                activeUsers.append(user)
                section = 0
            } else {
                inactiveUsers.append(user)
                section = 1
            }
            
            index = collectionView.numberOfItems(inSection: section)
            let indexPath = IndexPath(row: index, section: section)
            collectionView.insertItems(at: [indexPath])
            collectionView.flashScrollIndicators()
        } else {
            update(user: user)
        }
    }
    
    @objc public func update(user: VTUser) {
        if let index = activeUsers.firstIndex(where: { $0.id == user.id }) {
            if user.hasStream { /* Reload user */
                activeUsers[index] = user
                
                let indexPath = IndexPath(row: index, section: 0)
                collectionView.reloadItems(at: [indexPath])
            } else { /* Switch user from active to inactive list */
                activeUsers.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                
                inactiveUsers.insert(user, at: 0)
                collectionView.insertItems(at: [IndexPath(row: 0, section: 1)])
            }
        } else if let index = inactiveUsers.firstIndex(where: { $0.id == user.id }) {
            if user.hasStream { /* Switch user from inactive to active list */
                inactiveUsers.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(row: index, section: 1)])
                
                activeUsers.append(user)
                collectionView.insertItems(at: [IndexPath(row: activeUsers.count - 1, section: 0)])
            } else { /* Reload user */
                inactiveUsers[index] = user
                
                let indexPath = IndexPath(row: index, section: 1)
                collectionView.reloadItems(at: [indexPath])
            }
        }
        
        if user.id == selectedUser?.id, !user.hasStream {
            selectedUser = nil
            delegate?.selectedUserUpdated(user: nil)
        }
    }
    
    @objc public func remove(userID: String) {
        if let index = activeUsers.firstIndex(where: { $0.id == userID }) {
            activeUsers.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.deleteItems(at: [indexPath])
        } else if let index = inactiveUsers.firstIndex(where: { $0.id == userID }) {
            inactiveUsers.remove(at: index)
            
            let indexPath = IndexPath(row: index, section: 1)
            collectionView.deleteItems(at: [indexPath])
        }
        
        if userID == selectedUser?.id {
            selectedUser = nil
            delegate?.selectedUserUpdated(user: nil)
        }
    }
    
    @objc public func reload() {
        // Reload collectionView's data asynchronously to avoid an insert item at the same time.
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc public func lock(user: VTUser?) {
        lockedUser = user
        selectedUser = lockedUser
        
        let indexPaths = collectionView.indexPathsForVisibleItems
        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: indexPaths)
        }
    }
    
    @objc private func refreshVoiceLevel() {
        DispatchQueue.main.async {
            let indexPaths = self.collectionView.indexPathsForVisibleItems
            for indexPath in indexPaths {
                if let cell = self.collectionView.cellForItem(at: indexPath) as? VTUXUserCollectionViewCell, indexPath.section == 0 {
                    let user = self.activeUsers[indexPath.row]
                    var isUserTalking = false
                    
                    if let userID = user.id, user.hasStream {
                        let voiceLevel = VoxeetSDK.shared.conference.voiceLevel(userID: userID)
                        
                        // Update avatar border width.
                        if voiceLevel >= 0.05 || userID == self.selectedUser?.id {
                            if cell.avatar.layer.borderWidth == 0 {
                                cell.avatar.layer.borderWidth = 2
                                cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
                            }
                            isUserTalking = true
                        }
                        
                        // Update name alpha.
                        if voiceLevel >= 0.05 && cell.name.alpha != 1 {
                            cell.name.alpha = 1
                        } else if voiceLevel < 0.05 && cell.name.alpha == 1 {
                            cell.name.alpha = self.inactiveAlpha
                        }
                    }
                    
                    if !isUserTalking && cell.avatar.layer.borderWidth != 0 {
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
}

extension VTUXUsersViewController: UICollectionViewDataSource {
    @objc public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let users = activeUsers + inactiveUsers
        
        // Hide collection view if there is just one user live.
        var collectionViewAlpha: CGFloat = 1
        if let user = users.first, user.hasStream && users.count == 1 {
            let mediaStream = VoxeetSDK.shared.conference.mediaStream(userID: user.id ?? "")
            let screenShareMediaStream = VoxeetSDK.shared.conference.screenShareMediaStream()
            
            if screenShareMediaStream != nil && mediaStream?.videoTracks.count != 0 {
                collectionViewAlpha = 1
            } else {
                collectionViewAlpha = 0
            }
        } else if users.isEmpty {
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
        
        return section == 0 ? activeUsers.count : inactiveUsers.count
    }
    
    @objc public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VTUXUserCollectionViewCell", for: indexPath) as! VTUXUserCollectionViewCell
        cell.avatar.alpha = inactiveAlpha
        cell.name.alpha = cell.avatar.alpha
        
        // Get user.
        let user: VTUser
        if indexPath.section == 0 {
            user = activeUsers[indexPath.row]
        } else {
            user = inactiveUsers[indexPath.row]
        }
        
        // Cell data.
        let avatarURL = user.avatarURL ?? ""
        let imageURLStr = avatarURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let imageURL = URL(string: imageURLStr) {
            cell.avatar.kf.setImage(with: imageURL)
        } else {
            cell.avatar.image = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
        cell.name.text = user.name
        
        // Cell border property.
        cell.avatar.layer.borderColor = speakingUserColor.cgColor
        if let userID = user.id, userID == selectedUser?.id {
            cell.avatar.layer.borderColor = selectedUserColor.cgColor
            cell.avatar.layer.borderWidth = 2
        } else {
            cell.avatar.layer.borderWidth = 0
        }
        cell.videoRenderer.layer.borderColor = cell.avatar.layer.borderColor
        cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
        
        // User is currently in conference.
        if user.hasStream {
            // Update cell's user.
            cell.user = user
            cell.avatar.alpha = 1
            
            // Attach a video stream.
            if let userID = user.id, let stream = VoxeetSDK.shared.conference.mediaStream(userID: userID), !stream.videoTracks.isEmpty {
                cell.avatar.isHidden = true
                cell.videoRenderer.isHidden = false
                cell.videoRenderer.attach(userID: userID, stream: stream)
            }
        }
        
        return cell
    }
}

extension VTUXUsersViewController: UICollectionViewDelegate {
    @objc public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard lockedUser == nil else { return }
        
        var indexPaths = [indexPath]
        let user: VTUser
        if indexPath.section == 0 {
            user = activeUsers[indexPath.row]
        } else {
            user = inactiveUsers[indexPath.row]
        }
        
        // Get selected user index path.
        var selectedUserIndexPath: IndexPath?
        if let row = activeUsers.firstIndex(where: { $0.id == selectedUser?.id }) {
            selectedUserIndexPath = IndexPath(row: row, section: 0)
        } else if let row = inactiveUsers.firstIndex(where: { $0.id == selectedUser?.id })  {
            selectedUserIndexPath = IndexPath(row: row, section: 1)
        }
        if let selectedUserIndexPath = selectedUserIndexPath, selectedUserIndexPath != indexPath {
            indexPaths.append(selectedUserIndexPath)
        }
        
        // Select / Unselect a user.
        if user.hasStream && user.id != selectedUser?.id {
            selectedUser = user
        } else {
            selectedUser = nil
        }
        
        // Reload collection view.
        collectionView.reloadItems(at: indexPaths)
        
        // Update selected user.
        delegate?.selectedUserUpdated(user: selectedUser)
    }
}

extension VTUXUsersViewController: UICollectionViewDelegateFlowLayout {
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
            let numberOfItems = CGFloat(activeUsers.count + inactiveUsers.count)
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
