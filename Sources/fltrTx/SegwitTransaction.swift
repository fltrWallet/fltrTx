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
import struct NIOCore.ByteBufferAllocator
import struct NIOCore.ByteBuffer

public extension Tx {
    struct SegwitTransaction: TransactionSerializationProtocol {
        public var version: Int32
        public var vin: [Tx.In]
        public var vout: [Tx.Out]
        public var locktime: Tx.Locktime
        @inlinable
        public var hasWitnesses: Bool { true }

        @inlinable
        public init?(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            guard let _ = vin.first(where: { $0.hasWitness })
            else { return nil }
            
            self.version = version
            self.vin = vin
            self.vout = vout
            self.locktime = locktime
        }
        
        @inlinable
        public init(_ tx: SegwitIdentifiableTransaction) {
            self = tx._backing
        }

        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let tx = Self.readWitnessTransaction(buffer: &buffer) {
                self = tx
            } else {
                buffer = save
                return nil
            }
        }

        @inlinable
        public func write(to buffer: inout ByteBuffer) {
            self.writeSegwitTransaction(to: &buffer)
        }
    }
    
    struct SegwitIdentifiableTransaction: IdentifiableTransactionProtocol, IdentifiableSerializationProtocol {
        public let _backing: Tx.SegwitTransaction
        @usableFromInline
        var bufferCache = Optional<ByteBuffer>.none
        public let txId: Tx.TxId
        public let wtxId: Tx.WtxId
        
        @inlinable
        public init?(version: Int32, vin: [Tx.In],
                     vout: [Tx.Out], locktime: Tx.Locktime,
                     txId: Tx.TxId, wtxId: Tx.WtxId) {
            guard let backing = Tx.SegwitTransaction(version: version, vin: vin, vout: vout, locktime: locktime)
            else { return nil }
            
            self._backing = backing
            self.txId = txId; self.wtxId = wtxId
        }
        
        @inlinable
        public init?(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
            guard let backing = Tx.SegwitTransaction(version: version, vin: vin, vout: vout, locktime: locktime)
            else { return nil }
            self._backing = backing

            var bufferTxId = ByteBufferAllocator().buffer(capacity: 2048)
            let txId = backing.txId(scratch: &bufferTxId)
            self.txId = txId
            if let cache = self.bufferCache {
                self.wtxId = .makeHash(from: cache.readableBytesView)
            } else {
                bufferTxId.moveReaderIndex(to: 0); bufferTxId.moveWriterIndex(to: 0)
                let wtxId = backing.wtxId(scratch: &bufferTxId)
                self.wtxId = wtxId
            }
            self.bufferCache = nil
        }

        @inlinable
        public init(_ tx: SegwitTransaction) {
            var bufferTxId = ByteBufferAllocator().buffer(capacity: 2048)
            let txId = tx.txId(scratch: &bufferTxId)
            bufferTxId.moveReaderIndex(to: 0); bufferTxId.moveWriterIndex(to: 0)
            let wtxId = tx.wtxId(scratch: &bufferTxId)
            self._backing = tx
            self.txId = txId
            self.wtxId = wtxId
            self.bufferCache = nil
        }

        @inlinable
        public init?(fromBuffer buffer: inout ByteBuffer) {
            let save = buffer
            if let tx = Self.readWitnessTransaction(buffer: &buffer) {
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

extension Tx.SegwitTransaction: Hashable {}
extension Tx.SegwitIdentifiableTransaction: Hashable {}
extension Tx.SegwitTransaction: CustomDebugStringConvertible {}
extension Tx.SegwitIdentifiableTransaction: CustomDebugStringConvertible {}
