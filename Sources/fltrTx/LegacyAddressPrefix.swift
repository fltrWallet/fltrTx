//===----------------------------------------------------------------------===//
//
// This source file is part of the fltrECC open source project
//
// Copyright (c) 2022 fltrWallet AG and the fltrECC project authors
// Licensed under Apache License v2.0
//
// See LICENSE.md for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
public enum BitcoinLegacyAddressPrefix: RawRepresentable {
    case main
    case testnet
    
    @usableFromInline
    static let mainPubkey: UInt8 = 0
    @usableFromInline
    static let mainScript: UInt8 = 5

    @usableFromInline
    static let testnetPubkey: UInt8 = 111
    @usableFromInline
    static let testnetScript: UInt8 = 196

    @inlinable
    public init?(rawValue: (pubkey: UInt8, script: UInt8)) {
        switch rawValue {
        case (Self.mainPubkey, Self.mainScript):
            self = .main
        case (Self.testnetPubkey, Self.testnetScript):
            self = .testnet
        default:
            return nil
        }
    }
    
    @inlinable
    public var rawValue: (pubkey: UInt8, script: UInt8) {
        switch self {
        case .main:
            return (Self.mainPubkey, Self.mainScript)
        case .testnet:
            return (Self.testnetPubkey, Self.testnetScript)
        }
    }
}

