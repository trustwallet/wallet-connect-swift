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
import TrustWalletCore

class ViewController: UIViewController {

    @IBOutlet weak var uriField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var chainIdField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var approveButton: UIButton!

    var interactor: WCInteractor!
    let clientMeta = WCPeerMeta(name: "WallectConnect SDK", url: "https://github.com/WalletConnect/swift-walletconnect-lib")

    let ethAccount = "0x5Ee066cc1250E367423eD4Bad3b073241612811f"
    let privateKey = PrivateKey(data: Data(hexString: "ba005cd605d8a02e3d5dfd04234cef3a3ee4f76bfbad2722d1fb5af8e12e6764")!)!

    override func viewDidLoad() {
        super.viewDidLoad()

        let string = "wc:117efa7b-1a9e-4a96-b3f1-451f987b586a@1?bridge=https%3A%2F%2Fwallet-bridge.fdgahl.cn&key=f159e109f8453cad7295e937383bb6526999968a58b79c8286b6adb94f8c64f3"

        uriField.text = string
        addressField.text = TendermintAddress(hrp: .binanceTest, publicKey: privateKey.getPublicKeySecp256k1(compressed: true))?.description
        chainIdField.text = "1"
        approveButton.isEnabled = false
    }

    func connect(session: WCSession) {
        interactor = WCInteractor(session: session, meta: clientMeta)
        interactor.onEthSign = { [weak self] params in
            let signed = "0x88089fa09f170b0c5173bccbe41fda6a11af5005678a601b2ac494d70f203e413b056ffbd1721137c2b400ee95139bb259f37d0e86579351e7e9e6774aa242ef1c"
            let alert = UIAlertController(title: "eth_sign", message: params[1], preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { _ in
                print(signed)
            }))
            self?.show(alert, sender: nil)
        }
        interactor.connect().done { [weak self] connected in
            self?.approveButton.isEnabled = connected
            self?.connectButton.setTitle(!connected ? "Connect" : "Disconnect", for: .normal)
        }.cauterize()
    }

    func approve(accounts: [String], chainId: Int) {
        interactor.approveSession(accounts: accounts, chainId: chainId)
    }

    @IBAction func connectTapped() {
        guard let string = uriField.text, let session = WCSession(string: string) else {
            print("invalid uri: \(String(describing: uriField.text))")
            return
        }
        if let i = interactor, i.connected {
            i.killSession().done {  [weak self] in
                self?.approveButton.isEnabled = false
                self?.connectButton.setTitle("Connect", for: .normal)
            }.cauterize()
        } else {
            connect(session: session)
        }
    }

    @IBAction func approveTapped() {
        guard let address = addressField.text,
            let chainIdString = chainIdField.text else {
            print("empty address or chainId")
            return
        }
        guard let chainId = Int(chainIdString) else {
            print("invalid chainId")
            return
        }
        guard EthereumAddress.isValidString(string: address) || TendermintAddress.isValidString(string: address) else {
            print("invalid eth or bnb address")
            return
        }
        approve(accounts: [address], chainId: chainId)
    }
}
