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
import fltrECC

public extension X.PublicKey {
    @inlinable
    var scriptPubKey: [UInt8] {
        [ OpCodes.OP_1, 0x20 ] + self.serialize()
    }
    
    @inlinable
    func addressTaproot(_ prefix: Bech32.HumanReadablePart) -> String {
        return try! Bech32.addressEncode(prefix, version: 1, witnessProgram: self.serialize())
    }
}
