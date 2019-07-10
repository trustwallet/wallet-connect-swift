// Copyright © 2017-2019 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public struct WCSessionManager {

    static let prefix = "org.walletconnect.sessions"

    static var allSessions: [String: WCSession] {
        let sessions: [String: WCSession] = UserDefaults.standard.codableValue(forKey: prefix) ?? [:]
        return sessions
    }

    public static func store(_ session: WCSession) {
        var sessions = allSessions
        sessions[session.topic] = session
        store(sessions)
    }

    public static func load(_ topic: String) -> WCSession? {
        return allSessions[topic]
    }

    public static func clear( _ topic: String) {
        var sessions = allSessions
        sessions.removeValue(forKey: topic)
        store(sessions)
    }

    public static func clearAll() {
        store([:])
    }

    private static func store(_ sessions: [String: WCSession]) {
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
