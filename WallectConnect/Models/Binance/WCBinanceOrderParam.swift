//
//  WCBinanceOrderParam.swift
//  WallectConnect
//
//  Created by Tao Xu on 4/2/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public struct WCBinanceOrderParam: Codable {
    public struct Message: Codable {
        public let id: String
        public let ordertype: Int
        public let price: Int
        public let quantity: Int64
        public let sender: String
        public let side: Int
        public let symbol: String
        public let timeinforce: Int
    }
    public let account_number: String
    public let chain_id: String
    public let memo: String
    public let msgs: [Message]
    public let sequence: String
    public let source: String
}

public struct WCBinanceOrderSigned: Codable {
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
