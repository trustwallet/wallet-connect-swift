//
//  WCTrustBalance.swift
//  WalletConnect
//
//  Created by Leone Parise on 25/06/19.
//

import Foundation

public struct WCTrustBalanceParams: Codable {
    public let network: UInt32
    public let address: String
}

public struct WCTrustBalance: Codable {
    public let token: WCToken
    public let address: String
    public let balance: UInt64

    public init(token: WCToken, address: String, balance: UInt64) {
        self.token = token
        self.address = address
        self.balance = balance
    }
}
