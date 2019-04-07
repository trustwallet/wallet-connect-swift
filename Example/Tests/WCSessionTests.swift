//
//  WCSessionTests.swift
//  WalletConnectTests
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import XCTest
import WalletConnect

class WCSessionTests: XCTestCase {

    func testParse() {
        let uri = "wc:217374f6-8735-472d-a743-23bd7d26d106@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=d565a3e6cc792fa789bbea26b3f257fb436cfba2de48d2490b3e0248168d4b6b"

        let session = WCSession.from(string: uri)

        XCTAssertNotNil(session)
        XCTAssertEqual(session?.topic, "217374f6-8735-472d-a743-23bd7d26d106")
        XCTAssertEqual(session?.version, "1")
        XCTAssertEqual(session?.bridge.description, "https://bridge.walletconnect.org")
        XCTAssertEqual(session?.key, Data(hex: "d565a3e6cc792fa789bbea26b3f257fb436cfba2de48d2490b3e0248168d4b6b") )
    }
}
