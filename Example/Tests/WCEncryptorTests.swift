// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
@testable import WalletConnect

// swiftlint:disable line_length
class WCEncryptorTests: XCTestCase {
    func testDecrypt() throws {
        let data = "1b3db3674de082d65455eba0ae61cfe7e681c8ef1132e60c8dbd8e52daf18f4fea42cc76366c83351dab6dca52682ff81f828753f89a21e1cc46587ca51ccd353914ffdd3b0394acfee392be6c22b3db9237d3f717a3777e3577dd70408c089a4c9c85130a68c43b0a8aadb00f1b8a8558798104e67aa4ff027b35d4b989e7fd3988d5dcdd563105767670be735b21c4"
        let hmac = "a33f868e793ca4fcca964bcb64430f65e2f1ca7a779febeaf94c5373d6df48b3"
        let iv = "89ef1d6728bac2f1dcde2ef9330d2bb8"
        let key = Data(hex: "5caa3a74154cee16bd1b570a1330be46e086474ac2f4720530662ef1a469662c")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let request = try JSONDecoder().decode(JSONRPCRequest<[WCSessionUpdateParam]>.self, from: decrypted)

        let expect =  """
{"id":1554098597199736,"jsonrpc":"2.0","method":"wc_sessionUpdate","params":[{"approved":false,"chainId":null,"accounts":null}]}
"""
        XCTAssertEqual(expect, String(data: decrypted, encoding: .utf8)!)
        XCTAssertEqual(request.method, "wc_sessionUpdate")
        XCTAssertEqual(request.params[0].approved, false)
    }

    func testDecryptSessionRequest() throws {
        // wc:a87335bc-0c1d-4c2e-ac12-1cf4fc003563@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=8c146479c3c9c387b848db8d0eb09145f17c88c86453c10b2963a74d6f916868
        let data = "5d2e92b0b64a014eef5bf3637ddbc66a70a6bd48630234dc02f1256089e8e6f50a014518e9f1a79c52f22eeda3821bfad1b2cc13ef905360a25b9573a1ed236d6cf9cd5c6b835a9272fca8ba24ce34b7842620dfd4cbe215443a17555f70dadc4831f3b87776e18b05c5204f6c93a20060a818b3fd809c1353f394dc78e4138e4c4e300740bbd7e62b453b76446f49dcbed329a1f0a7a5b7f4505735bd5488dd0aecb54d204797351166634c483431555fe212d56b83dcb1cb709da824f50fe62dcffa05116ba3b7cc82d72649135255bb88f5c99aacc526e5e40b135db7d65cc3b034cdc46c305ba10498d8967a4525243cbb6a6f7cc9c7c7ded4546c2a0aa5eb82b80121e314493ac897304cfb1d7ac491d54ea728c5e99bffee379369ca2a"
        let hmac = "34079117b417d80d7bef3c95b2affe0bfcd82435afc484e7826275f780885369"
        let iv = "7ba596e01aa6695a410320b372e8695b"
        let key = Data(hex: "8c146479c3c9c387b848db8d0eb09145f17c88c86453c10b2963a74d6f916868")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let request: JSONRPCRequest<[WCSessionRequestParam]> = try WCEvent.sessionRequest.decode(decrypted)
        XCTAssertNotNil(request.params.first)
        XCTAssertNil(request.params.first?.chainId)
    }

    func testDecryptSessionRequestChainId() throws {
        // wc:d3175406-811b-4463-bcfd-0570481c8d7f@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=6a91eb9cc4322209224b97e81894bcec7474712659dd1bd26d72841065684706
        let data = "36ec99546b080c3d49762fde911818e1804e861b5bccfd02c66191fd97ff56afb7bc3d73d7441f7e5587b24674e8c5b9bd963aa2645be137d961cb40f5222440d184e1f1da5a546f3b70f8d26083a6355c0af3b544a8b21d7bbf1353a77ff44078ad84167fc8747fc187a8b4c56034321c76c6fe5637622dc412407bfa6f198b9bc6d7cac8d89833de8a9edf7ad69e40004c5af5cfaae8aae2787132cbfab22ae2481f16a9b6af96a67f54c5d5868219d809197acd6c5b6c944c8617cce80d7ed45db6a8d78a8a4bd047652047c85985682f7c47e588348a492a11aa0ea5f287b5c6b796bf3c51465eef9ed3723555d0765d5116f87f987d2838fc54731d3f9e43dd4d82e7c043df31a358a6dce8715459681277c6cb097e1faf2e24735c8689e7caa5b29f155c552e7f86e7ddd23fff0ce95839f757f9dc244272f75e3cdd5cda209bff64d8ff2c770fa692964468ef5cea6ba3e9943acbbf133e18de242565864666b2f5341b5dae9a716568d4ad39b5be851e834a51473ad79ac7f737d1e9025314066c13f0ddec851f5d0bc5121c94727e823edfa423e43f9a9d59bfe86f07500375b33650acb2ef0668670169f59585f7ee12be42094d2279e2a1064f56bedf4ecb59099f8cb7a0d19fa150e7aff83566dd74deaec8fc1726a8b11ae14d23d977256896e1f801a6ad77b097aa7ec2c86b252893c181aff9edf9c58740fb"
        let hmac = "86a2b0425f7c84337d9639f8ca07de0a67b2fc1e65bc5cd88fc3739c0693738e"
        let iv = "b2560b9f092ee90afd492c8b900f5835"
        let key = Data(hex: "6a91eb9cc4322209224b97e81894bcec7474712659dd1bd26d72841065684706")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let request: JSONRPCRequest<[WCSessionRequestParam]> = try WCEvent.sessionRequest.decode(decrypted)
        XCTAssertNotNil(request.params.first)
        XCTAssertEqual(request.params.first?.chainId, 1)
    }

