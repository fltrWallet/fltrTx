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
@testable import fltrTx
import XCTest

final class TapRootTests: XCTestCase {
    func loadTestVectors() throws -> [TestTx] {
        let url = Bundle.module.url(forResource: "TapRootData", withExtension: "json")!
        let data = try Data(contentsOf: url)
        
        return try JSONDecoder().decode([TestTx].self, from: data)
    }
    
    func load(test: TestTx) -> (DummyTx, [Tx.Out], Int)? {
        var buffer = test.tx.buffer
        guard let tx = DummyTx.readLegacyTransaction(buffer: &buffer)?
            .load(witness: test.witness, index: test.index)
        else { return nil }
        
        let prevOuts: [Tx.Out] = test.prevOuts
        .compactMap {
            var buffer = $0.buffer
            guard let out = Tx.Out(fromBuffer: &buffer)
            else { return nil }
            
            return out
        }
        guard prevOuts.count == test.prevOuts.count
        else { return nil }
        
        return (tx, prevOuts, test.index)
    }
    
    func testVectorValid() {
        guard let tests = try? loadTestVectors()
        else {
            XCTFail()
            return
        }
        
        var testSet: [[TestTx]] = []
        testSet.append(tests.filter({$0.comment.hasPrefix("inactive/keypath_valid")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("sig/bitflip")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("sig/key")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("sighash/hashtype")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("sighash/keypath")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("sighash/purepk")}))
        testSet.append(tests.filter({$0.comment.hasPrefix("siglen/padzero_keypath")}))

        for test in testSet.joined() {
            guard let (tx, prevOuts, index) = load(test: test),
                  prevOuts.count == tx.vin.count
            else {
                XCTFail()
                return
            }

            XCTAssert(tx.verifySignature(index: index, prevouts: prevOuts))
        }
    }
}

struct TestTx: Decodable {
    struct Flags: OptionSet {
        let rawValue: UInt
        
        static let P2SH: Flags = .init(rawValue: 1)
        static let DERSIG: Flags = .init(rawValue: 1 << 1)
        static let CHECKLOCKTIMEVERIFY: Flags = .init(rawValue: 1 << 2)
        static let CHEKSEQUENCEVERIFY: Flags = .init(rawValue: 1 << 3)
        static let WITNESS: Flags = .init(rawValue: 1 << 4)
        static let NULLDUMMY: Flags = .init(rawValue: 1 << 5)
        static let TAPROOT: Flags = .init(rawValue: 1 << 6)
        
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        init(from rawFlags: String) {
            let rawFlags = rawFlags.split(separator: ",")
            var flags: Flags = []
            
            for flag in rawFlags {
                switch flag {
                case "P2SH":
                    flags.formUnion(.P2SH)
                case "DERSIG":
                    flags.formUnion(.DERSIG)
                case "CHECKLOCKTIMEVERIFY":
                    flags.formUnion(.CHECKLOCKTIMEVERIFY)
                case "CHECKSEQUENCEVERIFY":
                    flags.formUnion(.CHEKSEQUENCEVERIFY)
                case "WITNESS":
                    flags.formUnion(.WITNESS)
                case "NULLDUMMY":
                    flags.formUnion(.NULLDUMMY)
                case "TAPROOT":
                    flags.formUnion(.TAPROOT)
                default:
                    preconditionFailure("Unknown flag: [\(flag)]")
                }
            }
            
            self = flags
        }
    }
    
    let tx: [UInt8]
    let flags: Flags
    let prevOuts: [[UInt8]]
    let index: Int
    let comment: String
    let witness: [[UInt8]]
    let scriptSig: [UInt8]
    
    init(from decoder: Decoder) throws {
        let raw = try TestTxSerialized(from: decoder)
        self.tx = raw.tx.hex2Bytes
        self.flags = Flags(from: raw.flags)
        self.prevOuts = raw.prevouts.map { $0.hex2Bytes }
        self.index = raw.index
        self.comment = raw.comment
        self.witness = raw.success.witness.map {
            $0.hex2Bytes
        }
        self.scriptSig = raw.success.scriptSig.hex2Bytes
    }
}

struct TestTxSerialized: Decodable {
    struct ScriptPayload: Codable {
        let scriptSig: String
        let witness: [String]
    }
    
    let tx: String
    let prevouts: [String]
    let index: Int
    let success: ScriptPayload
    let failure: ScriptPayload?
    let flags: String
    let final: Bool?
    let comment: String
}
