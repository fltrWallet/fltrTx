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

public extension Tx {
    enum TapRoot {}
}

extension Tx.TapRoot {
    @inlinable
    public static func sigHash<Transaction>(tx: Transaction,
                                            inputIndex: Int,
                                            type: Tx.Signature.SigHashType,
                                            prevouts: [Tx.Out],
                                            annex: [UInt8] = [])
    -> BlockChain.Hash<TapSighash>
    where Transaction: TransactionProtocol {
        precondition(tx.vin.count == prevouts.count)
        precondition(inputIndex < tx.vin.count)

        func isAll() -> Bool {
            switch type {
            case .DEFAULT, .ALL, .ANYONECANPAY_ALL:
                return true
            case .ANYONECANPAY_NONE, .ANYONECANPAY_SINGLE,
                 .NONE, .SINGLE:
                return false
            }
        }
        
        func isAnyoneCanPay() -> Bool {
            switch type {
            case .ANYONECANPAY_ALL, .ANYONECANPAY_NONE,
                 .ANYONECANPAY_SINGLE:
                return true
            case .DEFAULT, .ALL, .NONE, .SINGLE:
                return false
            }
        }
        
        func isSingle() -> Bool {
            switch type {
            case .ANYONECANPAY_SINGLE, .SINGLE:
                return true
            case .ANYONECANPAY_NONE, .ANYONECANPAY_ALL,
                 .DEFAULT, .ALL, .NONE:
                return false
            }
        }
        
        var ss: [UInt8] = []
        ss.append(contentsOf: [ 0, type.rawValue ])
        ss.append(contentsOf: UInt32(bitPattern: tx.version).littleEndianBytes)
        ss.append(contentsOf: tx.locktime.intValue.littleEndianBytes)

        if !isAnyoneCanPay() {
            ss.append(
                contentsOf: tx.vin.flatMap {
                    $0.outpoint.transactionId.littleEndian
                        + $0.outpoint.index.littleEndianBytes
                }
                .sha256
            )
            ss.append(
                contentsOf: prevouts.flatMap {
                    $0.value.littleEndianBytes
                }
                .sha256
            )
            ss.append(
                contentsOf: prevouts.flatMap {
                    $0.scriptPubKey.count.variableLengthCode + $0.scriptPubKey
                }
                .sha256
            )
            ss.append(
                contentsOf: tx.vin.flatMap {
                    $0.sequence.rawValue.littleEndianBytes
                }
                .sha256
            )
        }
        
        if isAll() {
            ss.append(
                contentsOf: tx.vout.flatMap {
                    $0.cTxOut()
                }
                .sha256
            )
        }
        
        let spendType: UInt8 = {
            if annex.count > 0 {
                return 1
            }
            
            return 0
        }()
        ss.append(spendType)
        
        if isAnyoneCanPay() {
            ss.append(contentsOf: tx.vin[inputIndex].outpoint.transactionId.littleEndian
                        + tx.vin[inputIndex].outpoint.index.littleEndianBytes)
            ss.append(contentsOf: prevouts[inputIndex].value.littleEndianBytes)
            ss.append(contentsOf: prevouts[inputIndex].scriptPubKey.count.variableLengthCode
                        + prevouts[inputIndex].scriptPubKey)
            ss.append(contentsOf: tx.vin[inputIndex].sequence.rawValue.littleEndianBytes)
        } else {
            ss.append(contentsOf: UInt32(inputIndex).littleEndianBytes)
        }
        
        if annex.count > 0 {
            let annexSerial: [UInt8] = annex.count.variableLengthCode + annex
            ss.append(contentsOf: annexSerial.sha256)
        }
        
        if isSingle() {
            if inputIndex < tx.vout.count {
                ss.append(
                    contentsOf: tx.vout[inputIndex]
                        .cTxOut()
                        .sha256
                )
            } else {
                ss.append(contentsOf: (0..<32).map { _ in UInt8(0) })
            }
        }
        
        assert(
            ss.count == 175
                - (isAnyoneCanPay() ? 49 : 0)
                - (!isAll() && !isSingle() ? 32 : 0)
                + (annex.count == 0 ? 0 : 32)
        )
        return .makeHash(from: ss)
    }
}
