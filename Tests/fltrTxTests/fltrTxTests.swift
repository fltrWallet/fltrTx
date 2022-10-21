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
import NIOCore
import fltrECC
import fltrECCTesting
@testable import fltrTx
import XCTest

final class fltrTxTests: XCTestCase {
    func testTxAnyTransaction() {
        var buffer = Self.legacyTx1.buffer
        guard let legacyTx1 = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        switch legacyTx1 {
        case .legacy:
            break
        case .segwit:
            XCTFail()
        }
        
        var encoded = allocator.buffer(capacity: 4096)
        legacyTx1.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx1)
        
        encoded = allocator.buffer(capacity: 4096)
        let id = Tx.AnyIdentifiableTransaction(legacyTx1)
        id.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx1)
        XCTAssertEqual(Array(id.txId.bigEndian),
                       "0627052b6f28912f2703066a912ea577f2ce4da4caa5a5fbd8a57286c345c2f2".hex2Bytes)
        
        buffer = Self.tx1.buffer
        guard let tx1 = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        switch tx1 {
        case .legacy:
            XCTFail()
        case .segwit:
            break
        }
        
        encoded = allocator.buffer(capacity: 4096)
        let id1 = Tx.AnyIdentifiableTransaction(tx1)
        id1.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.tx1)
        XCTAssertEqual(Array(id1.txId.bigEndian),
                       "7b9de05535a389fe6c68cdc89337b991d84eca0230b2a4bfc834dca7037527ce".hex2Bytes)
        XCTAssertEqual(Array(id1.wtxId.bigEndian),
                       "b19228be2b6a527e8738296da7e0cf85422def598aa876ff065b4909d59e139b".hex2Bytes)

        buffer = Self.tx2.buffer
        guard let tx2 = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        switch tx2 {
        case .legacy:
            XCTFail()
        case .segwit:
            break
        }
        
        encoded = allocator.buffer(capacity: 4096)
        let id2 = Tx.AnyIdentifiableTransaction(tx2)
        id2.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.tx2)
        XCTAssertEqual(Array(id2.txId.bigEndian),
                       "91e87bf5af606372f1f7d2fb6b74c88fe62249e8369cc4b6f00e25fbb0c2b75a".hex2Bytes)
        XCTAssertEqual(Array(id2.wtxId.bigEndian),
                       "480f58dec67e76244a15d1999c919771a3ff343a6c721891465f37c7fa469c4a".hex2Bytes)
    }
    
    func testTxLegacyTransaction1() {
        var buffer = Self.legacyTx1.buffer
        guard let legacyTx1 = Tx.LegacyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        var encoded = allocator.buffer(capacity: 4096)
        legacyTx1.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx1)
        
        encoded = allocator.buffer(capacity: 4096)
        let id = Tx.LegacyIdentifiableTransaction(legacyTx1)
        id.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx1)
        XCTAssertEqual(Array(id.txId.bigEndian),
                       "0627052b6f28912f2703066a912ea577f2ce4da4caa5a5fbd8a57286c345c2f2".hex2Bytes)
        
        buffer = Self.legacyTx1.buffer
        XCTAssertNil(Tx.SegwitTransaction(fromBuffer: &buffer))
    }

    func testTxLegacyTransaction2() {
        var buffer = Self.legacyTx2.buffer
        guard let legacyTx2 = Tx.LegacyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        var encoded = allocator.buffer(capacity: 4096)
        legacyTx2.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx2)
        
        encoded = allocator.buffer(capacity: 4096)
        let id = Tx.LegacyIdentifiableTransaction(legacyTx2)
        id.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.legacyTx2)
        XCTAssertEqual(Array(id.txId.bigEndian),
                       "7301b595279ece985f0c415e420e425451fcf7f684fcce087ba14d10ffec1121".hex2Bytes)
        
        buffer = Self.legacyTx2.buffer
        XCTAssertNil(Tx.SegwitTransaction(fromBuffer: &buffer))
    }
    
    func testTxSegwitTransaction() {
        var buffer = Self.tx1.buffer
        guard let tx1 = Tx.SegwitTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        var encoded = allocator.buffer(capacity: 4096)
        let id1 = Tx.SegwitIdentifiableTransaction(tx1)
        id1.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.tx1)
        XCTAssertEqual(Array(id1.txId.bigEndian),
                       "7b9de05535a389fe6c68cdc89337b991d84eca0230b2a4bfc834dca7037527ce".hex2Bytes)
        XCTAssertEqual(Array(id1.wtxId.bigEndian),
                       "b19228be2b6a527e8738296da7e0cf85422def598aa876ff065b4909d59e139b".hex2Bytes)

        buffer = Self.tx2.buffer
        guard let tx2 = Tx.SegwitTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        
        encoded = allocator.buffer(capacity: 4096)
        let id2 = Tx.SegwitIdentifiableTransaction(tx2)
        id2.write(to: &encoded)
        XCTAssertEqual(Array(encoded.readableBytesView), Self.tx2)
        XCTAssertEqual(Array(id2.txId.bigEndian),
                       "91e87bf5af606372f1f7d2fb6b74c88fe62249e8369cc4b6f00e25fbb0c2b75a".hex2Bytes)
        XCTAssertEqual(Array(id2.wtxId.bigEndian),
                       "480f58dec67e76244a15d1999c919771a3ff343a6c721891465f37c7fa469c4a".hex2Bytes)
        
        encoded = allocator.buffer(capacity: 4096)
        let tx2Legacy = Tx.LegacyIdentifiableTransaction(id2)
        tx2Legacy.write(to: &encoded)
        XCTAssertNotEqual(Array(encoded.readableBytesView), Self.tx2)
        XCTAssertEqual(Array(tx2Legacy.txId.bigEndian),
                       "91e87bf5af606372f1f7d2fb6b74c88fe62249e8369cc4b6f00e25fbb0c2b75a".hex2Bytes)
        XCTAssertEqual(Array(tx2Legacy.wtxId.bigEndian),
                       "91e87bf5af606372f1f7d2fb6b74c88fe62249e8369cc4b6f00e25fbb0c2b75a".hex2Bytes)
    }
    
    func testDecodeEncode1() {
        var buffer = Self.tx1.buffer
        guard let tx1 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        var encoded = allocator.buffer(capacity: 4096)
        tx1.writeSegwitTransaction(to: &encoded)
        let bytes: [UInt8] = Array(encoded.readableBytesView)
        XCTAssertEqual(Self.tx1, bytes)
    }
    
    func testDecodeEncode2() {
        var buffer = Self.tx2.buffer
        guard let tx2 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        var encoded = allocator.buffer(capacity: 4096)
        tx2.writeSegwitTransaction(to: &encoded)
        let bytes: [UInt8] = Array(encoded.readableBytesView)
        XCTAssertEqual(Self.tx2, bytes)
    }
    
    func testVerifySignatures1() {
        var buffer = Self.tx1.buffer
        guard let tx1 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        XCTAssert(tx1.verifySignature(index: 0, prevouts: Self.tx1Prevouts))
        XCTAssert(tx1.verifySignature(index: 1, prevouts: Self.tx1Prevouts))

        XCTAssertFalse(tx1.verifySignature(index: -1, prevouts: Self.tx1Prevouts))
        XCTAssertFalse(tx1.verifySignature(index: 2, prevouts: Self.tx1Prevouts))
        XCTAssertFalse(tx1.verifySignature(index: 0, prevouts: [ Tx.Out(value: 0, scriptPubKey: []), Tx.Out(value: 0, scriptPubKey: []) ]))
        XCTAssertFalse(tx1.verifySignature(index: 1, prevouts: Self.tx1Prevouts.reversed()))
        
        buffer = Self.tx1.buffer
        guard let anyTx1 = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        XCTAssert(anyTx1.verifySignature(index: 0, prevouts: Self.tx1Prevouts))
        XCTAssert(anyTx1.verifySignature(index: 1, prevouts: Self.tx1Prevouts))
        
        buffer = Self.tx1.buffer
        guard let witTx1 = Tx.SegwitTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        XCTAssert(witTx1.hasWitnesses)
        XCTAssert(witTx1.verifySignature(index: 0, prevouts: Self.tx1Prevouts))
        XCTAssert(witTx1.verifySignature(index: 1, prevouts: Self.tx1Prevouts))
    }
    
    func testVerifySignatures2() {
        var buffer = Self.tx2.buffer
        guard let tx2 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        XCTAssert(tx2.verifySignature(index: 0, prevouts: Self.tx2Prevouts))
        
        XCTAssertFalse(tx2.verifySignature(index: -1, prevouts: Self.tx2Prevouts))
        XCTAssertFalse(tx2.verifySignature(index: 1, prevouts: Self.tx2Prevouts))
        XCTAssertFalse(tx2.verifySignature(index: 2, prevouts: Self.tx2Prevouts))
        XCTAssertFalse(tx2.verifySignature(index: 0, prevouts: [ Tx.Out(value: 0, scriptPubKey: []) ]))

        buffer = Self.tx2.buffer
        guard let anyTx2 = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        XCTAssert(anyTx2.hasWitnesses)
        XCTAssert(anyTx2.verifySignature(index: 0, prevouts: Self.tx2Prevouts))
    }
    
    func testVerifyLegacy1() {
        var buffer = Self.legacyTx1.buffer
        guard let legacy1 = DummyTx.readLegacyTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        XCTAssert(legacy1.verifySignature(index: 0, prevouts: Self.legacyTx1Prevouts))

        XCTAssertFalse(legacy1.verifySignature(index: -1, prevouts: Self.legacyTx1Prevouts))
        XCTAssertFalse(legacy1.verifySignature(index: 1, prevouts: Self.legacyTx1Prevouts))
        XCTAssertFalse(legacy1.verifySignature(index: 2, prevouts: Self.legacyTx1Prevouts))
        XCTAssertFalse(legacy1.verifySignature(index: 0, prevouts: [ Tx.Out(value: 0, scriptPubKey: []) ]))

        buffer = Self.legacyTx1.buffer
        guard let any = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        XCTAssertFalse(any.hasWitnesses)
        XCTAssert(any.verifySignature(index: 0, prevouts: Self.legacyTx1Prevouts))
    }
    
    func testVerifyLegacy2() {
        var buffer = Self.legacyTx2.buffer
        guard let legacy2 = DummyTx.readLegacyTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        XCTAssert(legacy2.verifySignature(index: 0, prevouts: Self.legacyTx2Prevouts))

        XCTAssertFalse(legacy2.verifySignature(index: -1, prevouts: Self.legacyTx2Prevouts))
        XCTAssertFalse(legacy2.verifySignature(index: 1, prevouts: Self.legacyTx2Prevouts))
        XCTAssertFalse(legacy2.verifySignature(index: 2, prevouts: Self.legacyTx2Prevouts))
        XCTAssertFalse(legacy2.verifySignature(index: 0, prevouts: [ Tx.Out(value: 0, scriptPubKey: []) ]))

        buffer = Self.legacyTx2.buffer
        guard let any = Tx.AnyTransaction(fromBuffer: &buffer)
        else { XCTFail(); return }
        XCTAssertFalse(any.hasWitnesses)
        XCTAssert(any.verifySignature(index: 0, prevouts: Self.legacyTx2Prevouts))
    }
    
    func testAddressDecoder1() {
        var buffer = Self.tx1.buffer
        guard let tx1 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        guard let address0 = AddressDecoder(decoding: "2N2xsSUVnsV3NUCYZgQd7VoZQdQjk3BCWVU",
                                            network: .testnet),
              let address1 = AddressDecoder(decoding: "2NBKFDVbkRAMDeEVcUb2FnsvXgCFwH7pgMF",
                                            network: .testnet)
        else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(address0.scriptPubKey, tx1.vout[0].scriptPubKey)
        XCTAssertEqual(address1.scriptPubKey, tx1.vout[1].scriptPubKey)
    }
    
    func testAddressDecoder2() {
        var buffer = Self.tx2.buffer
        guard let tx2 = DummyTx.readWitnessTransaction(buffer: &buffer)
        else {
            XCTFail()
            return
        }
        
        guard let address0 = AddressDecoder(decoding: "tb1qgt5f4ktrd3nz8cdpyhj2zs20cnl5avvjuf5au9z82q6jsp4dedeseherjq",
                                            network: .testnet),
              let address1 = AddressDecoder(decoding: "tb1qetrrnpjtayusgqqlxzz0tdyeqzhlln4fslv89u",
                                            network: .testnet)
        else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(address0.scriptPubKey, tx2.vout[0].scriptPubKey)
        XCTAssertEqual(address1.scriptPubKey, tx2.vout[1].scriptPubKey)
    }
    
    func testPublicKeyHashEquals() {
        let point = DSA.PublicKey(123)
        let publicKeyHash: PublicKeyHash = .init(point)
        
        let hash = point.serialize().hash160
        var hashInvalid = hash
        hashInvalid[hashInvalid.index(before: hashInvalid.endIndex)] &+= 1
        XCTAssertTrue(publicKeyHash.equals(hash))
        XCTAssertTrue(publicKeyHash.equals(hash[...]))
        XCTAssertFalse(publicKeyHash.equals(hashInvalid))
        XCTAssertFalse(publicKeyHash.equals(hash[1...]))
        XCTAssertFalse(publicKeyHash.equals(hash[..<hash.index(before: hash.endIndex)]))
        hashInvalid = hash + [0]
        XCTAssertFalse(publicKeyHash.equals(hashInvalid))
    }
}


