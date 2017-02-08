//
//  ViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/6/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import Quickblox
import QuickbloxWebRTC
import SystemConfiguration
import MobileCoreServices

class ViewController: UIViewController, QBRTCClientDelegate {

    var session: QBRTCSession?
    var videoCapture: QBRTCCameraCapture?
    
    @IBOutlet weak var opponentVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let alan = false
        
        usernameLabel.text = alan ? "Alan" : "Sean"
        let userEmail = alan ? "alan.scarpa+thirty@gmail.com" : "seaneats@gmail.com"
        let userPassword = alan ? "alan1234" : "seaneats"
        // let userID: NSNumber = alan ? 23716786 : 23754827
        
        QBRequest.logIn(withUserEmail: userEmail, password: userPassword, successBlock: { [weak self] (response, user) in
            print(response)
            guard let strongSelf = self else { return }
            guard let user = user else { return }
            
            let currentUser = strongSelf.createUserWithID(user.id, password: userPassword)
            
            QBChat.instance().connect(with: currentUser) { [weak self] error in
                if error != nil {
                    print(error!)
                } else {
                    print("logged in!")
                    guard let strongSelf = self else { return }
                    strongSelf.startQuickBloxSession { complete in
                        if complete {
                            if alan {
                                self?.callUserWithID(23754827)
                            }
                        } else {
                            print("unable to start session")
                        }
                    }
                }
            }
        }) { (error) in
            print(error)
        }
    }

    func startQuickBloxSession(completion: @escaping (Bool) -> Void) {
        // Initialize QuickbloxWebRTC and configure signaling
        // You should call this method before any interact with QuickbloxWebRTC
        QBRTCClient.initializeRTC()
        QBRTCClient.instance().add(self)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            startLocalVideo { complete in
                completion(complete)
            }
        }
    }
    
    func startLocalVideo(completion: @escaping (Bool) -> Void) {
        let videoFormat = QBRTCVideoFormat.init()
        videoFormat.frameRate = 30
        videoFormat.pixelFormat = QBRTCPixelFormat.format420f
        videoFormat.width = 640
        videoFormat.height = 480
        // QBRTCCameraCapture class used to capture frames using AVFoundation APIs
        self.videoCapture = QBRTCCameraCapture.init(videoFormat: videoFormat, position: AVCaptureDevicePosition.front)
        
        
        self.session?.localMediaStream.videoTrack.isEnabled = true
        // add video capture to session's local media stream
        // from version 2.3 you no longer need to wait for 'initializedLocalMediaStream:' delegate to do it
        self.session?.localMediaStream.videoTrack.videoCapture = self.videoCapture
        
        self.videoCapture?.previewLayer.frame = self.localVideoView.bounds
        self.videoCapture?.startSession({ [weak self] in
            guard let strongSelf = self else { return }
            guard let previewLayer = strongSelf.videoCapture?.previewLayer else { return }
            strongSelf.localVideoView.layer.insertSublayer(previewLayer, at: 0)
            completion(true)
        })
    }
    
    func callUserWithID(_ id: NSNumber) {
        let opponentsIDs: [NSNumber] = [id]
        let newSession = QBRTCClient.instance().createNewSession(withOpponents: opponentsIDs, with: QBRTCConferenceType.video)
        // userInfo - the custom user information dictionary for the call. May be nil.
        let userInfo :[String:String] = ["key":"value"]
        newSession.startCall(userInfo)
    }
    
    func endQuickBloxSession() {
        // Call this method when you finish your work with QuickbloxWebRTC
        QBRTCClient.deinitializeRTC()
    }
    
    // MARK: QBRTCClientDelegate
    
    func didReceiveNewSession(_ session: QBRTCSession, userInfo: [String : String]? = nil) {
        if self.session != nil {
            // we already have a video/audio call session, so we reject another one
            // userInfo - the custom user information dictionary for the call from caller. May be nil.
            let userInfo :[String:String] = ["key":"value"]
            session.rejectCall(userInfo)
        }
        else {
            self.session = session
            acceptCall(userInfo)
        }
    }
    
    //Called in case when receive remote video track from opponent
    func session(_ session: QBRTCSession, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack, fromUser userID: NSNumber) {
        guard session == self.session else { return }
        // we suppose you have created UIView and set it's class to QBRTCRemoteVideoView class
        // also we suggest you to set view mode to UIViewContentModeScaleAspectFit or
        // UIViewContentModeScaleAspectFill
        
        // TODO: use later maybe let videoTrack = QBRTCSession.remoteVideoTrack(session)
        
        opponentVideoView.setVideoTrack(videoTrack)
    }
    
    func session(_ session: QBRTCSession, acceptedByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        print("call accepted")
        
        
    }
    
    func session(_ session: QBRTCSession, connectedToUser userID: NSNumber) {
        print("connected")
    }
    
    func session(_ session: QBRTCSession, disconnectedFromUser userID: NSNumber) {
        print("disconnected")
    }
    
    func session(_ session: QBRTCSession, connectionFailedForUser userID: NSNumber) {
        print("connection failed")
    }
    
    func session(_ session: QBRTCSession, userDidNotRespond userID: NSNumber) {
        print("user did not respond before timeout")
    }
    
    func session(_ session: QBRTCSession, didChange state: QBRTCConnectionState, forUser userID: NSNumber) {
        print(state.rawValue)
    }
    
    func sessionDidClose(_ session: QBRTCSession) {
        print("closed session")
    }
    
    // MARK: Helpers
    
    func createUserWithID(_ id: UInt, password: String) -> QBUUser {
        let user = QBUUser()
        user.id = id
        user.password = password
        return user
    }
    
    func acceptCall(_ userInfo: [String:String]?) {
        // userInfo - the custom user information dictionary for the accept call. May be nil.
        self.session?.acceptCall(userInfo)
    }
    
}

