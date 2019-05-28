//
//  ViewController.swift
//  WalletConnectApp
//
//  Created by Tao Xu on 3/29/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import UIKit
import WalletConnect
import PromiseKit
import TrustWalletCore

class ViewController: UIViewController {

    @IBOutlet weak var uriField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var chainIdField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var approveButton: UIButton!

    var interactor: WCInteractor?
    let clientMeta = WCPeerMeta(name: "WalletConnect SDK", url: "https://github.com/TrustWallet/wallet-connect-swift")

    let privateKey = PrivateKey(data: Data(hexString: "ba005cd605d8a02e3d5dfd04234cef3a3ee4f76bfbad2722d1fb5af8e12e6764")!)!

    var defaultAddress: String = ""
    var defaultChainId: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        let string = "wc:dad7a19e-d6e9-45fe-ba5f-f2116841d3c6@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=6c56b56a08ff026f3bf56a30aa971fa4b1b3064563fe8d91755190c3037aea04"

        defaultAddress = CoinType.ethereum.deriveAddress(privateKey: privateKey)
        uriField.text = string
        addressField.text = defaultAddress
        chainIdField.text = "1"
        chainIdField.textAlignment = .center
        approveButton.isEnabled = false
    }

    func connect(session: WCSession) {
        print("==> session", session)
        let interactor = WCInteractor(session: session, meta: clientMeta)

        configure(interactor: interactor)

        interactor.connect().done { [weak self] connected in
            self?.connectionStatusUpdated(connected)
        }.cauterize()

        self.interactor = interactor
    }

    func configure(interactor: WCInteractor) {
        let accounts = [defaultAddress]
        let chainId = defaultChainId

        interactor.onError = { [weak self] error in
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.show(alert, sender: nil)
        }

        interactor.onSessionRequest = { [weak self] (id, peer) in
            let message = [peer.description, peer.url].joined(separator: "\n")
            let alert = UIAlertController(title: peer.name, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
                self?.interactor?.rejectSession().cauterize()
            }))
            alert.addAction(UIAlertAction(title: "Approve", style: .default, handler: { _ in
                self?.interactor?.approveSession(accounts: accounts, chainId: chainId).cauterize()
            }))
            self?.show(alert, sender: nil)
        }

        interactor.onDisconnect = { [weak self] (error) in
            self?.connectionStatusUpdated(false)
        }

        interactor.onEthSign = { [weak self] (id, payload) in
            let alert = UIAlertController(title: payload.method, message: payload.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { _ in
                self?.signEth(id: id, payload: payload)
            }))
            self?.show(alert, sender: nil)
        }

        interactor.onEthTransaction = { [weak self] (id, event, transaction) in
            let data = try! JSONEncoder().encode(transaction)
            let message = String(data: data, encoding: .utf8)
            let alert = UIAlertController(title: event.rawValue, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
                self?.interactor?.rejectRequest(id: id, message: "I don't have ethers").cauterize()
            }))
            self?.show(alert, sender: nil)
        }

        interactor.onBnbSign = { [weak self] (id, order) in
            let message = order.encodedString
            let alert = UIAlertController(title: "bnb_sign", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { [weak self] _ in
                self?.signBnbOrder(id: id, order: order)
            }))
            self?.show(alert, sender: nil)
        }
    }

    func approve(accounts: [String], chainId: Int) {
        interactor?.approveSession(accounts: accounts, chainId: chainId).done {
            print("<== approveSession done")
        }.cauterize()
    }

    func signEth(id: Int64, payload: WCEthereumSignPayload) {
        let data: Data = {
            switch payload {
                case .sign(let data, _):
                    return data
                case .personalSign(let data, _):
                    let prefix = "\u{19}Ethereum Signed Message:\n\(data)".data(using: .utf8)!
                    return prefix + data
                case .signTypeData(let data, _):
                    // FIXME
                    return data
            }
        }()

        var result = privateKey.sign(digest: Hash.keccak256(data: data), curve: .secp256k1)!
        result[64] += 27
        self.interactor?.approveRequest(id: id, result: result.hexString).cauterize()
    }

    func signBnbOrder(id: Int64, order: WCBinanceOrder) {
        let data = order.encoded
        print("==> signbnbOrder", String(data: data, encoding: .utf8)!)
        let signature = privateKey.sign(digest: Hash.sha256(data: data), curve: .secp256k1)!
        let signed = WCBinanceOrderSignature(
            signature: signature.dropLast().hexString,
            publicKey: privateKey.getPublicKeySecp256k1(compressed: false).data.hexString
        )
        interactor?.approveBnbOrder(id: id, signed: signed).done({ confirm in
            print("<== approveBnbOrder", confirm)
        }).cauterize()
    }

    func connectionStatusUpdated(_ connected: Bool) {
        self.approveButton.isEnabled = connected
        self.connectButton.setTitle(!connected ? "Connect" : "Disconnect", for: .normal)
    }

    @IBAction func connectTapped() {
        guard let string = uriField.text, let session = WCSession.from(string: string) else {
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
        guard EthereumAddress.isValidString(string: address) || CosmosAddress.isValidString(string: address) else {
            print("invalid eth or bnb address")
            return
        }
        approve(accounts: [address], chainId: chainId)
    }
}
