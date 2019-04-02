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
    public var connected: Bool {
        return socket.isConnected
    }

    public let clientId: String
    public let clientMeta: WCPeerMeta


    public var onEthSign: (([String]) -> Void)?

    private let socket: WebSocket
    private var handshakeId: Int64 = -1
    private var pingTimer: Timer?

    var peerId: String?
    var peerMeta: WCPeerMeta?

    var connectResolvers: [Resolver<Bool>] = []

    public init(session: WCSession, meta: WCPeerMeta) {
        self.session = session
        self.clientId = (UIDevice.current.identifierForVendor ?? UUID()).description.lowercased()
        self.clientMeta = meta
        self.socket = WebSocket.init(url: session.bridge)

        socket.onConnect = { [weak self] in self?.onConnect() }
        socket.onDisconnect = { [weak self] error in self?.onDisconnect(error: error) }
        socket.onText = { [weak self] text in self?.onReceiveMessage(text: text) }
        socket.onPong = { _ in print("<== pong") }
        socket.onData = { data in print("<== websocketDidReceiveData: \(data.toHexString())") }
    }

    deinit {
        disconnect()
    }

    public func connect() -> Promise<Bool> {
        if socket.isConnected {
            return Promise.value(true)
        }
        socket.connect()
        return Promise<Bool> { [weak self] seal in
            self?.connectResolvers.append(seal)
        }
    }

    public func disconnect() {
        pingTimer?.invalidate()
        socket.disconnect()
        connectResolvers = []
    }

    public func approveSession(accounts: [String], chainId: Int) {
        guard handshakeId > 0 else {
            return
        }
        let result = WCApproveSessionResponse(
            approved: true,
            chainId: chainId,
            accounts: accounts,
            peerId: clientId,
            peerMeta: clientMeta
        )
        let response = JSONRPCResponse(id: handshakeId, result: result)
        let data = try! JSONEncoder().encode(response)
        return encryptAndSend(data: data)
    }

    public func rejectSession() {

    }

    public func killSession() -> Promise<Void> {
        let result = WCSessionUpdateParam(approved: false, chainId: nil, accounts: nil)
        let response = JSONRPCRequest(id: generateId(), method: WCEvent.sessionUpdate.rawValue, params: [result])
        let data = try! JSONEncoder().encode(response)
        return Promise { seal in
            encryptAndSend(data: data) {
                seal.fulfill(())
            }
        }
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

    private func encryptAndSend(data: Data, completion: (() -> Void)? = nil) {
        print("==> encrypt: \(String(data: data, encoding: .utf8)!) ")
        let encoder = JSONEncoder()
        let payload = try! WCEncryptor.encrypt(data: data, with: session.key)
        let payloadString = encoder.encodeAsUTF8(payload)
        let message = WCSocketMessage(topic: peerId ?? session.topic, type: .pub, payload: payloadString)
        let data = try! JSONEncoder().encode(message)
        socket.write(data: data) {
            print("==> sent \(String(data: data, encoding: .utf8)!) ")
            completion?()
        }
    }



    private func handleEvent(_ event: WCEvent, topic: String, decrypted: Data) {
        do {
            switch event {
            case .sessionRequest:
                // topic == session.topic
                let request: JSONRPCRequest<[WCSessionRequestParam]> = try event.decode(decrypted)
                guard let params = request.params.first else {
                    throw WCError.badJSONRPCRequest
                }
                handshakeId = request.id
                peerId = params.peerId
                peerMeta = params.peerMeta
            case .ethSign:
                // topic == clientId
                let request: JSONRPCRequest<[String]> = try event.decode(decrypted)
                onEthSign?(request.params)
            case .bnbSign:
                // topic == clientId
                break
            case .sessionUpdate:
                // topic == clientId
                let request: JSONRPCRequest<[WCSessionUpdateParam]> = try event.decode(decrypted)
                guard let param = request.params.first else {
                    throw WCError.badJSONRPCRequest
                }
                if param.approved == false {
                    disconnect()
                }
            default:
                break
            }
        } catch let error {
            print("==> handleEvent error: \(error.localizedDescription)")
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
        subscribe(topic: clientId)
        connectResolvers.forEach { $0.fulfill(true) }
        connectResolvers = []
    }

    private func onDisconnect(error: Error?) {
        print("<== websocketDidDisconnect, error: \(error.debugDescription)")
        pingTimer?.invalidate()
        if let error = error {
            connectResolvers.forEach { $0.reject(error) }
        } else {
            connectResolvers.forEach { $0.fulfill(false) }
        }
        connectResolvers = []
    }

    private func onReceiveMessage(text: String) {
        print("<== receive: \(text)")
        guard let (topic, payload) = WCEncryptionPayload.extract(text) else {
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
                let event = WCEvent(rawValue: method) {
                handleEvent(event, topic: topic, decrypted: decrypted)
            }
        } catch let error {
            print(error)
        }
    }
}
