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
import Foundation
import HaByLo
//import NIO

public protocol TransactionProtocol: CustomDebugStringConvertible {
    @inlinable
    var version: Int32 { get }
    @inlinable
    var vin: [Tx.In] { get }
    @inlinable
    var vout: [Tx.Out] { get }
    @inlinable
    var isCoinbase: Bool { get }
    @inlinable
    var locktime: Tx.Locktime { get }
    @inlinable
    var hasWitnesses: Bool { get }
}

public extension TransactionProtocol {
    var isCoinbase: Bool {
        self.vin.count == 1
            && self.vin[0].outpoint.index == 0xff_ff_ff_ff
            && self.vin[0].outpoint.transactionId == .zero
    }
}

public enum Tx {}

public extension Tx {
    typealias WtxId = BlockChain.Hash<TransactionWitnessHash>
    typealias TxId = BlockChain.Hash<TransactionLegacyHash>
    
    struct In {
        public let outpoint: Outpoint
        public let scriptSig: [UInt8]
        public let sequence: Tx.Sequence
        @usableFromInline
        let _witness: () -> Tx.Witness?
        
        @inlinable
        public var witness: Tx.Witness? {
            self._witness()
        }
        
        @inlinable
        public var hasWitness: Bool {
            self.witness != nil
        }
        
        @inlinable
        public init(outpoint: Tx.Outpoint, scriptSig: [UInt8], sequence: Tx.Sequence, witness: @escaping () -> Tx.Witness?) {
            self.outpoint = outpoint
            self.scriptSig = scriptSig
            self.sequence = sequence
            self._witness = witness
        }

        @inlinable
        public func add(witness: Tx.Witness) -> Tx.In {
            .init(outpoint: self.outpoint,
                  scriptSig: self.scriptSig,
                  sequence: self.sequence,
                  witness: { witness })
        }
    }
    
    struct Out {
        public let value: UInt64
        public let scriptPubKey: [UInt8]

        @inlinable
        public init(value: UInt64, scriptPubKey: [UInt8]) {
            self.value = value
            self.scriptPubKey = scriptPubKey
        }

    }

    struct Outpoint {
        public let transactionId: Tx.TxId
        public let index: UInt32
        
        @inlinable
        public init(transactionId: Tx.TxId, index: UInt32) {
            self.transactionId = transactionId
            self.index = index
        }
        
        public var isNull: Bool {
            self.transactionId == .zero
//                && index == 0
        }
    }
    
    enum LocktimeValue: Hashable {
        case enabled(UInt32)
        case disabled(UInt32)
        
        @inlinable
        public var enabled: Bool {
            switch self {
            case .enabled:
                return true
            case .disabled:
                return false
            }
        }
        
        @inlinable
        public var intValue: UInt32 {
            switch self {
            case .enabled(let value), .disabled(let value):
                return value
            }
        }
        
        @inlinable
        public var bytes: [UInt8] {
            self.intValue.littleEndianBytes
        }
    }
    
    struct Locktime: Hashable {
        @usableFromInline
        enum InternalState: Hashable {
            case block(UInt32)
            case timestamp(Date)
            case disabled(UInt32)

            @usableFromInline
            static func from(value: UInt32) -> Self {
                switch value {
                case let i where i < 500_000_000:
                    return .block(value)
                default:
                    return .timestamp(Date(timeIntervalSince1970: .init(value)))
                }
            }

            @usableFromInline
            var date: Date? {
                switch self {
                case .timestamp(let date):
                    return date
                case .block, .disabled:
                    return nil
                }
            }
            
            @usableFromInline
            var enabled: Bool {
                switch self {
                case .block, .timestamp:
                    return true
                case .disabled:
                    return false
                }
            }
            
            @usableFromInline
            var height: Int? {
                switch self {
                case .block(let height):
                    return Int(height)
                case .timestamp, .disabled:
                    return nil
                }
            }
            
