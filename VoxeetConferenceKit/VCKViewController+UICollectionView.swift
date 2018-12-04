//
//  VCKViewController+UICollectionView.swift
//  VoxeetConferenceKit
//
//  Created by Coco on 16/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import Foundation
import VoxeetSDK

extension VCKViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VoxeetSDK.shared.conference.users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! VCKViewControllerUserCell
        
        // Get user.
        guard VoxeetSDK.shared.conference.users.count >= indexPath.row else {
            return cell
        }
        let user = VoxeetSDK.shared.conference.users[indexPath.row]
        
        // Cell data.
        if let avatarURL = user.avatarURL {
            cell.avatar.kf.setImage(with: URL(string: avatarURL))
        } else {
            cell.avatar.image = UIImage(named: "UserPlaceholder", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
        cell.name.text = user.name
        
        // Cell alpha.
        cell.avatar.alpha = 0.4
        cell.name.alpha = cell.avatar.alpha
        
        // Cell border property.
        cell.avatar.layer.borderColor = UIColor(red: 41/255, green: 162/255, blue: 251/255, alpha: 1).cgColor
        cell.videoRenderer.layer.borderColor = cell.avatar.layer.borderColor
        if let userID = user.id, userID == selectedUser?.id {
            cell.avatar.layer.borderWidth = 2
        } else {
            cell.avatar.layer.borderWidth = 0
        }
        cell.videoRenderer.layer.borderWidth = cell.avatar.layer.borderWidth
        
        // User is currently in conference.
        if user.asStream {
            // Update cell alpha.
            cell.avatar.alpha = 1
            cell.name.alpha = cell.avatar.alpha
            
            // Update cell's user.
            cell.user = user
            
            // Attach a video stream.
            if let userID = user.id, let stream = VoxeetSDK.shared.conference.mediaStream(userID: userID), !stream.videoTracks.isEmpty {
                cell.videoRenderer.isHidden = false
                VoxeetSDK.shared.conference.attachMediaStream(stream, renderer: cell.videoRenderer)
            }
        }
        
        return cell
    }
}

extension VCKViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = VoxeetSDK.shared.conference.users[indexPath.row]
        
        // Select / unselect a user.
        if let userID = user.id, user.status == .connected, userID != selectedUser?.id {
            var indexPaths = [indexPath]
            // Reload old selected user's cell.
            if let selectedUserID = selectedUser?.id, let selectedUserIndex = VoxeetSDK.shared.conference.users.index(where: { $0.id == selectedUserID }) {
                let selectedUserIndexPath = IndexPath(item: selectedUserIndex, section: 0)
                indexPaths.append(selectedUserIndexPath)
            }
            
            // Reload collection view.
            selectedUser = user
            collectionView.reloadItems(at: indexPaths)
            
            // Set the new main avatar.
            updateMainUser(user: user)
            
            // Stop active speaker mode.
            activeSpeakerTimer?.invalidate()
        } else if selectedUser != nil {
            selectedUser = nil
            collectionView.reloadData()
            
            // Relaunch active speaker mode.
            resetActiveSpeakerTimer()
        }
    }
}

extension VCKViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: section))
        let combinedItemWidth = (numberOfItems * flowLayout.itemSize.width) + ((numberOfItems - 1) * flowLayout.minimumLineSpacing)
        let padding = (collectionView.frame.width - combinedItemWidth) / 2
        
        if padding >= minimizeButton.frame.width {
            return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: 0)
        } else {
            return UIEdgeInsets(top: 0, left: minimizeButton.frame.width, bottom: 0, right: 0)
        }
    }
}
