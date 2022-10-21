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
import fltrECC
import HaByLo
import struct NIOCore.ByteBufferAllocator

public extension Tx {
    enum Signature {
        fileprivate static var allocator: ByteBufferAllocator = .init()

        public enum SigHashType: UInt8 {
            case DEFAULT = 0
            case ALL = 1
            case NONE = 2
            case SINGLE = 3
            case ANYONECANPAY_ALL = 0x81
            case ANYONECANPAY_NONE = 0x82
            case ANYONECANPAY_SINGLE = 0x83

            @usableFromInline
            var bytes: [UInt8] {
                UInt32(self.rawValue).littleEndianBytes
            }
        }
        
        enum Error: Swift.Error {
            case segwitOutputMalformed
        }

        @inlinable
        public static func sigHash<Transaction: TransactionProtocol>(tx: Transaction,
                                                                     signatureType: SigHashType,
                                                                     inputIndex: Int,
                                                                     amount: UInt64,
                                                                     outpointPublicKeyHash: PublicKeyHash)
        -> BlockChain.Hash<SignatureHash> {
            assert(inputIndex < tx.vin.count)

            if tx.vin[inputIndex].hasWitness {
                return Tx.SegwitTransaction.sigHash(tx: tx,
                                                    sigHashType: signatureType,
                                                    inputIndex: inputIndex,
                                                    amount: amount,
                                                    outpointPublicKeyHash: outpointPublicKeyHash)
            } else {
                return Tx.LegacyTransaction.sigHash(tx: tx,
                                                        sigHashType: signatureType,
                                                        inputIndex: inputIndex,
                                                    scriptPubKey: outpointPublicKeyHash.scriptPubKeyLegacyPKH)
            }
        }
    }
}

// MARK: Legacy
public extension Tx.In {
    var legacySignature: (signature: DSA.Signature,
                          sigHashType: Tx.Signature.SigHashType,
                          publicKey: DSA.PublicKey)? {
        var buffer = Tx.Signature.allocator.buffer(bytes: self.scriptSig)
        
        guard let sigSize = buffer.readVarInt().map(Int.init),
              var fullSig = buffer.readBytes(length: sigSize),
              let sigHashType = fullSig.popLast().flatMap({ Tx.Signature.SigHashType(rawValue: $0) }),
              let signature = DSA.Signature(from: fullSig)
        else { return nil }
        
        guard let publicKeySize = buffer.readVarInt().map(Int.init),
              let publicKeyBytes = buffer.readBytes(length: publicKeySize),
              let point = DSA.PublicKey(from: publicKeyBytes)
        else { return nil }
        
        return (signature, sigHashType, point)
    }

    @inlinable
    var hasAnnex: Bool {
        if let witness = self.witness,
           witness.witnessField.count > 1,
           let last = witness.witnessField.last,
           let firstByte = last.first,
           firstByte == 0x50 {
            return true
        } else {
            return false
        }
    }
    
    @inlinable
    var annex: [UInt8] {
        guard let witness = self.witness,
              self.hasAnnex
        else { return [] }
        
        let annex = witness.witnessField.last!
        return annex
    }
    
    @inlinable
    var v0Signature: (signature: DSA.Signature,
                      sigHashType: Tx.Signature.SigHashType,
                      publicKey: DSA.PublicKey)? {
        guard let witness = self.witness,
              let sigHashType = witness.witnessField.first?.last.flatMap({ Tx.Signature.SigHashType(rawValue: $0) }),
            let signatureBytes = witness.witnessField.first?.dropLast(),
              let signature = DSA.Signature(from: signatureBytes) else {
            return nil
        }
        
        guard let publicKeyBytes = witness.witnessField.last,
              let point = DSA.PublicKey(from: publicKeyBytes)
        else { return nil }

        return (signature, sigHashType, point)
    }
    
    @inlinable
    var v1Signature: (signature: X.Signature, sigHashType: Tx.Signature.SigHashType)? {
        guard let witness = self.witness
        else { return nil }
        
        var witnessStack = witness.witnessField
        
        if self.hasAnnex {
            witnessStack.removeLast()
        }
        
        guard witnessStack.count == 1,
              var signatureBytes = witnessStack.first
        else { return nil }
        
        var sigHash = Tx.Signature.SigHashType.DEFAULT
        if signatureBytes.count == 65,
           let last = signatureBytes.popLast() {
            guard let readSigHash = Tx.Signature.SigHashType(rawValue: last)
            else { return nil }
            
            sigHash = readSigHash
        }
        
        guard let signature = X.Signature(from: signatureBytes)
        else { return nil }
        
        return (signature: signature,
                sigHashType: sigHash)
    }
}

