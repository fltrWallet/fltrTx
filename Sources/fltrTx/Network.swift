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
import bech32

public enum Network {
    case main
    case testnet
    
    @inlinable
    public var legacyAddressPrefix: BitcoinLegacyAddressPrefix {
        switch self {
        case .main:
            return .main
        case .testnet:
            return .testnet
        }
    }
    
    @inlinable
    public var bech32HumanReadablePart: Bech32.HumanReadablePart {
        switch self {
        case .main:
            return .main
        case .testnet:
            return .testnet
        }
    }
}
