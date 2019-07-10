// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public struct WCSessionManager {

    struct Cache: Codable {
        let session: WCSession
        let peer: WCPeerMeta
    }

    static let prefix = "org.walletconnect.sessions"

    static var allSessions: [String: Cache] {
        let sessions: [String: Cache] = UserDefaults.standard.codableValue(forKey: prefix) ?? [:]
        return sessions
    }

    public static func store(_ session: WCSession, peer: WCPeerMeta) {
        var sessions = allSessions
        sessions[session.topic] = Cache(session: session, peer: peer)
        store(sessions)
    }

    public static func load(_ topic: String) -> (session: WCSession, peer: WCPeerMeta)? {
        guard let item = allSessions[topic] else { return nil }
        return (item.session, item.peer)
    }

    public static func clear( _ topic: String) {
        var sessions = allSessions
        sessions.removeValue(forKey: topic)
        store(sessions)
    }

    public static func clearAll() {
        store([:])
    }

    private static func store(_ sessions: [String: Cache]) {
        let data = try? JSONEncoder().encode(sessions)
        UserDefaults.standard.setCodable(sessions, forKey: prefix)
    }
}

extension UserDefaults {
    func setCodable<T: Codable>(_ value: T, forKey: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: forKey)
    }

    func codableValue<T: Codable>(forKey: String) -> T? {
        guard let data = data(forKey: forKey),
            let value = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return value
    }
}