// MARK: Testdata
extension fltrTxTests {
    // main TxId 0627052b6f28912f2703066a912ea577f2ce4da4caa5a5fbd8a57286c345c2f2
    static let legacyTx1: [UInt8] = """
0100000001186f9f998a5aa6f048e51dd8419a14d8a0f1a8a2836dd734d2804fe65fa35779000000008b483045022100884d142d86652a3f47ba4746ec719bbfbd040a570b1deccbb6498c75c4ae24cb02204b9f039ff08df09cbe9f6addac960298cad530a863ea8f53982c09db8f6e381301410484ecc0d46f1918b30928fa0e4ed99f16a0fb4fde0735e7ade8416ab9fe423cc5412336376789d172787ec3457eee41c04f4938de5cc17b4a10fa336a8d752adfffffffff0260e31600000000001976a914ab68025513c3dbd2f7b92a94e0581f5d50f654e788acd0ef8000000000001976a9147f9b1a7fb68d60c536c2fd8aeaa53a8f3cc025a888ac00000000
""".hex2Bytes
    static let legacyTx1Prevouts: [Tx.Out] = [
        .init(value: 10_000_000,
              scriptPubKey: [ OpCodes.OP_DUP, OpCodes.OP_HASH160, 0x14 ]
              + "7f9b1a7fb68d60c536c2fd8aeaa53a8f3cc025a8".hex2Bytes
              + [ OpCodes.OP_EQUALVERIFY, OpCodes.OP_CHECKSIG ]),
    ]

