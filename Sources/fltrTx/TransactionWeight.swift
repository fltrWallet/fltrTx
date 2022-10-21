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
public extension TransactionProtocol {
    @usableFromInline
    internal static var SegwitScaleFactor: Int { 4 }
    
    @inlinable
    var coreSize: Int {
        8 // version + locktime
            + self.vin.count.variableLengthCode.count
            + self.vin.map {
                40 + $0.scriptSig.count.variableLengthCode.count + $0.scriptSig.count
                // 32 byte hash + 4 byte index + 4 byte sequence
            }
            .reduce(0, +)
            + self.vout.count.variableLengthCode.count
            + self.vout.map { (out: Tx.Out) -> Int in
                8 + out.scriptPubKey.count.variableLengthCode.count + out.scriptPubKey.count
            }
            .reduce(0, +)
    }
    
    @inlinable
    var witnessSize: Int {
        guard self.hasWitnesses else {
            return 0
        }

        var sum = 2 // header? 0001?
        self.vin.forEach {
            if let witness = $0.witness {
                sum += witness.witnessField.count.variableLengthCode.count
                witness.witnessField.forEach {
                    sum += $0.count.variableLengthCode.count
                    sum += $0.count
                }
            } else {
                sum += 1 // witness field variable length code 00
            }
        }
        
        return sum
    }
    
    @inlinable
    var size: Int {
        self.coreSize + self.witnessSize
    }
    
    @inlinable
    var weight: Int {
        self.coreSize * Self.SegwitScaleFactor + self.witnessSize
    }

    @inlinable
    var vBytes: Double {
        Double(self.weight) / Double(Self.SegwitScaleFactor)
    }
}
