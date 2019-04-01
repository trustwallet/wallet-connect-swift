//
//  WCEncryptorTests.swift
//  WallectConnectTests
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import XCTest
import WallectConnect

class WCEncryptorTests: XCTestCase {
    func testDecrypt() throws {
        let data = "1b3db3674de082d65455eba0ae61cfe7e681c8ef1132e60c8dbd8e52daf18f4fea42cc76366c83351dab6dca52682ff81f828753f89a21e1cc46587ca51ccd353914ffdd3b0394acfee392be6c22b3db9237d3f717a3777e3577dd70408c089a4c9c85130a68c43b0a8aadb00f1b8a8558798104e67aa4ff027b35d4b989e7fd3988d5dcdd563105767670be735b21c4"
        let hmac = "a33f868e793ca4fcca964bcb64430f65e2f1ca7a779febeaf94c5373d6df48b3"
        let iv = "89ef1d6728bac2f1dcde2ef9330d2bb8"
        let key = Data(hex: "5caa3a74154cee16bd1b570a1330be46e086474ac2f4720530662ef1a469662c")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)

        let expect =  """
{"id":1554098597199736,"jsonrpc":"2.0","method":"wc_sessionUpdate","params":[{"approved":false,"chainId":null,"accounts":null}]}
"""
        XCTAssertEqual(expect, String(data: decrypted, encoding: .utf8)!)
    }
}
