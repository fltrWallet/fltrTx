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

public protocol TransactionSerializationProtocol where Self: TransactionProtocol {
    @inlinable
    func write(to: inout ByteBuffer)
    @inlinable
    init?(fromBuffer: inout ByteBuffer)
    @inlinable
    init?(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime)
    @inlinable
    init?<T: TransactionProtocol>(_ tx: T)
}

internal protocol IdentifiableSerializationProtocol: TransactionSerializationProtocol where Self: IdentifiableTransactionProtocol {
    associatedtype Backing: TransactionSerializationProtocol
    var _backing: Backing { get }
}

extension IdentifiableSerializationProtocol {
    @inlinable
    public var version: Int32 { self._backing.version }
    @inlinable
    public var vin: [Tx.In] { self._backing.vin }
    @inlinable
    public var vout: [Tx.Out] { self._backing.vout }
    @inlinable
    public var locktime: Tx.Locktime { self._backing.locktime }
    @inlinable
    public var hasWitnesses: Bool { self._backing.hasWitnesses }
    
    @inlinable
    public func write(to buffer: inout ByteBuffer) {
        self._backing.write(to: &buffer)
    }
}

public extension TransactionProtocol {
    @inlinable
    func writeSegwitTransaction(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self.version, endianness: .little)
        buffer.writeBytes([0, 1])
        self.writeVinVout(&buffer)
        self.vin.forEach {
            if let witness = $0.witness {
                let witnessField = witness.witnessField
                assert(witnessField.count > 0)
                buffer.writeBytes(witnessField.count.variableLengthCode)
                witnessField.forEach { bytes in
                    buffer.writeBytes(bytes.count.variableLengthCode)
                    buffer.writeBytes(bytes)
                }
            } else {
                buffer.writeInteger(0, as: UInt8.self)
            }
        }
        buffer.writeBytes(self.locktime.intValue.littleEndianBytes)
    }
    
    @inlinable
    func writeLegacyTransaction(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self.version, endianness: .little)
        self.writeVinVout(&buffer)
        buffer.writeBytes(self.locktime.intValue.littleEndianBytes)
    }
    
    @usableFromInline
    internal func writeVinVout(_ buffer: inout ByteBuffer) {
        buffer.writeBytes(self.vin.count.variableLengthCode)
        self.vin.forEach {
            $0.write(to: &buffer)
        }
        buffer.writeBytes(self.vout.count.variableLengthCode)
        self.vout.forEach {
            $0.write(to: &buffer)
        }
    }
}

public extension TransactionSerializationProtocol {
    @inlinable
    init?<T: TransactionProtocol>(_ tx: T) {
        guard let selfTx = Self.init(version: tx.version,
                                     vin: tx.vin,
                                     vout: tx.vout,
                                     locktime: tx.locktime),
              tx.hasWitnesses == selfTx.hasWitnesses
        else { return nil }

        self = selfTx
    }

    @inlinable
    static func readLegacyTransaction(buffer: inout ByteBuffer) -> Self? {
        let save = buffer
        guard let version: Int32 = buffer.readInteger(endianness: .little),
              let vinCount = buffer.readVarInt(),
              vinCount > 0
        else {
            buffer = save
            return nil
        }
        
        var enableLocktime: Bool = false
        let vin: [Tx.In] = (0..<Int(vinCount)).compactMap { i in
            Tx.In(fromBuffer: &buffer, enableLocktime: &enableLocktime, getWitness: nil)
        }
        
        guard vin.count == vinCount,
              let voutCount = buffer.readVarInt() else {
            buffer = save
            return nil
        }

        var vouts: [Tx.Out] = []
        for _ in 0..<voutCount {
            guard let txOut = Tx.Out(fromBuffer: &buffer) else {
                buffer = save
                return nil
            }
            vouts.append(txOut)
        }

        guard let locktime: UInt32 = buffer.readInteger(endianness: .little) else {
            return nil
        }

        return Self.init(version: version,
                         vin: vin,
                         vout: vouts,
                         locktime: enableLocktime
                            ? .enable(locktime)
                            : .disable(locktime))
    }
    
