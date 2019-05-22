//
//  WCBinanceOrderParam.swift
//  WalletConnect
//
//  Created by Tao Xu on 4/2/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public protocol WCBinanceOrder {
    var encoded: Data { get }
    var encodedString: String { get }
}

public protocol WCBinanceOrderMessage: WCBinanceOrder {
    associatedtype Message
    var account_number: String { get }
    var chain_id: String { get }
    var data: String? { get }
    var memo: String { get }
    var msgs: [Message] { get }
    var sequence: String { get }
    var source: String { get }
}

public struct WCBinanceOrderSignature: Codable {
    public let signature: String
    public let publicKey: String

    public init(signature: String, publicKey: String) {
        self.signature = signature
        self.publicKey = publicKey
    }
}

public struct WCBinanceTxConfirmParam: Codable {
    public let ok: Bool
    public let errorMsg: String?
}
