// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import WalletConnect
import CryptoSwift

class WCEthereumSignPayloadTests: XCTestCase {

    func testDecodeSign() throws {
        let data = try loadJSON(filename: "eth_sign")
        let payload = try JSONDecoder().decode(WCEthereumSignPayload.self, from: data)
        if case .sign(let data, let raw) = payload {
            let messageData = Data(hex: "6dee0d861fb7e0da1b3cd046816981b1150b60f409d648a5b6d85d3fce00642c")
            XCTAssertEqual(payload.method, "eth_sign")
            XCTAssertEqual(Data(hex: payload.message), messageData)
            XCTAssertEqual(data, messageData)
            XCTAssertEqual(raw[0], "0xD432C5910f626dD21bE918D782facB38BDaE3296")
        } else {
            XCTFail("faild to decode eth sign data")
        }
    }

    func testDecodePersonal() throws {
        let data = try loadJSON(filename: "personal_sign")
        let payload = try JSONDecoder().decode(WCEthereumSignPayload.self, from: data)
        if case .personalSign(let data, let raw) = payload {
            XCTAssertEqual(payload.method, "personal_sign")
            XCTAssertEqual(payload.message, "My email is john@doe.com - 1537836206101")
            XCTAssertEqual(data.toHexString(), "4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031353337383336323036313031")
            XCTAssertEqual(raw[1], "0xD432C5910f626dD21bE918D782facB38BDaE3296")
        } else {
            XCTFail("faild to decode eth sign data")
        }
    }
}
