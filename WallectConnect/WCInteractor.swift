//
//  WCInteractor.swift
//  WallectConnect
//
//  Created by Tao Xu on 3/29/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation
import Starscream
import PromiseKit

public class WCInteractor {
    public let session: WCSession

    let clientId: String
    let clientMeta: WCClientMeta
    let socket: WebSocket
    var handshakeId: Int64 = -1
    var pingTimer: Timer?

    var peerId: String?
    var peerMeta: WCClientMeta?

    public init(session: WCSession, meta: WCClientMeta) {
        self.session = session
        self.clientId = UUID().description
        self.clientMeta = meta
        self.socket = WebSocket.init(url: session.bridge)

        socket.onConnect = { [weak self] in self?.onConnect() }
        socket.onText = { [weak self] text in self?.onReceiveMessage(text: text) }

        socket.onPong = { _ in print("<== pong") }
        socket.onData = { data in print("<== websocketDidReceiveData: \(data.toHexString())") }
        socket.onDisconnect = { [weak pingTimer] error in
            print("<== websocketDidDisconnect, error: \(error.debugDescription)")
            pingTimer?.invalidate()
        }
    }

    deinit {
        pingTimer?.invalidate()
        socket.disconnect()
    }

    public func connect() {
        socket.connect()
    }

    public func approveSession(accounts: [String], chainId: Int) {
        let request = WCSessionUpdateRequest(approved: true, chainId: chainId, accounts: accounts)
        sendResponse(request)
    }

    public func rejectSession() {

    }

    public func killSession() {

    }

    public func approveRequest() {

    }
}

extension WCInteractor {
    private func subscribe(topic: String) {
        let message = WCSocketMessage(topic: topic, type: .sub, payload: "")
        let data = try! JSONEncoder().encode(message)
        socket.write(data: data)
        print("==> subscribe: \(String(data: data, encoding: .utf8)!)")
    }

    private func exchangeKey() {
        
    }

    private func sendResponse(_ request: WCSessionUpdateRequest) {
        let id = handshakeId > 0 ? handshakeId : generateId()
        let response = JSONRPCResponse(id: id, result: request)
        let data = try! JSONEncoder().encode(response)
        print("==> encrypt: \(String(data: data, encoding: .utf8)!) ")
        return encryptAndSend(data: data)
    }

    private func encryptAndSend(data: Data) {
        let encoder = JSONEncoder()
        let payload = try! WCEncryptor.encrypt(data: data, with: session.key)
        let payloadString = encoder.encodeAsUTF8(payload)
        let message = WCSocketMessage(topic: peerId ?? session.topic, type: .pub, payload: payloadString)
        let data = try! JSONEncoder().encode(message)
        socket.write(data: data) {
            print("==> \(String(data: data, encoding: .utf8)!) ")
        }
    }

    private func handleEvent(_ event: WCEvent, id: Int, decrypted: Data) {
        switch event {
        case .sessionRequest:
            handshakeId = Int64(id)
            let params = try? JSONDecoder().decode(JSONRPCRequest<[WCSessionRequestParam]>.self, from: decrypted).params.first
            peerId = params?.peerId
            peerMeta = params?.peerMeta
        default:
            break
        }
    }
}
extension WCInteractor {

    private func onConnect() {
        print("<== websocketDidConnect")
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak socket] _ in
            print("==> ping")
            socket?.write(ping: Data())
        })
        subscribe(topic: session.topic)
    }

    private func onReceiveMessage(text: String) {
        print("<== websocketDidReceiveMessage: \(text)")
        guard let payload = WCEncryptionPayload.extract(text) else {
            return
        }
        do {
            let decrypted = try WCEncryptor.decrypt(payload: payload, with: session.key)
            guard let json = try JSONSerialization.jsonObject(with: decrypted, options: [])
                as? [String: Any] else {
                throw WCError.badServerResponse
            }
            print("<== decrypted: \(String(data: decrypted, encoding: .utf8)!)")
            if let method = json["method"] as? String,
                let id = json["id"] as? Int,
                let event = WCEvent(rawValue: method) {
                handleEvent(event, id: id, decrypted: decrypted)
            }
        } catch let error {
            print(error)
        }
    }
}
