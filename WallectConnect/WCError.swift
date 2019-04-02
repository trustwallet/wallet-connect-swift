//
//  WCError.swift
//  WallectConnect
//
//  Created by Tao Xu on 3/30/19.
//  Copyright © 2019 Trust. All rights reserved.
//

import Foundation

public enum WCError: Error {
    case badServerResponse
    case badJSONRPCRequest
    case unknown
}
