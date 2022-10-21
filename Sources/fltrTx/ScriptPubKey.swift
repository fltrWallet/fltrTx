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
public struct ScriptPubKey: Hashable, Codable {
    public let tag: UInt8
    public let index: UInt32
    public let opcodes: [UInt8]
    
    @inlinable
    public init(tag: UInt8, index: UInt32, opcodes: [UInt8]) {
        self.tag = tag
        self.index = index
        self.opcodes = opcodes
    }
    
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.opcodes)
    }
    
    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.opcodes.elementsEqual(rhs.opcodes)
    }
}

extension ScriptPubKey: CustomStringConvertible {
    public var description: String {
        var string = [String]()
        string.append("ScriptPubKey(")
        string.append("tag🏷: \(self.tag), ")
        string.append("index#️⃣: \(self.index), ")
        string.append("opcodes💾: \(self.opcodes.hexEncodedString))")
        return string.joined()
    }
}
