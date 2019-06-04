// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

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
