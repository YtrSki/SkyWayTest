//
//  StreamViewController.swift
//  SkyWay Test
//
//  Created by YutaroSakai on 2020/10/04.
//
//  参考URL: https://blog.dreamonline.co.jp/2020/05/01/skywaywebrtcアプリ開発/
//

import Foundation
import UIKit
import SkyWay

class StreamViewController: UIViewController {
    
    fileprivate var peer: SKWPeer?
    fileprivate var mediaConnection: SKWMediaConnection?
    fileprivate var localStream: SKWMediaStream?
    fileprivate var remoteStream: SKWMediaStream?
    
    @IBOutlet weak var remoteStreamView: SKWVideo!
    @IBOutlet weak var localStreamView: SKWVideo!
    @IBOutlet weak var callButton: UIButton!
    @IBAction func tabCall(_ sender: Any) {
        guard let peer = self.peer else {
            print("tabCall()にて、peerが存在しない")
            return
        }
        
        if(!self.isCalling()) {
            peer.listAllPeers({ (peers) -> Void in
                guard let allPeerIds = peers as? [String] else {
                    print("tapCall()にて、peer IDが存在しない")
                    return
                }
                let targetPeerIds = allPeerIds.filter({ (peerId) -> Bool in
                    return peerId != peer.identity
                })
                if targetPeerIds.count != 0 {
                    let alert = UIAlertController.init(title: nil, message: "接続先を選択する", preferredStyle: .alert)
                    for targetPeerId in targetPeerIds {
                        let action = UIAlertAction(title: targetPeerId, style: .default, handler: { (action) in
                            self.call(targetPeerId)
                        })
                        alert.addAction(action)
                    }
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController.init(title: nil, message: "接続先が見つかりません", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
        } else {
            self.endCall()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let option: SKWPeerOption = SKWPeerOption.init()
        option.key = "4ef87046-d284-414f-9b6b-4b5ab9d4d961"
        option.domain = "localhost"
        
        if let peer = SKWPeer(options: option) {
            SKWNavigator.initialize(peer)
            self.setupPeerCallBacks(peer)
            self.peer = peer
        } else {
            print("peerの初期化に失敗")
        }
        
        //  MARK: getUserMediaで映像取得
        let constraints:SKWMediaConstraints = SKWMediaConstraints()
        self.localStream = SKWNavigator.getUserMedia(constraints)
    }
    
    func setupPeerCallBacks(_ peer: SKWPeer) {
        //シグナリングサーバとの接続が確立された時のイベント
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN, callback: { (obj) -> Void in
            if let peerId = obj as? String {
                print("自分のpeerIDは「\(peerId)」")
            }
        })
        
        //リモートピアからのメディア接続が発生した時のイベント
        peer.on(SKWPeerEventEnum.PEER_EVENT_CALL, callback: { (obj) -> Void in
            if let connection = obj as? SKWMediaConnection {
                self.setMediaConnectionCallBacks(connection)
                self.mediaConnection = connection
                self.updateCallState()
                connection.answer(self.localStream)
            }
        })
        
        //エラーが発生した時のイベント
        peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR, callback: { (obj) -> Void in
            if let error = obj as? SKWPeerError {
                print("コールバックあたりでエラー発生")
            }
        })
    }
    
    func call(_ targetPeerId: String) {
        let option = SKWCallOption()
        if let mediaConnection = self.peer?.call(withId: targetPeerId, stream: self.localStream, options: option) {
            self.setMediaConnectionCallBacks(mediaConnection)
            self.mediaConnection = mediaConnection
            self.updateCallState()
        } else {
            print("call()にて、\(targetPeerId)に対して発信できない")
        }
    }
    
    func endCall() {
        self.mediaConnection?.close()
    }
    
    func updateCallState() {
        if (!self.isCalling()) {
            self.callButton.setTitle("開始", for: .normal)
            self.callButton.setTitleColor(.green, for: .normal)
        } else {
            self.callButton.setTitle("終了", for: .normal)
            self.callButton.setTitleColor(.red, for: .normal)
        }
    }
    
    func isCalling() -> Bool {
        return self.mediaConnection != nil
    }
    
    func setMediaConnectionCallBacks(_ mediaConnection: SKWMediaConnection) {
        // リモートメディアストリームを追加された時のイベント
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM, callback: { (obj) -> Void in
            if let mediaStream = obj as? SKWMediaStream {
                self.remoteStream = mediaStream
                DispatchQueue.main.async {
                    self.remoteStream?.addVideoRenderer(self.remoteStreamView, track: 0) //相手の映像をビューに映し出す
                    self.localStream?.addVideoRenderer(self.localStreamView, track: 0) //自分の映像をビューに映し出す
                }
            }
        })
        // メディアコネクションが閉じられた時のイベント
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE, callback: { (obj) -> Void in
            if let _ = obj as? SKWMediaConnection {
                DispatchQueue.main.async {
                    self.remoteStream?.removeVideoRenderer(self.remoteStreamView, track: 0)
                    self.remoteStream = nil
                    self.mediaConnection = nil
                    self.updateCallState()
                    self.localStream?.removeVideoRenderer(self.localStreamView, track: 0)
                }
            }
        })
        // エラーが発生したときのイベント
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_ERROR) { (obj) in
            if let error = obj as? SKWPeerError {
                print("\(error)")
            }
        }
    }
}
