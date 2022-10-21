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
    var debugDescription: String {
        var out = String()
        out.append("Transaction\n")
        out.append("\tCore size: \(self.coreSize)")
        out.append("\tWitness size: \(self.witnessSize)")
        out.append("\tVirtual size: \(self.vBytes)")
        out.append("\tLocktime: \(self.locktime)")

        self.vin.enumerated().forEach { tuple in
            let (n, txIn) = tuple
            out.append("\n\tInput \(n)\(self.isCoinbase ? "\t\t[COINBASE]" : "")\n")
            if self.isCoinbase {
                out.append("\t\tScriptSig [\(txIn.scriptSig.hexEncodedString)]\n")
                out.append("\t\tWitness [\(txIn.witness?.witnessField.map { $0.hexEncodedString }.joined(separator: " | ") ?? "empty")]")
            } else {
                out.append("\t\tPrevious out: [\(txIn.outpoint.transactionId) : \(txIn.outpoint.index)]\n")
                out.append("\t\tScriptSig [\(txIn.scriptSig.hexEncodedString)]\n")
                out.append("\t\tWitness [\(txIn.witness?.witnessField.map { $0.hexEncodedString }.joined(separator: " | ") ?? "empty")]\n")
                out.append("\t\t\(txIn.sequence)")
            }
        }
        
        self.vout.enumerated().forEach { tuple in
            let (n, txOut) = tuple
            out.append("\n\tOutput \(n)\n")
            out.append("\t\tAmount mBTC [\(Double(txOut.value) / 100_000.0)]\n")
            out.append("\t\tScriptPubKey [\(txOut.scriptPubKey.hexEncodedString)]")
        }
      
        return out
    }
}

extension Tx.In: CustomDebugStringConvertible {
    @inlinable
    public var debugDescription: String {
        var result: [String] = []
        result.append("\(self.outpoint)")
        result.append("scriptSig: \(self.scriptSig)")
        result.append("\(self.sequence)")

        if let _ = self.witness {
            if let v1 = self.v1Signature {
                result.append("Witness[Schnorr with sigHash \(v1.sigHashType)]")
            } else if let v0 = self.v0Signature {
                result.append("Witness[ECDSA with type \(v0.sigHashType) pubKey: \(v0.publicKey)]")
            } else {
                result.append("UNKNOWN Witness")
            }
        } else {
            if let legacy = self.legacySignature {
                result.append("Legacy[P2PKH with sigHash \(legacy.sigHashType) pubKey: \(legacy.publicKey)]")
            } else {
                result.append("NO Witness")
            }
        }
        
        return "Tx.In(\(result.joined(separator: ", ")))"
    }
}

extension Tx.Out: CustomStringConvertible {
    public var description: String {
        "Amount mBTC [\(String(format: "%.2f", Double(self.value) / 100_000.0))]" +
        "\t ScriptPubKey [\(self.scriptPubKey.hexEncodedString)]"
    }
}

extension Tx.Outpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Outpoint(\(self.transactionId):\(self.index))"
    }
}

extension Tx.Sequence: CustomStringConvertible {
    public var description: String {
        guard !self.isDisabled else {
            return "BIP0068 sequence disabled [0x\(String(self.rawValue, radix: 16))]"
        }
        
        if let bip68Time = self.bip68Time {
            return "BIP0068 relative time seconds [\(bip68Time)]"
        }
        
        if let bip68RelativeBlock = self.bip68RelativeBlock {
            return "BIP0068 relative block [\(bip68RelativeBlock)]"
        }

        return "Non BIP0068 sequence number [\(String(self.rawValue, radix: 16))]"
    }
}
