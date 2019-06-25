//
//  WCTrustAccount.swift
//  WalletConnect
//
//  Created by Leone Parise on 25/06/19.
//

import Foundation

public struct WCTrustAccount: Codable {
    public let network: UInt32
    public let address: String

    public init(network: UInt32, address: String) {
        self.network = network
        self.address = address
    }
}
