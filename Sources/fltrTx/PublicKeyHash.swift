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
import HaByLo

public protocol PublicKeyHashProtocol {
    var bytes: [UInt8] { get }
    
    init(_: DSA.PublicKey)
}

extension PublicKeyHashProtocol {
    @inlinable
    public func addressLegacyPKH(_ prefix: BitcoinLegacyAddressPrefix) -> String {
        return ([prefix.rawValue.pubkey] + self.bytes).base58CheckEncode()
    }
    
    @inlinable
    public var scriptPubKeyLegacyPKH: [UInt8] {
        [ OpCodes.OP_DUP, OpCodes.OP_HASH160, ]
            + self.bytes.count.variableLengthCode
            + self.bytes
            + [ OpCodes.OP_EQUALVERIFY, OpCodes.OP_CHECKSIG ]
    }
}

public struct PublicKeyHash: PublicKeyHashProtocol, Hashable {
    public let bytes: [UInt8]
    
    @inlinable
    public init(_ publicKey: DSA.PublicKey) {
        self.bytes = publicKey.serialize().hash160
    }
    
    @inlinable
    public init(_ bytes: [UInt8]) {
        assert(bytes.count == 20)
        self.bytes = bytes
    }

    @inlinable
    public func addressLegacyWPKH(_ prefix: BitcoinLegacyAddressPrefix) -> String {
        let network = prefix.rawValue.script
        let scriptHash = self.scriptPubKeyWPKH.hash160
        let address = [ network ] + scriptHash
        return address.base58CheckEncode()
    }

    @inlinable
    public func addressSegwit(_ prefix: Bech32.HumanReadablePart) -> String {
        return try! Bech32.addressEncode(prefix, version: 0, witnessProgram: self.bytes)
    }
    
    @inlinable
    public var scriptPubKeyWPKH: [UInt8] {
        [ 0x00, 0x14, ] + self.bytes
    }
    
    @inlinable
    public var scriptPubKeyLegacyWPKH: [UInt8] {
        [ OpCodes.OP_HASH160, 0x14 ]
            + self.scriptPubKeyWPKH.hash160
            + [ OpCodes.OP_EQUAL ]
    }
    
    @inlinable
    public func equals<Bytes: Sequence>(_ bytes: Bytes) -> Bool where Bytes.Element == UInt8 {
        var lhsIterator = self.bytes.makeIterator()
        var rhsIterator = bytes.makeIterator()
        
        while let lhs = lhsIterator.next() {
            guard let rhs = rhsIterator.next(),
                  lhs == rhs else {
                return false
            }
        }
        
        guard rhsIterator.next() == nil else {
            return false
        }
        
        return true
    }
}

public struct UncompressedPublicKeyHash: PublicKeyHashProtocol, Hashable {
    public let bytes: [UInt8]
    
    @inlinable
    public init(_ publicKey: DSA.PublicKey) {
        self.bytes = publicKey.serialize(format: .uncompressed).hash160
    }
}
