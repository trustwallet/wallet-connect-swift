//
//  WCEvent.swift
//  WallectConnect
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public enum WCEvent: String {
    case sessionRequest = "wc_sessionRequest"
    case sessionUpdate = "wc_sessionUpdate"
    case exchangeKey = "wc_exchangeKey"

    case bnbSign = "bnb_sign"
    case ethSign = "eth_sign"
}

extension WCEvent {
    func decode<T: Codable>(_ data: Data) throws -> JSONRPCRequest<T> {
        return try JSONDecoder().decode(JSONRPCRequest<T>.self, from: data)
    }
}
