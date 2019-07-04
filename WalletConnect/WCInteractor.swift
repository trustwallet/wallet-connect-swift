// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import Starscream
import PromiseKit

public typealias SessionRequestClosure = (_ id: Int64, _ peer: WCPeerMeta) -> Void
public typealias DisconnectClosure = (Error?) -> Void
public typealias CustomRequestClosure = (_ id: Int64, _ request: [String: Any]) -> Void
public typealias ErrorClosure = (Error) -> Void

open class WCInteractor {
    public let session: WCSession
    public var connected: Bool {
        return socket.isConnected
    }

    public let clientId: String
    public let clientMeta: WCPeerMeta

    public var eth: WCEthereumInteractor
    public var bnb: WCBinanceInteractor
    public var trust: WCTrustInteractor

    // incoming event handlers
    public var onSessionRequest: SessionRequestClosure?
    public var onDisconnect: DisconnectClosure?
    public var onError: ErrorClosure?
    public var onCustomRequest: CustomRequestClosure?

    // outgoing promise resolvers
    private var connectResolver: Resolver<Bool>?

    private let socket: WebSocket
    private var handshakeId: Int64 = -1
    private var pingTimer: Timer?
    private var sessionTimer: Timer?

    private var peerId: String?
    private var peerMeta: WCPeerMeta?

    public init(session: WCSession, meta: WCPeerMeta) {
        self.session = session
        self.clientId = (UIDevice.current.identifierForVendor ?? UUID()).description.lowercased()
        self.clientMeta = meta
        self.socket = WebSocket.init(url: session.bridge)

        self.eth = WCEthereumInteractor()
        self.bnb = WCBinanceInteractor()
        self.trust = WCTrustInteractor()

        socket.onConnect = { [weak self] in self?.onConnect() }
        socket.onDisconnect = { [weak self] error in self?.onDisconnect(error: error) }
        socket.onText = { [weak self] text in self?.onReceiveMessage(text: text) }
        socket.onPong = { _ in WCLog("<== pong") }
        socket.onData = { data in WCLog("<== websocketDidReceiveData: \(data.toHexString())") }
    }

    deinit {
        disconnect()
    }

    open func connect() -> Promise<Bool> {
        if socket.isConnected {
            return Promise.value(true)
        }
        socket.connect()
        return Promise<Bool> { [weak self] seal in
            self?.connectResolver = seal
        }
    }

    open func disconnect() {
        pingTimer?.invalidate()
        socket.disconnect()
        connectResolver = nil
        handshakeId = -1
    }

    open func approveSession(accounts: [String], chainId: Int) -> Promise<Void> {
        guard handshakeId > 0 else {
            return Promise(error: WCError.sessionInvalid)
        }
        let result = WCApproveSessionResponse(
            approved: true,
            chainId: chainId,
            accounts: accounts,
            peerId: clientId,
            peerMeta: clientMeta
        )
        let response = JSONRPCResponse(id: handshakeId, result: result)
        return encryptAndSend(data: response.encoded)
    }

    open func rejectSession(_ message: String = "Session Rejected") -> Promise<Void> {
        guard handshakeId > 0 else {
            return Promise(error: WCError.sessionInvalid)
        }
        let response = JSONRPCErrorResponse(id: handshakeId, error: JSONRPCError(code: -32000, message: message))
        return encryptAndSend(data: response.encoded)
    }

    open func killSession() -> Promise<Void> {
        let result = WCSessionUpdateParam(approved: false, chainId: nil, accounts: nil)
        let response = JSONRPCRequest(id: generateId(), method: WCEvent.sessionUpdate.rawValue, params: [result])
        return encryptAndSend(data: response.encoded)
            .map { [weak self] in
            self?.disconnect()
        }
    }

    open func approveBnbOrder(id: Int64, signed: WCBinanceOrderSignature) -> Promise<WCBinanceTxConfirmParam> {
        let result = signed.encodedString
        return approveRequest(id: id, result: result)
            .then { _ -> Promise<WCBinanceTxConfirmParam> in
                return Promise { [weak self] seal in
                    self?.bnb.confirmResolvers[id] = seal
                }
            }
    }

