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
public typealias EthSignClosure = (_ id: Int64, _ payload: WCEthereumSignPayload) -> Void
public typealias EthTransactionClosure = (_ id: Int64, _ event: WCEvent, _ transaction: WCEthereumTransaction) -> Void
public typealias BnbSignClosure = (_ id: Int64, _ order: WCBinanceOrder) -> Void
public typealias CustomRequestClosure = (_ id: Int64, _ request: [String: Any]) -> Void
public typealias ErrorClosure = (Error) -> Void
public typealias TransactionSignClosure = (_ id: Int64, _ transaction: WCTrustTransaction) -> Void
public typealias TrustGetAccountsClosure = (_ id: Int64) -> Void

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    items.forEach {
        Swift.print($0, separator: separator, terminator: terminator)
    }
    #endif
}

open class WCInteractor {
    public let session: WCSession
    public var connected: Bool {
        return socket.isConnected
    }

    public let clientId: String
    public let clientMeta: WCPeerMeta

    // incoming event handlers
    public var onSessionRequest: SessionRequestClosure?
    public var onDisconnect: DisconnectClosure?
    public var onEthSign: EthSignClosure?
    public var onEthTransaction: EthTransactionClosure?
    public var onBnbSign: BnbSignClosure?
    public var onCustomRequest: CustomRequestClosure?
    public var onTrustTransactionSign: TransactionSignClosure?
    public var onError: ErrorClosure?
    public var onTrustGetAccounts: TrustGetAccountsClosure?

    // outgoing promise resolvers
    var connectResolver: Resolver<Bool>?
    var bnbTxConfirmResolvers: [Int64: Resolver<WCBinanceTxConfirmParam>] = [:]

    private let socket: WebSocket
    private var handshakeId: Int64 = -1
    private var pingTimer: Timer?

    private var peerId: String?
    private var peerMeta: WCPeerMeta?

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
            return Promise(error: WCError.invalidSession)
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
            return Promise(error: WCError.invalidSession)
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
                    self?.bnbTxConfirmResolvers[id] = seal
                }
            }
    }

    open func approveRequest(id: Int64, result: String) -> Promise<Void> {
        let response = JSONRPCResponse(id: id, result: result)
        return encryptAndSend(data: response.encoded)
    }

    open func rejectRequest(id: Int64, message: String) -> Promise<Void> {
        let response = JSONRPCErrorResponse(id: id, error: JSONRPCError(code: -32000, message: message))
        return encryptAndSend(data: response.encoded)
    }
}

extension WCInteractor {
    private func subscribe(topic: String) {
        let message = WCSocketMessage(topic: topic, type: .sub, payload: "")
        let data = try! JSONEncoder().encode(message)
        socket.write(data: data)
        print("==> subscribe: \(String(data: data, encoding: .utf8)!)")
    }

    private func encryptAndSend(data: Data) -> Promise<Void> {
        print("==> encrypt: \(String(data: data, encoding: .utf8)!) ")
        let encoder = JSONEncoder()
        let payload = try! WCEncryptor.encrypt(data: data, with: session.key)
        let payloadString = encoder.encodeAsUTF8(payload)
        let message = WCSocketMessage(topic: peerId ?? session.topic, type: .pub, payload: payloadString)
        let data = message.encoded
        return Promise { seal in
            socket.write(data: data) {
                print("==> sent \(String(data: data, encoding: .utf8)!) ")
                seal.fulfill(())
            }
        }
    }

    private func handleEvent(_ event: WCEvent, topic: String, decrypted: Data) throws {
        switch event {
        // topic == session.topic
        case .sessionRequest:
            let request: JSONRPCRequest<[WCSessionRequestParam]> = try event.decode(decrypted)
            guard let params = request.params.first else { throw WCError.badJSONRPCRequest }
            handshakeId = request.id
            peerId = params.peerId
            peerMeta = params.peerMeta
            onSessionRequest?(request.id, params.peerMeta)
        // topic == clientId
        case .ethSign, .ethPersonalSign, .ethSignTypeData:
            let request: JSONRPCRequest<[String]> = try event.decode(decrypted)
            guard request.params.count > 1 else { throw WCError.badJSONRPCRequest }
            let payload: WCEthereumSignPayload = {
                if event == .ethSign {
                    return .sign(data: Data(hex: request.params[1]), raw: request.params)
                } else if event == .ethPersonalSign {
                    return .personalSign(data: Data(hex: request.params[0]), raw: request.params)
                } else if event == .ethSignTypeData {
                    let data = request.params[0].data(using: .utf8) ?? Data()
                    return .signTypeData(data: data, raw: request.params)
                } else {
                    fatalError()
                }
            }()
            onEthSign?(request.id, payload)
        case .ethSendTransaction, .ethSignTransaction:
            let request: JSONRPCRequest<[WCEthereumTransaction]> = try event.decode(decrypted)
            guard !request.params.isEmpty else { throw WCError.badJSONRPCRequest }
            onEthTransaction?(request.id, event, request.params[0])
        case .bnbSign:
            if let request: JSONRPCRequest<[WCBinanceTradeOrder]> = try? event.decode(decrypted) {
                onBnbSign?(request.id, request.params[0])
            } else if let request: JSONRPCRequest<[WCBinanceCancelOrder]> = try? event.decode(decrypted) {
                onBnbSign?(request.id, request.params[0])
            } else if let request: JSONRPCRequest<[WCBinanceTransferOrder]> = try? event.decode(decrypted) {
                onBnbSign?(request.id, request.params[0])
            }
        case .bnbTransactionConfirm:
            let request: JSONRPCRequest<[WCBinanceTxConfirmParam]> = try event.decode(decrypted)
            guard !request.params.isEmpty else { throw WCError.badJSONRPCRequest }
            bnbTxConfirmResolvers[request.id]?.fulfill(request.params[0])
            bnbTxConfirmResolvers[request.id] = nil
        case .sessionUpdate:
            let request: JSONRPCRequest<[WCSessionUpdateParam]> = try event.decode(decrypted)
            guard let param = request.params.first else { throw WCError.badJSONRPCRequest }
            if param.approved == false {
                disconnect()
            }
        case .trustSignTransacation:
            let request: JSONRPCRequest<[WCTrustTransaction]> = try event.decode(decrypted)
            guard !request.params.isEmpty else { throw WCError.badJSONRPCRequest }
            onTrustTransactionSign?(request.id, request.params[0])
        case .trustGetAccounts:
            let request: JSONRPCRequest<[String]> = try event.decode(decrypted)
            onTrustGetAccounts?(request.id)        
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
        connectResolver?.fulfill(true)
        connectResolver = nil
    }

    private func onDisconnect(error: Error?) {
        print("<== websocketDidDisconnect, error: \(error.debugDescription)")
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
        print("<== receive: \(text)")
        guard let (topic, payload) = WCEncryptionPayload.extract(text) else { return }
        do {
            let decrypted = try WCEncryptor.decrypt(payload: payload, with: session.key)
            guard let json = try JSONSerialization.jsonObject(with: decrypted, options: [])
                as? [String: Any] else {
                throw WCError.badJSONRPCRequest
            }
            print("<== decrypted: \(String(data: decrypted, encoding: .utf8)!)")
            if let method = json["method"] as? String {
                if let event = WCEvent(rawValue: method) {
                    try handleEvent(event, topic: topic, decrypted: decrypted)
                } else if let id = json["id"] as? Int64 {
                    onCustomRequest?(id, json)
                }
            }
        } catch let error {
            onError?(error)
            print("==> onReceiveMessage error: \(error.localizedDescription)")
        }
    }
}