public extension TransactionProtocol {
    func verifySignature(index: Int, prevouts: [Tx.Out]) -> Bool {
        precondition(self.vin.count == prevouts.count)
        
        guard index < self.vin.count,
              index >= 0
        else { return false }
        
        if let _ = self.vin[index].witness {
            if let v0Signature = self.vin[index].v0Signature {
                let sigHash = Tx.Signature.sigHash(tx: self,
                                                   signatureType: v0Signature.sigHashType,
                                                   inputIndex: index,
                                                   amount: prevouts[index].value,
                                                   outpointPublicKeyHash: PublicKeyHash(v0Signature.publicKey))
                return v0Signature.publicKey.verify(signature: v0Signature.signature, message: Array(sigHash.littleEndian))
            } else if let (v1Signature, sigHashType) = self.vin[index].v1Signature,
                      prevouts[index].scriptPubKey.count == 34,
                      let v1PublicKey = X.PublicKey(from: prevouts[index].scriptPubKey.dropFirst(2)) {
                let sigHash = Tx.TapRoot.sigHash(tx: self,
                                                 inputIndex: index,
                                                 type: sigHashType,
                                                 prevouts: prevouts,
                                                 annex: self.vin[index].annex)
                return v1PublicKey.verify(signature: v1Signature, message: Array(sigHash.littleEndian))
            } else {
                return false
            }
        } else if let legacySignature = self.vin[index].legacySignature {
            let sigHash = Tx.LegacyTransaction.sigHash(tx: self,
                                                       sigHashType: legacySignature.sigHashType,
                                                       inputIndex: index,
                                                       scriptPubKey: prevouts[index].scriptPubKey)
            return legacySignature.publicKey.verify(signature: legacySignature.signature, message: Array(sigHash.littleEndian))
        } else {
            return false
        }
    }
}

extension Tx.Signature {
    @usableFromInline
    struct LegacySigHashBuilder: TransactionProtocol {
        @usableFromInline
        internal init(vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime, sigHashType: Tx.Signature.SigHashType) {
            self.vin = vin
            self.vout = vout
            self.locktime = locktime
            self.sigHashType = sigHashType
        }
        
        @usableFromInline
        var vin: [Tx.In]
        @usableFromInline
        var vout: [Tx.Out]
        @usableFromInline
        let locktime: Tx.Locktime
        @usableFromInline
        let hasWitnesses: Bool = false
        @usableFromInline
        let version: Int32 = 1
        @usableFromInline
        let sigHashType: SigHashType
        
    }
}

extension Tx.LegacyTransaction {
    @usableFromInline
    static func sigHash<T: TransactionProtocol>(tx: T,
                                                sigHashType: Tx.Signature.SigHashType,
                                                inputIndex: Int,
                                                scriptPubKey: [UInt8])
    -> BlockChain.Hash<SignatureHash> {
        let scriptPubKey = scriptPubKey.filter {
            $0 != OpCodes.OP_CODESEPARATOR
        }
        
        precondition(inputIndex < tx.vin.count)
        
        func defaultVin() -> [Tx.In] {
            tx.vin.enumerated().map { index, txIn in
                Tx.In(outpoint: txIn.outpoint,
                      scriptSig: index == inputIndex ? scriptPubKey : [],
                      sequence: txIn.sequence,
                      witness: { nil })
            }
        }
        
        func resetSequenceVin(except: Int) -> [Tx.In] {
            tx.vin.enumerated().map { index, txIn in
                Tx.In(outpoint: txIn.outpoint,
                      scriptSig: index == inputIndex ? scriptPubKey : [],
                      sequence: inputIndex == except ? txIn.sequence : .init(rawValue: 0),
                      witness: { nil })
            }
        }
        
        let vin: [Tx.In] = {
            switch sigHashType {
            case .ANYONECANPAY_ALL, .ANYONECANPAY_NONE, .ANYONECANPAY_SINGLE:
                return [ tx.vin[inputIndex] ]
            case .ALL, .DEFAULT:
                return defaultVin()
            case .NONE:
                return resetSequenceVin(except: inputIndex)
            case .SINGLE:
                return resetSequenceVin(except: inputIndex)
            }
        }()
        
        guard let vout: [Tx.Out] = {
            switch sigHashType {
            case .ANYONECANPAY_NONE, .NONE:
                return []
            case .ANYONECANPAY_SINGLE, .SINGLE:
                guard inputIndex < tx.vout.count
                else { return nil }
                
                var vout = [Tx.Out](repeating: Tx.Out(value: UInt64.max,
                                                      scriptPubKey: []),
                                    count: inputIndex - 1)
                vout.append(tx.vout[inputIndex])
                return vout
            case .ALL, .ANYONECANPAY_ALL, .DEFAULT:
                return tx.vout
            }
        }()
        else { return .little(
            "0100000000000000000000000000000000000000000000000000000000000000"
                .hex2Bytes) }
        
        let legacyTx = Tx.LegacyTransaction(version: tx.version,
                                            vin: vin, vout: vout,
                                            locktime: tx.locktime)
        var buffer = Tx.Signature.allocator.buffer(capacity: 8 * 1024)
        legacyTx.writeLegacyTransaction(to: &buffer)
        return .makeHash(from: buffer.readableBytesView + sigHashType.bytes)
    }
}

