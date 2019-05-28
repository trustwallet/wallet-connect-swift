//
//  WCEthereumSignType.swift
//  WalletConnect
//
//  Created by Tao Xu on 5/29/19.
//

import Foundation

public enum WCEthereumSignPayload {
    case sign(data: Data, raw: [String])
    case personalSign(data: Data, raw: [String])
    case signTypeData(data: Data, raw: [String])
}

public extension WCEthereumSignPayload {

    public var method: String {
        switch self {
        case .sign: return "eth_sign"
        case .personalSign: return "personal_sign"
        case .signTypeData: return "eth_signTypedData"
        }
    }

    public var message: String {
        switch self {
        case .sign(_, let raw):
            return raw[1]
        case .personalSign(let data, let raw):
            return String(data: data, encoding: .utf8) ?? raw[0]
        case .signTypeData(_, let raw):
            return raw[0]
        }
    }
}
