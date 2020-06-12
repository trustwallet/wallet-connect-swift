// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
@testable import WalletConnect

class WCEthereumTransactionTests: XCTestCase {
    func testSendTransaction() throws {
        let data = try loadJSON(filename: "defisaver_send")
        let request = try JSONDecoder().decode(JSONRPCRequest<[WCEthereumTransaction]>.self, from: data)
        let tx = request.params.first!

        XCTAssertEqual(tx.from, "0x7d8bf18c7ce84b3e175b339c4ca93aed1dd166f1")
        XCTAssertEqual(tx.to, "0xb1ff153f0ecbd12433000314e2c9d2c6b9f9c214")
        XCTAssertEqual(tx.gasPrice, "0x10642ace9")
        XCTAssertEqual(tx.data.count, 458)
    }

    func testDecodeGas() throws {
        let jsonString = """
        {
            "from": "0xc36edf48e21cf395b206352a1819de658fd7f988",
            "gas": "0x77fb",
            "gasPrice": "0xb2d05e00",
            "nonce": "0x64",
            "to": "0x00000000000c2e074ec69a0dfb2997ba6c7d2e1e",
            "value": "0x0",
            "data": ""
        }
        """
        let tx = try JSONDecoder().decode(WCEthereumTransaction.self, from: jsonString.data(using: .utf8)!)
        XCTAssertEqual(tx.gas, "0x77fb")
    }
}
