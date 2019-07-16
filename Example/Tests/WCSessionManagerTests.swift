// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import WalletConnect

class WCSessionStoreTests: XCTestCase {

    override func setUp() {
        let wcUri = "wc:f7fddc39-e4ab-4071-b51e-1b669244f516@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=65253a9f194c3eaa9c823f8db07736817a0b024db5b00eb2d7da58d59c1e1376"
        let session = WCSession.from(string: wcUri)!
        let peerId = "779ee67f-6dbf-4c47-8589-16f1bcdd8e68"

        WCSessionStore.store(session, peerId: peerId, peerMeta: .mock())
    }

    func testStore() {
        let wcUri = "wc:fcfecccf-4930-46b9-9f42-5648579c1658@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=4941e24abe9cce7822c17ebeadcd2f25a96b6e6904b9e4ec0942446ad5de8a18"
        let peerId = "309dc3d2-1d15-49fe-bef4-f708eb8c45de"
        let session = WCSession.from(string: wcUri)!

        WCSessionStore.store(session, peerId: peerId, peerMeta: .mock())
        XCTAssertNotNil(WCSessionStore.load(session.topic))

        WCSessionStore.clear(session.topic)
        XCTAssertNil(WCSessionStore.load(session.topic))
    }

    func testLoad() {
        let topic = "f7fddc39-e4ab-4071-b51e-1b669244f516"
        let item = WCSessionStore.load(topic)!

        XCTAssertEqual(item.session.topic, topic)
        XCTAssertEqual(item.peerId, "779ee67f-6dbf-4c47-8589-16f1bcdd8e68")
        XCTAssertEqual(item.peerMeta.name, "WalletConnect Example")
        XCTAssertEqual(item.peerMeta.url, "https://example.walletconnect.org")
    }

    func testClearAll() {
        let expect = self.expectation(description: "clear all sessions")

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            WCSessionStore.clearAll()
            XCTAssertNil(WCSessionStore.load("f7fddc39-e4ab-4071-b51e-1b669244f516"))
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
}
