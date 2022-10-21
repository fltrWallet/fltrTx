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
import struct NIOCore.ByteBufferAllocator

public extension Tx {
    struct LegacyTransaction: TransactionSerializationProtocol {
        public let version: Int32
        public let vin: [Tx.In]
        public let vout: [Tx.Out]
        public let locktime: Tx.Locktime
        @inlinable
        public var hasWitnesses: Bool { false }
        
        @inlinable
        public init(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            self.version = version
            self.vin = vin
            self.vout = vout
            self.locktime = locktime
        }
        
        @inlinable
        public init<T: TransactionProtocol>(_ tx: T) {
            self.init(version: tx.version,
                      vin: tx.vin,
                      vout: tx.vout,
                      locktime: tx.locktime)
        }

        @inlinable
        public init(_ tx: LegacyIdentifiableTransaction) {
            self = tx._backing
        }
        
        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let tx = Self.readLegacyTransaction(buffer: &buffer) {
                self = tx
            } else {
                buffer = save
                return nil
            }
        }
        
        @inlinable
        public func write(to buffer: inout ByteBuffer) {
            self.writeLegacyTransaction(to: &buffer)
        }
    }
    
    struct LegacyIdentifiableTransaction: IdentifiableTransactionProtocol, IdentifiableSerializationProtocol {
        public let _backing: Tx.LegacyTransaction
        @usableFromInline
        var bufferCache = Optional<ByteBuffer>.none
        public let txId: Tx.TxId
        public let wtxId: Tx.WtxId

        @inlinable
        public init(version: Int32, vin: [Tx.In],
                    vout: [Tx.Out], locktime: Tx.Locktime,
                    txId: Tx.TxId, wtxId: Tx.WtxId) {
            self._backing = Tx.LegacyTransaction(version: version, vin: vin, vout: vout, locktime: locktime)
            self.txId = txId; self.wtxId = wtxId
        }

        @inlinable
        public init(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            let backing = Tx.LegacyTransaction(version: version, vin: vin, vout: vout, locktime: locktime)
            self._backing = backing
            
            if let cache = self.bufferCache {
                let txId: Tx.TxId = .makeHash(from: cache.readableBytesView)
                self.txId = txId
                self.wtxId = txId.asWtxId
            } else {
                var buffer = ByteBufferAllocator().buffer(capacity: 2048)
                let txId = backing.txId(scratch: &buffer)
                self.txId = txId
                self.wtxId = txId.asWtxId
            }
            self.bufferCache = nil
        }
        
        @inlinable
        public init<T: TransactionProtocol>(_ tx: T) {
            self.init(LegacyTransaction(tx))
        }

        @inlinable
        public init(_ tx: LegacyTransaction) {
            var buffer = ByteBufferAllocator().buffer(capacity: 2048)
            let txId = tx.txId(scratch: &buffer)
            self.txId = txId
            self.wtxId = txId.asWtxId
            self._backing = tx
            self.bufferCache = nil
        }
        
        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let tx = Self.readLegacyTransaction(buffer: &buffer) {
                let diff = save.readerIndex.distance(to: buffer.readerIndex)
                self.bufferCache = save.getSlice(at: save.readerIndex, length: diff)!
                self = tx
            } else {
                buffer = save
                return nil
            }
        }
    }
}

extension Tx.LegacyTransaction: Hashable {}
extension Tx.LegacyIdentifiableTransaction: Hashable {}
