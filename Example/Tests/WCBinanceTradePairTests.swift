// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import WalletConnect

class WCBinanceTradePairTests: XCTestCase {

    func testParsing() {
        let symbol = "BNB_ETH.B-261"
        let pair = WCBinanceTradePair.from(symbol)

        XCTAssertEqual(pair?.from, "BNB")
        XCTAssertEqual(pair?.to, "ETH.B")

        let symbol2 = "000-0E1_BNB"
        let pair2 = WCBinanceTradePair.from(symbol2)

        XCTAssertEqual(pair2?.from, "000")
        XCTAssertEqual(pair2?.to, "BNB")

        let symbol3 = "CRYPRICE-150_BTC.B-918"
        let pair3 = WCBinanceTradePair.from(symbol3)

        XCTAssertEqual(pair3?.from, "CRYPRICE")
        XCTAssertEqual(pair3?.to, "BTC.B")
    }
}