    open func approveRequest<T: Codable>(id: Int64, result: T) -> Promise<Void> {
        let response = JSONRPCResponse(id: id, result: result)
        return encryptAndSend(data: response.encoded)
    }

    open func rejectRequest(id: Int64, message: String) -> Promise<Void> {
        let response = JSONRPCErrorResponse(id: id, error: JSONRPCError(code: -32000, message: message))
        return encryptAndSend(data: response.encoded)
    }
}

// MARK: internal funcs
extension WCInteractor {
    private func subscribe(topic: String) {
        let message = WCSocketMessage(topic: topic, type: .sub, payload: "")
        let data = try! JSONEncoder().encode(message)
        socket.write(data: data)
        WCLog("==> subscribe: \(String(data: data, encoding: .utf8)!)")
    }

    private func encryptAndSend(data: Data) -> Promise<Void> {
        WCLog("==> encrypt: \(String(data: data, encoding: .utf8)!) ")
        let encoder = JSONEncoder()
        let payload = try! WCEncryptor.encrypt(data: data, with: session.key)
        let payloadString = encoder.encodeAsUTF8(payload)
        let message = WCSocketMessage(topic: peerId ?? session.topic, type: .pub, payload: payloadString)
        let data = message.encoded
        return Promise { seal in
            socket.write(data: data) {
                WCLog("==> sent \(String(data: data, encoding: .utf8)!) ")
                seal.fulfill(())
            }
        }
    }

    private func handleEvent(_ event: WCEvent, topic: String, decrypted: Data) throws {
        switch event {
        case .sessionRequest:
            // topic == session.topic
            let request: JSONRPCRequest<[WCSessionRequestParam]> = try event.decode(decrypted)
            guard let params = request.params.first else { throw WCError.badJSONRPCRequest }
            handshakeId = request.id
            peerId = params.peerId
            peerMeta = params.peerMeta
            onSessionRequest?(request.id, params.peerMeta)
        case .sessionUpdate:
            // topic == clientId
            let request: JSONRPCRequest<[WCSessionUpdateParam]> = try event.decode(decrypted)
            guard let param = request.params.first else { throw WCError.badJSONRPCRequest }
            if param.approved == false {
                disconnect()
            }
        default:
            if WCEvent.eth.contains(event) {
                try eth.handleEvent(event, topic: topic, decrypted: decrypted)
            } else if WCEvent.bnb.contains(event) {
                try bnb.handleEvent(event, topic: topic, decrypted: decrypted)
            } else if WCEvent.trust.contains(event) {
                try trust.handleEvent(event, topic: topic, decrypted: decrypted)
            }
        }
    }
}

// MARK: WebSocket event handler
extension WCInteractor {
    private func onConnect() {
        WCLog("<== websocketDidConnect")
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak socket] _ in
            WCLog("==> ping")
            socket?.write(ping: Data())
        }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
        }
        subscribe(topic: session.topic)
        subscribe(topic: clientId)
        connectResolver?.fulfill(true)
        connectResolver = nil
    }

    private func onDisconnect(error: Error?) {
        WCLog("<== websocketDidDisconnect, error: \(error.debugDescription)")
        pingTimer?.invalidate()
        if let error = error {
            connectResolver?.reject(error)
        } else {
            connectResolver?.fulfill(false)
        }
        connectResolver = nil
        onDisconnect?(error)
    }

    private func onReceiveMessage(text: String) {
        WCLog("<== receive: \(text)")
        guard let (topic, payload) = WCEncryptionPayload.extract(text) else { return }
        do {
            let decrypted = try WCEncryptor.decrypt(payload: payload, with: session.key)
            guard let json = try JSONSerialization.jsonObject(with: decrypted, options: [])
                as? [String: Any] else {
                throw WCError.badJSONRPCRequest
            }
            WCLog("<== decrypted: \(String(data: decrypted, encoding: .utf8)!)")
            if let method = json["method"] as? String {
                if let event = WCEvent(rawValue: method) {
                    try handleEvent(event, topic: topic, decrypted: decrypted)
                } else if let id = json["id"] as? Int64 {
                    onCustomRequest?(id, json)
                }
            }
        } catch let error {
            onError?(error)
            WCLog("==> onReceiveMessage error: \(error.localizedDescription)")
        }
    }
}
