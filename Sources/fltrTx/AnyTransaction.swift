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
import struct NIOCore.ByteBuffer

public extension Tx {
    enum AnyTransaction: TransactionSerializationProtocol {
        case legacy(LegacyTransaction)
        case segwit(SegwitTransaction)
        
        @usableFromInline
        var backing: TransactionSerializationProtocol {
            switch self {
            case .legacy(let tx as TransactionSerializationProtocol),
                    .segwit(let tx as TransactionSerializationProtocol):
                return tx
            }
        }
        
        @inlinable
        public var hasWitnesses: Bool { self.backing.hasWitnesses }
        @inlinable
        public var version: Int32 { self.backing.version }
        @inlinable
        public var vin: [Tx.In] { self.backing.vin }
        @inlinable
        public var vout: [Tx.Out] { self.backing.vout }
        @inlinable
        public var locktime: Tx.Locktime { self.backing.locktime }

        @inlinable
        public init(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            if let _ = vin.first(where: { $0.hasWitness }) {
                self = .segwit(.init(version: version,
                                     vin: vin,
                                     vout: vout,
                                     locktime: locktime)!)
            } else {
                self = .legacy(.init(version: version,
                                     vin: vin,
                                     vout: vout,
                                     locktime: locktime))
            }
        }

        @inlinable
        public func write(to buffer: inout ByteBuffer) {
            self.backing.write(to: &buffer)
        }
        
        @inlinable
        public init(_ tx: AnyIdentifiableTransaction) {
            switch tx {
            case .legacy(let tx):
                self = .legacy(LegacyTransaction(tx))
            case .segwit(let tx):
                self = .segwit(SegwitTransaction(tx))
            }
        }

        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let segwit = SegwitTransaction(fromBuffer: &buffer) {
                self = .segwit(segwit)
            } else {
                buffer = save
                if let legacy = LegacyTransaction(fromBuffer: &buffer) {
                    self = .legacy(legacy)
                } else {
                    buffer = save
                    return nil
                }
            }
        }
    }
    
    enum AnyIdentifiableTransaction: IdentifiableTransactionProtocol, TransactionSerializationProtocol {
        case legacy(LegacyIdentifiableTransaction)
        case segwit(SegwitIdentifiableTransaction)
        
        @usableFromInline
        var backing: TransactionProtocol {
            switch self {
            case .legacy(let tx as TransactionProtocol),
                    .segwit(let tx as TransactionProtocol):
                return tx
            }
        }
        
        @inlinable
        public var version: Int32 { self.backing.version }
        @inlinable
        public var vin: [Tx.In] { self.backing.vin }
        @inlinable
        public var vout: [Tx.Out] { self.backing.vout }
        @inlinable
        public var locktime: Tx.Locktime { self.backing.locktime }
        @inlinable
        public var hasWitnesses: Bool { self.backing.hasWitnesses }
        @inlinable
        public var txId: Tx.TxId {
            switch self {
            case .legacy(let tx): return tx.txId
            case .segwit(let tx): return tx.txId
            }
        }
        @inlinable
        public var wtxId: Tx.WtxId {
            switch self {
            case .legacy(let tx): return tx.wtxId
            case .segwit(let tx): return tx.wtxId
            }
        }

        @inlinable
        public init(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            self.init(AnyTransaction(version: version,
                                     vin: vin,
                                     vout: vout,
                                     locktime: locktime))
        }
        
        @inlinable
        public init(_ tx: AnyTransaction) {
            switch tx {
            case .legacy(let tx):
                self = .legacy(Tx.LegacyIdentifiableTransaction(tx))
            case .segwit(let tx):
                self = .segwit(Tx.SegwitIdentifiableTransaction(tx))
            }
        }

        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let segwit = SegwitIdentifiableTransaction(fromBuffer: &buffer) {
                self = .segwit(segwit)
            } else {
                buffer = save
                if let legacy = LegacyIdentifiableTransaction(fromBuffer: &buffer) {
                    self = .legacy(legacy)
                } else {
                    buffer = save
                    return nil
                }
            }
        }

        public func write(to buffer: inout ByteBuffer) {
            switch self {
            case .legacy(let tx):
                tx.write(to: &buffer)
            case .segwit(let tx):
                tx.write(to: &buffer)
            }
        }
    }
}

extension Tx.AnyTransaction: Hashable {}
extension Tx.AnyIdentifiableTransaction: Hashable {}

