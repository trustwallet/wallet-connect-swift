//
//  ViewController.swift
//  WalletConnectApp
//
//  Created by Tao Xu on 3/29/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import UIKit
import WallectConnect
import PromiseKit

class ViewController: UIViewController {
    var interactor: WCInteractor!
    let accounts = ["0x6e4d387c925a647844623762aB3C4a5B3acd9540", /*"tbnb1hlly02l6ahjsgxw9wlcswnlwdhg4xhx3f309d9"*/]

    override func viewDidLoad() {
        super.viewDidLoad()

        let string = "wc:c914f6dc-38ba-4f65-933a-aafbfad1b8cc@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=e02cb29f4901ae43e5d0b23cf8167838aeb981d92efeaa213e78b8b7a31d16da"

        let session = WCSession(string: string)!

        interactor = WCInteractor(
            session: session,
            meta: WCClientMeta(name: "WallectConnect SDK", url: "https://github.com/WalletConnect/swift-walletconnect-lib")
        )
        interactor.connect()
    }

    @IBAction func connectTapped() {
        self.interactor.approveSession(accounts: accounts, chainId: 3)
    }
}
