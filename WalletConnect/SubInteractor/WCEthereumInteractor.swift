// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public typealias EthSignClosure = (_ id: Int64, _ payload: WCEthereumSignPayload) -> Void
public typealias EthTransactionClosure = (_ id: Int64, _ event: WCEvent, _ transaction: WCEthereumTransaction) -> Void

public struct WCEthereumInteractor {
    public var onSign: EthSignClosure?
    public var onTransaction: EthTransactionClosure?

    func handleEvent(_ event: WCEvent, topic: String, decrypted: Data) throws {
        switch event {
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
            onSign?(request.id, payload)
        case .ethSendTransaction, .ethSignTransaction:
            let request: JSONRPCRequest<[WCEthereumTransaction]> = try event.decode(decrypted)
            guard !request.params.isEmpty else { throw WCError.badJSONRPCRequest }
            onTransaction?(request.id, event, request.params[0])
        default:
            break
        }
    }
}