    // main TxId 7301b595279ece985f0c415e420e425451fcf7f684fcce087ba14d10ffec1121
    static let legacyTx2: [UInt8] = """
01000000014dff4050dcee16672e48d755c6dd25d324492b5ea306f85a3ab23b4df26e16e9000000008c493046022100cb6dc911ef0bae0ab0e6265a45f25e081fc7ea4975517c9f848f82bc2b80a909022100e30fb6bb4fb64f414c351ed3abaed7491b8f0b1b9bcd75286036df8bfabc3ea5014104b70574006425b61867d2cbb8de7c26095fbc00ba4041b061cf75b85699cb2b449c6758741f640adffa356406632610efb267cb1efa0442c207059dd7fd652eeaffffffff020049d971020000001976a91461cf5af7bb84348df3fd695672e53c7d5b3f3db988ac30601c0c060000001976a914fd4ed114ef85d350d6d40ed3f6dc23743f8f99c488ac00000000
""".hex2Bytes
    static let legacyTx2Prevouts: [Tx.Out] = [
        .init(value: 36_473_000_000,
              scriptPubKey: [ OpCodes.OP_DUP, OpCodes.OP_HASH160, 0x14 ]
              + "5478d152bb557ac994c9793cece77d4295ed37e3".hex2Bytes
              + [ OpCodes.OP_EQUALVERIFY, OpCodes.OP_CHECKSIG ]),
    ]