    @inlinable
    static func readWitnessTransaction(buffer: inout ByteBuffer) -> Self? {
        let save = buffer
        guard let version: Int32 = buffer.readInteger(endianness: .little),
            let marker = buffer.readVarInt(),
            let flag: UInt8 = buffer.readInteger(),
            marker == 0,
            flag == 1,
            let vinCount = buffer.readVarInt()
        else {
            buffer = save
            return nil
        }

        var enableLocktime: Bool = false
        var witnesses: [Tx.Witness?] = []
        let vin: [Tx.In] = (0..<Int(vinCount)).compactMap { i in
            Tx.In(fromBuffer: &buffer, enableLocktime: &enableLocktime, getWitness: witnesses[i])
        }
        guard vin.count == vinCount,
              let voutCount = buffer.readVarInt() else {
            buffer = save
            return nil
        }

        var voutWitness: [Tx.Out] = []
        for _ in 0..<voutCount {
            guard let txOut = Tx.Out(fromBuffer: &buffer) else {
                buffer = save
                return nil
            }
            voutWitness.append(txOut)
        }
        assert(Int(voutCount) == voutWitness.count)
        
        var encounteredWitness = false
        for _ in (0..<vinCount) {
            guard let witnessFieldCount = buffer.readVarInt() else {
                buffer = save
                return nil
            }
            guard witnessFieldCount > 0 else {
                witnesses.append(nil)
                continue
            }
            var witnessField = [[UInt8]]()
            for _ in (0..<witnessFieldCount) {
                guard let fieldLength = buffer.readVarInt(),
                      let field = buffer.readBytes(length: Int(fieldLength)) else {
                    buffer = save
                    return nil
                }
                witnessField.append(field)
            }
            encounteredWitness = true
            witnesses.append(Tx.Witness(witnessField: witnessField))
        }
        guard encounteredWitness else {
            return nil
        }
        
        guard let locktime: UInt32 = buffer.readInteger(endianness: .little) else {
            return nil
        }
        
        return Self.init(version: version,
                         vin: vin,
                         vout: voutWitness,
                         locktime: enableLocktime
                            ? .enable(locktime)
                            : .disable(locktime))
    }
    
    @inlinable
    func wtxId(scratch buffer: inout ByteBuffer) -> Tx.WtxId {
        assert(buffer.writerIndex == 0)
        assert(buffer.readerIndex == buffer.writerIndex)
        self.writeSegwitTransaction(to: &buffer)
        return Tx.WtxId.makeHash(from: buffer.readableBytesView)
    }
    
    @inlinable
    func txId(scratch buffer: inout ByteBuffer) -> Tx.TxId {
        assert(buffer.writerIndex == 0)
        assert(buffer.readerIndex == buffer.writerIndex)
        self.writeLegacyTransaction(to: &buffer)
        return Tx.TxId.makeHash(from: buffer.readableBytesView)
    }
}

public extension Tx.Outpoint {
    @inlinable
    func write(to buffer: inout ByteBuffer) {
        buffer.writeBytes(self.transactionId.littleEndian)
        buffer.writeInteger(self.index, endianness: .little)
    }

    @inlinable
    init?(fromBuffer: inout ByteBuffer) {
        let save = fromBuffer
        guard let transactionId = fromBuffer.readBytes(length: 32),
            let index: UInt32 = fromBuffer.readInteger(endianness: .little) else {
                fromBuffer = save
                return nil
        }
        
        self.init(transactionId: .little(transactionId),
                  index: index)
    }
}

public extension Tx.In {
    @inlinable
    func write(to buffer: inout ByteBuffer) {
        self.outpoint.write(to: &buffer)
        buffer.writeBytes(self.scriptSig.count.variableLengthCode)
        buffer.writeBytes(self.scriptSig)
        buffer.writeInteger(self.sequence.rawValue, endianness: .little)
    }

    @inlinable
    init?(fromBuffer: inout ByteBuffer) {
        var unused = false
        self.init(fromBuffer: &fromBuffer, enableLocktime: &unused, getWitness: nil)
    }
        
    @inlinable
    init?(fromBuffer: inout ByteBuffer,
          enableLocktime: inout Bool,
          getWitness: @escaping @autoclosure () -> Tx.Witness?) {
        let save = fromBuffer
        guard let outpoint = Tx.Outpoint(fromBuffer: &fromBuffer),
            let scriptCount = fromBuffer.readVarInt(),
            let script = fromBuffer.readBytes(length: Int(scriptCount)),
            let sequence: UInt32 = fromBuffer.readInteger(endianness: .little) else {
                fromBuffer = save
                return nil
        }
        
        enableLocktime = enableLocktime
            || sequence != Tx.Sequence.disable.rawValue
        
        self.init(outpoint: outpoint,
                  scriptSig: script,
                  sequence: Tx.Sequence(rawValue: sequence),
                  witness: getWitness)
    }
}

public extension Tx.Out {
    @inlinable
    func write(to buffer: inout ByteBuffer) {
        buffer.writeBytes(self.cTxOut())
    }
    
    @inlinable
    init?(fromBuffer: inout ByteBuffer) {
        let save = fromBuffer
        guard let value: UInt64 = fromBuffer.readInteger(endianness: .little),
            let scriptCount = fromBuffer.readVarInt(),
            let script = fromBuffer.readBytes(length: Int(scriptCount)) else {
                fromBuffer = save
                return nil
        }

        self.init(value: value, scriptPubKey: script)
    }
    
    // corresponding to Bitcoin Core CTxOut format
    @inlinable
    func cTxOut() -> [UInt8] {
        self.value.littleEndianBytes
            + self.scriptPubKey.count.variableLengthCode
            + self.scriptPubKey
    }
}
