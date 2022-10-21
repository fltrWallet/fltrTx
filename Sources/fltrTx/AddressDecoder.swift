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
import Foundation

public struct AddressDecoder: Hashable {
    public enum AddressType: Hashable {
        case pkh(PublicKeyHash)
        case sh([UInt8])
        case segwit0(PublicKeyHash)
        case segwit0SigHash([UInt8])
        case segwit1(X.PublicKey)
    }
    
    public enum Standard: CustomStringConvertible, Hashable {
        case legacy
        case segwitVersion0
        case segwitVersion1
        
        @inlinable
        public var description: String {
            switch self {
            case .legacy:
                return "Legacy"
            case .segwitVersion0:
                return "Segwit"
            case .segwitVersion1:
                return "Taproot"
            }
        }
    }
    
    @usableFromInline
    internal let _string: String
    @usableFromInline
    internal let value: AddressType
    
    @usableFromInline
    internal init(pkh value: [UInt8], string: String) {
        precondition(value.count == 20)
        self.value = .pkh(PublicKeyHash(value))
        self._string = string
    }
    
    @usableFromInline
    internal init(sh value: [UInt8], string: String) {
        precondition(value.count == 20)
        self.value = .sh(value)
        self._string = string
    }
    
    @usableFromInline
    internal init(segwit value: [UInt8], string: String) {
        precondition(value.count == 20)
        self.value = .segwit0(PublicKeyHash(value))
        self._string = string
    }
    
    @usableFromInline
    internal init(segwitSigHash value: [UInt8], string: String) {
        precondition(value.count == 32)
        self.value = .segwit0SigHash(value)
        self._string = string
    }
    
    @usableFromInline
    internal init(taproot value: X.PublicKey, string: String) {
        self.value = .segwit1(value)
        self._string = string
    }
    
    @inlinable
    public init?(decoding: String,
                 network: Network) {
        let maybeUrl: String = {
            guard let url = URLComponents(string: decoding),
                  let scheme = url.scheme?.lowercased(),
                  scheme.elementsEqual("bitcoin")
            else { return decoding }
            
            return url.path
        }()
        
        if let decodeBech32 = try? Bech32.addressDecode(network.bech32HumanReadablePart,
                                                        address: maybeUrl) {
            if decodeBech32.version == 0 {
                if decodeBech32.program.count > 20 {
                    self.init(segwitSigHash: decodeBech32.program, string: maybeUrl)
                } else {
                    self.init(segwit: decodeBech32.program, string: maybeUrl)
                }
            } else if decodeBech32.version == 1,
                      decodeBech32.program.count == 32,
                      let xPublicKey = X.PublicKey(from: decodeBech32.program) {
                self.init(taproot: xPublicKey, string: maybeUrl)
            } else {
                return nil
            }
        } else if var decodeBase58 = try? maybeUrl.base58CheckDecode(),
           let prefix = decodeBase58.popFirst() {
            guard decodeBase58.count == 20
            else {
                return nil
            }
            
            if network.legacyAddressPrefix.rawValue.pubkey == prefix {
                self.init(pkh: Array(decodeBase58), string: maybeUrl)
            } else if network.legacyAddressPrefix.rawValue.script == prefix {
                self.init(sh: Array(decodeBase58), string: maybeUrl)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    @inlinable
    public var standard: Standard {
        switch self.value {
        case .pkh, .sh:
            return .legacy
        case .segwit0, .segwit0SigHash:
            return .segwitVersion0
        case .segwit1:
            return .segwitVersion1
        }
    }
    
    @inlinable
    public var scriptPubKey: [UInt8] {
        switch self.value {
        case .pkh(let publicKeyHash):
            return publicKeyHash.scriptPubKeyLegacyPKH
        case .sh(let scriptHash):
            return [ OpCodes.OP_HASH160, 0x14 ] + scriptHash + [ OpCodes.OP_EQUAL ]
        case .segwit0(let publicKeyHash):
            return publicKeyHash.scriptPubKeyWPKH
        case .segwit0SigHash(let script):
            return [ 0x00, 0x20 ] + script
        case .segwit1(let xPoint):
            return xPoint.scriptPubKey
        }
    }
    
    @inlinable
    public var string: String {
        switch self.standard {
        case .legacy:
            return self._string
        case .segwitVersion0, .segwitVersion1:
            return self._string.lowercased()
        }
    }
}
