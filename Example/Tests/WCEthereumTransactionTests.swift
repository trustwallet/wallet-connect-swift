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
}
