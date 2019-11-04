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

    // swiftlint:disable line_length
    func testDecodeTypedData() throws {
        let data = try loadJSON(filename: "sign_typed")
        let payload = try JSONDecoder().decode(WCEthereumSignPayload.self, from: data)
        if case .signTypeData(let id, let data, let raw) = payload {
            XCTAssertEqual(id, 1572863361304726)
            XCTAssertEqual(payload.method, "eth_signTypedData")
            XCTAssertEqual(raw[0], "0x7d8bf18C7cE84b3E175b339c4Ca93aEd1dD166F1")
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return XCTFail("fail to decode eth sign typed data")
            }
            XCTAssertEqual(json["primaryType"] as? String, "Mail")
        } else {
            XCTFail("faild to decode eth sign typed data")
        }
    }

    func testDecodeTypedDataString() throws {
        let data = try loadJSON(filename: "sign_typed_string")
        let payload = try JSONDecoder().decode(WCEthereumSignPayload.self, from: data)
        if case .signTypeData(_, let data, let raw) = payload {
            XCTAssertEqual(payload.method, "eth_signTypedData")
            XCTAssertEqual(data.toHexString(), "7b227479706573223a7b22454950373132446f6d61696e223a5b7b226e616d65223a226e616d65222c2274797065223a22737472696e67227d2c7b226e616d65223a2276657273696f6e222c2274797065223a22737472696e67227d2c7b226e616d65223a22636861696e4964222c2274797065223a2275696e74323536227d2c7b226e616d65223a22766572696679696e67436f6e7472616374222c2274797065223a2261646472657373227d5d2c22506572736f6e223a5b7b226e616d65223a226e616d65222c2274797065223a22737472696e67227d2c7b226e616d65223a226163636f756e74222c2274797065223a2261646472657373227d5d2c224d61696c223a5b7b226e616d65223a2266726f6d222c2274797065223a22506572736f6e227d2c7b226e616d65223a22746f222c2274797065223a22506572736f6e227d2c7b226e616d65223a22636f6e74656e7473222c2274797065223a22737472696e67227d5d7d2c227072696d61727954797065223a224d61696c222c22646f6d61696e223a7b226e616d65223a224578616d706c652044617070222c2276657273696f6e223a22312e302e302d62657461222c22636861696e4964223a312c22766572696679696e67436f6e7472616374223a22307830303030303030303030303030303030303030303030303030303030303030303030303030303030227d2c226d657373616765223a7b2266726f6d223a7b226e616d65223a22416c696365222c226163636f756e74223a22307861616161616161616161616161616161616161616161616161616161616161616161616161616161227d2c22746f223a7b226e616d65223a22426f62222c226163636f756e74223a22307862626262626262626262626262626262626262626262626262626262626262626262626262626262227d2c22636f6e74656e7473223a224865792c20426f6221227d7d")
            XCTAssertEqual(raw[0], "0x7d8bf18C7cE84b3E175b339c4Ca93aEd1dD166F1")
        } else {
            XCTFail("faild to decode eth sign typed data")
        }
    }
    // swiftlint:enable line_length
}
