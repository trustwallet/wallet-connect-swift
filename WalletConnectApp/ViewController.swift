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

    var interactor: WCInteractor?
    let clientMeta = WCPeerMeta(name: "WallectConnect SDK", url: "https://github.com/WalletConnect/swift-walletconnect-lib")

    let privateKey = PrivateKey(data: Data(hexString: "ba005cd605d8a02e3d5dfd04234cef3a3ee4f76bfbad2722d1fb5af8e12e6764")!)!

    override func viewDidLoad() {
        super.viewDidLoad()

        let string = "wc:eaf299d0-dbf5-4232-b870-864d232c54b0@1?bridge=https%3A%2F%2Fwallet-bridge.fdgahl.cn&key=5c6482fb8fced99e8dbb9c3b3114d0f90621546941cdd597e6b20b6cc3f90970"

        uriField.text = string
        addressField.text = CoinType.binance.deriveAddress(privateKey: privateKey)
//        addressField.text = CoinType.ethereum.deriveAddress(privateKey: privateKey)
        chainIdField.text = "1"
        approveButton.isEnabled = false
    }

    func connect(session: WCSession) {
        print("==> session", session)
        let interactor = WCInteractor(session: session, meta: clientMeta)

        interactor.onEthSign = { [weak self] (id, params) in
            let alert = UIAlertController(title: "eth_sign", message: params[1], preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { _ in
                let signed = "0x745e32f38f7ac950bd00cd6522428f8658951ba6c1174cba561b866af023bb8279c77924e87edbc46d693a13f72721c251cfdda5ac47d53379b1fb6404eb12391b"
                self?.interactor?.approveRequest(id: id, result: signed).cauterize()
            }))
            self?.show(alert, sender: nil)
        }

        interactor.onEthSendTransaction = { [weak self] (id, params) in
            let data = try! JSONEncoder().encode(params[0])
            let message = String(data: data, encoding: .utf8)
            let alert = UIAlertController(title: "eth_sendTransaction", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
                self?.interactor?.rejectRequest(id: id, message: "I don't have ethers").cauterize()
            }))
            self?.show(alert, sender: nil)
        }

        interactor.onBnbSign = { [weak self] (id, params) in
            let data = try! JSONEncoder().encode(params[0])
            let message = String(data: data, encoding: .utf8)
            let alert = UIAlertController(title: "bnb_sign", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { [weak self] _ in
                self?.signBnbOrder(id: id, params: params)
            }))
            self?.show(alert, sender: nil)
        }

        interactor.connect().done { [weak self] connected in
            self?.approveButton.isEnabled = connected
            self?.connectButton.setTitle(!connected ? "Connect" : "Disconnect", for: .normal)
        }.cauterize()

        self.interactor = interactor
    }

    func approve(accounts: [String], chainId: Int) {
        interactor?.approveSession(accounts: accounts, chainId: chainId).done {
            print("<== approveSession done")
        }.cauterize()
    }

    func signBnbOrder(id: Int64, params: [WCBinanceOrderParam]) {
        let data = try! JSONEncoder().encode(params)
        let signature = privateKey.sign(digest: data, curve: .secp256k1)!
        let signed = WCBinanceOrderSigned(
            signature: signature.dropLast().hexString,
            publicKey: privateKey.getPublicKeySecp256k1(compressed: false).data.hexString
        )
        interactor?.approveBnbOrder(id: id, signed: signed).done({ confirm in
            print("<== approveBnbOrder", confirm)
        }).cauterize()
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
