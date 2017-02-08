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
    @IBOutlet weak var opponentVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var localVideoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // alan
        // let user = createUserWithEmail("alan.scarpa+thirty@gmail.com", id: 23716786, password: "alan1234")
        
        // sean
        let user = createUserWithEmail("seaneats@gmail.com", id: 23754827, password: "seaneats")
        
        QBChat.instance().connect(with: user) { [weak self] error in
            if error != nil {
                print(error!)
            } else {
                print("logged in!")
                guard let strongSelf = self else { return }
                strongSelf.startQuickBloxSession()
                // strongSelf.callUserWithID(23754827)
            }
        }
        
    }
    
    func createUserWithEmail(_ email: String, id: UInt, password: String) -> QBUUser {
        let user = QBUUser()
        user.email = email
        user.id = id
        user.password = password
        return user
    }

    func startQuickBloxSession() {
        // Initialize QuickbloxWebRTC and configure signaling
        // You should call this method before any interact with QuickbloxWebRTC
        QBRTCClient.initializeRTC()
        QBRTCClient.instance().add(self)
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
        // we suppose you have created UIView and set it's class to QBRTCRemoteVideoView class
        // also we suggest you to set view mode to UIViewContentModeScaleAspectFit or
        // UIViewContentModeScaleAspectFill
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
    
    // MARK: Helpers
    
    func acceptCall(_ userInfo: [String:String]?) {
        // userInfo - the custom user information dictionary for the accept call. May be nil.
        self.session?.acceptCall(userInfo)
    }
    
}

