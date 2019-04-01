
//
//  WCSessionUpdate.swift
//  WallectConnect
//
//  Created by Tao Xu on 3/29/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public struct WCExchangeKeyParam: Codable {
    let peerId: String
    let peerMeta: WCClientMeta
    let nextKey: String
}

public struct WCSessionRequestParam: Codable {
    let peerId: String
    let peerMeta: WCClientMeta
    let chainId: String?
}

public struct WCSessionUpdateRequest: Codable {
    public let approved: Bool
    public let chainId: Int
    public let accounts: [String]
}
