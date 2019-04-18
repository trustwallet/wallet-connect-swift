//
//  WCBinanceTradePair.swift
//  WalletConnect
//
//  Created by Tao Xu on 4/18/19.
//

import Foundation

public struct WCBinanceTradePair {
    public let from: String
    public let to: String

    public static func from(_ symbol: String) -> WCBinanceTradePair? {
        let pair = symbol.split(separator: "_")
        guard pair.count > 1 else { return nil }
        let parts = pair[1].split(separator: "-")
        guard parts.count > 1 else { return nil }
        return WCBinanceTradePair(from: String(pair[0]), to: String(parts[0]))
    }
}