extension Tx.SegwitTransaction {
    @usableFromInline
    static func sigHash<Transaction: TransactionProtocol>(tx: Transaction,
                                                          sigHashType: Tx.Signature.SigHashType,
                                                          inputIndex: Int,
                                                          amount: UInt64,
                                                          outpointPublicKeyHash: PublicKeyHash)
    -> BlockChain.Hash<SignatureHash> {
        let scriptCode: [UInt8] = [
            0x19, // Total program length 25 (0x19)
            0x76, // OP_DUP
            0xa9, // OP_HASH160
            0x14, // Push pubkey of length 20 (0x14)
        ] + outpointPublicKeyHash.bytes + [
            0x88, // OP_CHECKEQUALVERIFY
            0xac, // OP_CHECKSIG
        ]
        

        var serialization: [UInt8] = []
        /* Double SHA256 of the serialization of:
         1. nVersion of the transaction (4-byte little endian)
         2. hashPrevouts (32-byte hash)
         3. hashSequence (32-byte hash)
         4. outpoint (32-byte hash + 4-byte little endian)
         5. scriptCode of the input (serialized as scripts inside CTxOuts)
         6. value of the output spent by this input (8-byte little endian)
         7. nSequence of the input (4-byte little endian)
         8. hashOutputs (32-byte hash)
         9. nLocktime of the transaction (4-byte little endian)
        10. sighash type of the signature (4-byte little endian) */

        /* 01. */ serialization.append(contentsOf: UInt32(bitPattern: tx.version).littleEndianBytes)
        /* 02. */ serialization.append(contentsOf: Self.hashPrevouts(for: sigHashType, tx: tx).littleEndian)
        /* 03. */ serialization.append(contentsOf: Self.hashSequence(for: sigHashType, tx: tx).littleEndian)
        /* 04. */ serialization.append(contentsOf: tx.vin[inputIndex].outpoint.transactionId.littleEndian + tx.vin[inputIndex].outpoint.index.littleEndianBytes)
        /* 05. */ serialization.append(contentsOf: scriptCode)
        /* 06. */ serialization.append(contentsOf: amount.littleEndianBytes)
        /* 07. */ serialization.append(contentsOf: tx.vin[inputIndex].sequence.rawValue.littleEndianBytes)
        /* 08. */ serialization.append(contentsOf: Self.hashOutputs(for: sigHashType, tx: tx, inputIndex: inputIndex).littleEndian)
        /* 09. */ serialization.append(contentsOf: tx.locktime.intValue.littleEndianBytes)
        /* 10. */ serialization.append(contentsOf: sigHashType.bytes)
        
        return .makeHash(from:
            serialization
        )
    }
    
    @usableFromInline
    static func hashPrevouts<Transaction: TransactionProtocol>(for type: Tx.Signature.SigHashType,
                                                               tx: Transaction)
    -> BlockChain.Hash<SignatureHash> {
        switch type {
        case .ALL, .NONE, .SINGLE:
            return .makeHash(from:
                tx.vin.flatMap {
                    $0.outpoint.transactionId.littleEndian + $0.outpoint.index.littleEndianBytes
                }
            )
        case .ANYONECANPAY_ALL, .ANYONECANPAY_NONE, .ANYONECANPAY_SINGLE:
            return .zero
        case .DEFAULT:
            preconditionFailure()
        }
    }
    
    @usableFromInline
    static func hashSequence<Transaction: TransactionProtocol>(for type: Tx.Signature.SigHashType,
                                                               tx: Transaction)
    -> BlockChain.Hash<SignatureHash> {
        switch type {
        case .ALL:
            return .makeHash(from:
                tx.vin.flatMap {
                    $0.sequence.rawValue.littleEndianBytes
                }
            )
        case .NONE, .SINGLE, .ANYONECANPAY_ALL, .ANYONECANPAY_NONE, .ANYONECANPAY_SINGLE:
            return .zero
        case .DEFAULT:
            preconditionFailure()
        }
    }
    
    @usableFromInline
    static func hashOutputs<Transaction: TransactionProtocol>(for type: Tx.Signature.SigHashType,
                                                              tx: Transaction,
                                                              inputIndex: Int)
    -> BlockChain.Hash<SignatureHash> {
        switch type {
        case .SINGLE, .ANYONECANPAY_SINGLE:
            guard inputIndex < tx.vout.count else {
                return .zero
            }
            fallthrough
        case .ALL, .ANYONECANPAY_ALL:
            return .makeHash(from:
                tx.vout.flatMap {
                    $0.cTxOut()
                }
            )
        case .NONE, .ANYONECANPAY_NONE:
            return .zero
        case .DEFAULT:
            preconditionFailure()
        }
    }
}
