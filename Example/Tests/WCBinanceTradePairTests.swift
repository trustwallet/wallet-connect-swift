//
//  WCBinanceTradePairTests.swift
//  WalletConnect_Tests
//
//  Created by Tao Xu on 4/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import WalletConnect

class WCBinanceTradePairTests: XCTestCase {

    func testParsing() {
        let symbol = "BNB_ETH.B-261"
        let pair = WCBinanceTradePair.from(symbol)!

        XCTAssertEqual(pair.from, "BNB")
        XCTAssertEqual(pair.to, "ETH.B")
    }
}