    // testnet block 1500004, transaction 1
    static let tx1: [UInt8] = "020000000001028fecba1dbccf97e465b0b37acade14d9cdc0847afbfe5a76bb1fe5d5bcbf0aa90100000017160014b46fef3b5b612965c7c0e33c35c1723717e8581dfeffffff97678f863b155f34fcbf36b3a8b2a8912a54cca078b52ecd9215d1be242d61a2010000001716001431f489ac1de2c8d451b3e661921a764adbf57915feffffff02eeac0f000000000017a9146a9973113e84d8f37f6162f2d7764eb0b78249c08740fb05000000000017a914c634f3ed0b44e0df8fe9f62ab420ade3b49bd96e870247304402200f29e830b5150822d51a24c169d26b6d0f7a2d7ad865487809f878ae90bab640022045643001957788d991b3a367171c1e8dc927aa141057c672f12afd8205207efa0121037d23c0f5322cfde7537c7cf7dd52afcbfd07554fbe0e28ffe29a62e756be1ebb02473044022018c3f98762e0424ce803d2d977f0240533ec3279eb2fe7fcd26ef317c067a65b022066b251573149eb218317563aeef66d2622a53c23f676509702b5a6a76f3edf49012102ecb946b4ce347aaa66eb1f7d557474ca89525c045d07a37c1da9843819d5497300000000".hex2Bytes
    
