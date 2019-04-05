//
//  WCEncryptorTests.swift
//  WalletConnectTests
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import XCTest
@testable import WalletConnect

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

    func testDecryptRejectSession() throws {
        // wc:3c5318c3-fba2-4e57-bca3-854e7ac9c51e@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=bbc82a01ebdb14698faee4a9e5038de72c995a9f6bcdb21903d62408b0c5ca96
        let data = "e7df9810ce66defcc03023ee945f5958c1d4697bf97945daeab5059c2bc6262642cbca82982ac690e77e16671770c200f348f743a7c6e5df5c74eb892ef9b45a9b5ddf0f08fa60c49e5b694688d1b0b521b43975e65b4e8d557a83f4d1aab0af"
        let hmac = "ffcf0f43aeb0ef36dd2ea641ab7f48b9abbf2d9f65354aefc7faf530d318a9fe"
        let iv = "debb62725b21c7577e4e498e10f096c7"
        let key = Data(hex: "bbc82a01ebdb14698faee4a9e5038de72c995a9f6bcdb21903d62408b0c5ca96")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)

        let expect =  """
{"jsonrpc":"2.0","id":1554343834752446,"error":{"code":-32000,"message":"Session Rejected"}}
"""
        XCTAssertEqual(expect, String(data: decrypted, encoding: .utf8)!)
    }

    func testDecryptBnbSign() throws {
        // wc:e7f48633-b2d5-43de-ab0a-f83a451a079c@1?bridge=https%3A%2F%2Fwallet-bridge.fdgahl.cn&key=10b653558be908057c2584b93d27cb0a6d020aa4520af9fef036dd0fec324668
        let data = "9e3a3590371e27596745ac4665d4e50d148804413b7fc1ea2b7f4866562ce7c61d5cd21e7c442edd41f20de891a87988c89e28458cba5051aabd74cab0e700fffcd9a383e05292c2053eb256a4e98c435b72359e189f6a9374489a6e6aef6d8356d183cf358c81ce532a21dd27f594981ab0e1f1d8fb0545a4dc6fa626bc891590d4d673e7d876b7684913c9134fb52870c4beb057a55deb7c8e7b3d237ff4b41287744d8f41fa74ee253d0d1a7833965191172ae2cc814dda53e599eb4dbb41c1c60416c2385af38f0093a9dec97e4892a9f7793d24b43d087fa1ee549bc7037269cb19f68e32dae38ac695197c389c04fa043273f29abe0d0aee6933f237488361e0a4415e2e41541dd068304bd6051e099d3fbc909d9c237694c858080e461ceceabb3cb06048b5ac9b2944a28b7a516308f2e1ff9089bbcd3ead12066edcabc8fb8b28e40fa6ffb7943bfbb9fa8695324104798489724e1328d3000cb7bb0518f64117c5b871b282ac6bb3d1e213f4e82137402e6fd69478b145a5b5f059"
        let hmac = "d910de5672d1506129ad35709fa0d7c4618814605e8529385b089f899a99b574"
        let iv = "7cfdc41e3b2bee432a196770bb644865"
        let key = Data(hex: "10b653558be908057c2584b93d27cb0a6d020aa4520af9fef036dd0fec324668")

        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let request: JSONRPCRequest<[WCBinanceTradeOrder]> = try WCEvent.bnbSign.decode(decrypted)
        XCTAssertNotNil(request)
    }
}
