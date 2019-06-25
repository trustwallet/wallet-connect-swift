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
    public let type: WCTokenType
    public let symbol: String
    public let decimals: Int

    public init(type: WCTokenType, symbol: String, decimals: Int) {
        self.type = type
        self.symbol = symbol
        self.decimals = decimals
    }
}

public enum WCTokenType {
    case erc20(address: String)
    case coin(slip44: UInt32)
}

extension WCTokenType: Codable {
    private enum CodingKeys: String, CodingKey {
        case erc20
        case coin
    }

    enum WCTokenTypeCodingError: Error {
        case decoding(String)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(String.self, forKey: .erc20) {
            self = .erc20(address: value)
            return
        }

        if let value = try? values.decode(UInt32.self, forKey: .coin) {
            self = .coin(slip44: value)
            return
        }

        throw WCTokenTypeCodingError.decoding("Fail to decode: \(dump(values))")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .erc20(let value):
            try container.encode(value, forKey: .erc20)
        case .coin(let value):
            try container.encode(value, forKey: .coin)
        }
    }
}