    static let tx1Prevouts: [Tx.Out] = [
        .init(value: 421_000, scriptPubKey: [ OpCodes.OP_HASH160,
                                              0x14, ]
                                              + "f02c18fae6a10448a049c6481bad7a43d10ecdab".hex2Bytes
                                              + [ OpCodes.OP_EQUAL, ]),
        .init(value: 999_990, scriptPubKey: [ OpCodes.OP_HASH160,
                                              0x14, ]
                                              + "524ba1cf81420ed120ce529045eb2c20694f85dc".hex2Bytes
                                              + [ OpCodes.OP_EQUAL, ]),
    ]
    
    static let tx2: [UInt8] =
        "01000000000101d7bb897172e632dd0bf37120e827b66b436ad5cb836a6038866302617e48bf2a0000000017160014a6bda58417ce77bd562a816f8cd913f99edd19b1ffffffff0200127a000000000022002042e89ad9636c6623e1a125e4a1414fc4ff4eb192e269de144750352806adcb73adac7b0500000000160014cac639864be93904001f3084f5b49900afffcea902483045022100d3e0d420bd4fcf900eeb34f9727e2493e584966c409767de6799fba203f86af702201d3feee9e3ba7187d415099eed50b6daa2359c73b01aa889f97354957a5fe2180121032cf7ce41ebccb51449e5709f5f68185dad9371320af73488358e868ce9552eff00000000".hex2Bytes
    
    static let tx2Prevouts: [Tx.Out] = [
        .init(value: 100_000_000, scriptPubKey: [ OpCodes.OP_HASH160,
                                                  0x14, ]
                                                  + "86b7c5501690c4f94ae151588237b05fe3ec3997".hex2Bytes
                                                  + [ OpCodes.OP_EQUAL, ]),
    ]
}

// MARK: Dummy implementation
struct DummyTx: TransactionSerializationProtocol {
    func write(to: inout ByteBuffer) {
        preconditionFailure()
    }
    
    init?(fromBuffer: inout ByteBuffer) {
        preconditionFailure()
    }
    
    internal init?(version: Int32, vin: [Tx.In], vout: [Tx.Out], locktime: Tx.Locktime) {
        self.version = version
        self.vin = vin
        self.vout = vout
        self.locktime = locktime
        self.hasWitnesses = true
    }
    
    func load(witness: [[UInt8]], index: Int) -> DummyTx {
        precondition(index < self.vin.count)
        var newTxIns: [Tx.In] = []
        for (i, txIn) in self.vin.enumerated() {
            let witness: Tx.Witness = {
                if i == index {
                    return .init(witnessField: witness)
                } else {
                    return .init(witnessField: [])
                }
            }()
            let newTxIn: Tx.In = .init(outpoint: txIn.outpoint,
                                       scriptSig: txIn.scriptSig,
                                       sequence: txIn.sequence,
                                       witness: { witness })
            newTxIns.append(newTxIn)
        }
        
        return DummyTx(version: self.version,
                       vin: newTxIns,
                       vout: self.vout,
                       locktime: self.locktime)!
    }
    
    var version: Int32
    var vin: [Tx.In]
    var vout: [Tx.Out]
    var locktime: Tx.Locktime
    var hasWitnesses: Bool
}

let allocator = ByteBufferAllocator()
extension Array where Element == UInt8 {
    var buffer: ByteBuffer {
        var buffer = allocator.buffer(capacity: 4096)
        buffer.writeBytes(self)
        
        return buffer
    }
}