            @usableFromInline
            var intValue: UInt32 {
                switch self {
                case .block(let value):
                    return value
                case .timestamp(let date):
                    return UInt32(date.timeIntervalSince1970)
                case .disabled(let value):
                    return value
                }
            }
        }

        @usableFromInline
        let value: InternalState
        
        @usableFromInline
        init(_ state: InternalState) {
            self.value = state
        }
        
        @inlinable
        static public func disable(_ value: UInt32) -> Self {
            .init(.disabled(value))
        }
        
        @inlinable
        static public func enable(_ value: UInt32) -> Self {
            .init(.from(value: value))
        }
        
        @inlinable
        public var date: Date? {
            self.value.date
        }
        
        @inlinable
        public var enabled: Bool {
            self.value.enabled
        }
        
        @inlinable
        public var height: Int? {
            self.value.height
        }
        
        @inlinable
        public var intValue: UInt32 {
            self.value.intValue
        }
    }

    struct Sequence: OptionSet {
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        // Disable locktime field in transaction (as well as relative height/time)
        public static let disable: Sequence = Sequence(rawValue: .max)
        public static let locktimeOnly: Sequence = Sequence(rawValue: .max - 1)
        // (BIP68) Relative height / time disable
        public static let bip68Disable = Sequence(rawValue: 1 << 31)
        // Relative locktime = value << 9 (i.e. multiplied by 512)
        public static let chooseTime = Sequence(rawValue: 1 << 22)
        public static let mask: UInt32 = 0xffff
        
        @inlinable
        public var isDisabled: Bool {
            self.contains(.bip68Disable)
        }
        
        @inlinable
        public var isBip68: Bool {
            guard (self.rawValue ^ Self.bip68Disable.rawValue) & ~Self.chooseTime.rawValue <= 0xffff else {
                    return false
            }
            return true
        }
        
        @inlinable
        public var bip68Time: UInt32? {
            guard self.isBip68, self.contains(.chooseTime) else {
                return nil
            }
            
            return (self.rawValue & Self.mask) << 9
        }
        
        @inlinable
        public var bip68RelativeBlock: UInt32? {
            guard self.isBip68, !self.contains(.chooseTime) else {
                return nil
            }
            
            return self.rawValue
        }
    }
    
    struct Witness {
        public let witnessField: [[UInt8]]

        public init(witnessField: [[UInt8]]) {
            self.witnessField = witnessField
        }
    }
}

extension Tx.In: Equatable & Hashable {
    public static func == (lhs: Tx.In, rhs: Tx.In) -> Bool {
        lhs.outpoint == rhs.outpoint
            && lhs.scriptSig == rhs.scriptSig
            && lhs.sequence == rhs.sequence
            && lhs.witness == rhs.witness
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.outpoint)
        hasher.combine(self.scriptSig)
        hasher.combine(self.sequence)
        guard let witness = self.witness else {
            return
        }
        hasher.combine(witness)
    }
}

extension Tx.Out: Equatable & Hashable, Codable {}

extension Tx.Outpoint: Equatable & Hashable, Codable {}

extension Tx.Locktime: Codable {
    enum CodingKeys: String, CodingKey {
        case block
        case timestamp
        case disabled
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self.value {
        case .block(let number):
            try container.encode(number, forKey: .block)
        case .disabled(let number):
            try container.encode(number, forKey: .disabled)
        case .timestamp(let date):
            try container.encode(UInt32(date.timeIntervalSince1970), forKey: .timestamp)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let key = container.allKeys.first
        else {
            struct DecodingKeyNotFound: Swift.Error {}
            throw DecodingKeyNotFound()
        }
        
        let associatedValue = try container.decode(UInt32.self, forKey: key)
        
        switch key {
        case .block:
            self.value = .block(associatedValue)
        case .disabled:
            self.value = .disabled(associatedValue)
        case .timestamp:
            self.value = .timestamp(Date(timeIntervalSince1970: TimeInterval(associatedValue)))
        }
    }
}

extension Tx.Witness: Equatable & Hashable, Codable {}
extension Tx.Sequence: Equatable & Hashable, Codable {}

