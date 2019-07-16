// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import WalletConnect

func loadJSON(filename: String, extension: String? = "json", subdirectory: String? = "test_data") throws -> Data {
    let dataUrl = Bundle(for: WCSessionStoreTests.self).url(forResource: filename, withExtension: `extension`, subdirectory: subdirectory)!
    let data = try Data(contentsOf: dataUrl)
    return data
}

extension WCPeerMeta {
    static func mock() -> WCPeerMeta {
        let data = try! loadJSON(filename: "peer_meta")
        let peerMeta = try! JSONDecoder().decode(WCPeerMeta.self, from: data)
        return peerMeta
    }
}
