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

    public init(token: WCToken, address: String) {
        self.token = token
        self.address = address
    }
}

public struct WCToken: Codable {
    public let network: UInt32
    public let name: String
    public let symbol: String
    public let decimals: Int

    public init(network: UInt32, name: String, symbol: String, decimals: Int) {
        self.network = network
        self.name = symbol
        self.symbol = symbol
        self.decimals = decimals
    }
}