    func testDecryptRejectSession() throws {
        // wc:3c5318c3-fba2-4e57-bca3-854e7ac9c51e@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=bbc82a01ebdb14698faee4a9e5038de72c995a9f6bcdb21903d62408b0c5ca96
        let data = "e7df9810ce66defcc03023ee945f5958c1d4697bf97945daeab5059c2bc6262642cbca82982ac690e77e16671770c200f348f743a7c6e5df5c74eb892ef9b45a9b5ddf0f08fa60c49e5b694688d1b0b521b43975e65b4e8d557a83f4d1aab0af"
        let hmac = "ffcf0f43aeb0ef36dd2ea641ab7f48b9abbf2d9f65354aefc7faf530d318a9fe"
        let iv = "debb62725b21c7577e4e498e10f096c7"
        let key = Data(hex: "bbc82a01ebdb14698faee4a9e5038de72c995a9f6bcdb21903d62408b0c5ca96")
        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let rpcError = try JSONDecoder().decode(JSONRPCErrorResponse.self, from: decrypted)

        let expect = """
{"jsonrpc":"2.0","id":1554343834752446,"error":{"code":-32000,"message":"Session Rejected"}}
"""
        XCTAssertEqual(expect, String(data: decrypted, encoding: .utf8)!)
        XCTAssertEqual(rpcError.error.code, -32000)
    }

    func testDecryptBnbSign() throws {
        // topic: e7f48633-b2d5-43de-ab0a-f83a451a079c
        // key: 10b653558be908057c2584b93d27cb0a6d020aa4520af9fef036dd0fec324668
        let data = "9e3a3590371e27596745ac4665d4e50d148804413b7fc1ea2b7f4866562ce7c61d5cd21e7c442edd41f20de891a87988c89e28458cba5051aabd74cab0e700fffcd9a383e05292c2053eb256a4e98c435b72359e189f6a9374489a6e6aef6d8356d183cf358c81ce532a21dd27f594981ab0e1f1d8fb0545a4dc6fa626bc891590d4d673e7d876b7684913c9134fb52870c4beb057a55deb7c8e7b3d237ff4b41287744d8f41fa74ee253d0d1a7833965191172ae2cc814dda53e599eb4dbb41c1c60416c2385af38f0093a9dec97e4892a9f7793d24b43d087fa1ee549bc7037269cb19f68e32dae38ac695197c389c04fa043273f29abe0d0aee6933f237488361e0a4415e2e41541dd068304bd6051e099d3fbc909d9c237694c858080e461ceceabb3cb06048b5ac9b2944a28b7a516308f2e1ff9089bbcd3ead12066edcabc8fb8b28e40fa6ffb7943bfbb9fa8695324104798489724e1328d3000cb7bb0518f64117c5b871b282ac6bb3d1e213f4e82137402e6fd69478b145a5b5f059"
        let hmac = "d910de5672d1506129ad35709fa0d7c4618814605e8529385b089f899a99b574"
        let iv = "7cfdc41e3b2bee432a196770bb644865"
        let key = Data(hex: "10b653558be908057c2584b93d27cb0a6d020aa4520af9fef036dd0fec324668")

        let payload = WCEncryptionPayload(data: data, hmac: hmac, iv: iv)
        let decrypted = try WCEncryptor.decrypt(payload: payload, with: key)
        let request: JSONRPCRequest<[WCBinanceTradeOrder]> = try WCEvent.bnbSign.decode(decrypted)

        let expected = """
{"id":1,"jsonrpc":"2.0","method":"bnb_sign","params":[{"account_number":"666682","chain_id":"Binance-Chain-Nile","data":null,"memo":"","msgs":[{"id":"A9241D9CDC41DBFF587A236047D5836EDA6C7345-1","ordertype":2,"price":401180,"quantity":2500000000,"sender":"tbnb14yjpm8xug8dl7kr6ydsy04vrdmdxcu69kwrw78","side":2,"symbol":"BNB_BTC.B-918","timeinforce":1}],"sequence":"0","source":"1"}]}
"""
        XCTAssertEqual(request.encodedString, expected)
    }
}
// swiftlint:enable line_length
