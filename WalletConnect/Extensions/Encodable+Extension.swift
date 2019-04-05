//
//  Encodable+Extension.swift
//  WallectConnect
//
//  Created by Tao Xu on 4/1/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public extension Encodable {
    var encoded: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(self)
    }
    var description: String {
        return String(data: encoded, encoding: .utf8)!
    }
}
