//
//  WCTrustAccount.swift
//  WalletConnect
//
//  Created by Leone Parise on 25/06/19.
//

import Foundation

public struct WCTrustAccount: Codable {
    public let token: WCToken
    public let address: String
    public let amount: UInt64

    public init(token: WCToken, address: String, amount: UInt64) {
        self.token = token
        self.address = address
        self.amount = amount
    }
}

public struct WCToken: Codable {
    public let network: Int32
    public let symbol: String
    public let decimals: Int

    public init(network: Int32, symbol: String, decimals: Int) {
        self.network = network
        self.symbol = symbol
        self.decimals = decimals
    }
}
