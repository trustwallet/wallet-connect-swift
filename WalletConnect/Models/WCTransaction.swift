//
//  WCTransaction.swift
//  CryptoSwift
//
//  Created by Leone Parise on 30/05/19.
//

import Foundation

public struct WCTransaction: Codable {
    public let network: UInt32
    public let transaction: String
}
