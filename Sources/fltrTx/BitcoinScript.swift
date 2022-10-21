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
import bech32

public typealias Script = [BitcoinScript.OpCodeData]

public enum BitcoinScript {}

public extension BitcoinScript {
    enum OpCodeData: Hashable {
        case error(UInt8, [UInt8])
        case opN(UInt8)
        case pushdata0([UInt8])
        case pushdata1([UInt8])
        case pushdata2([UInt8])
        case pushdata4([UInt8])
        case other(UInt8)
    }
    
    enum AddressType {
        case P2PKH(String)
        case P2WPKH(String)
        case P2SH(String)
        case P2TR(String)
        case unknown
        
        public var value: String? {
            switch self {
            case .P2PKH(let value),
                    .P2WPKH(let value),
                    .P2SH(let value),
                    .P2TR(let value):
                return value
            case .unknown:
                return nil
            }
        }
    }
    
    enum SegwitVersion: UInt8 {
        case v0 = 0x00 // OP_0
        case v1 = 0x51 // OP_1
//        case v2 = 0x52 // OP_2
    }
}

public extension BitcoinScript.OpCodeData {
    var isPushdata: Bool {
        switch self {
        case .pushdata0, .pushdata1, .pushdata2, .pushdata4:
            return true
        case .error, .opN, .other:
            return false
        }
    }
    
    var isError: Bool {
        switch self {
        case .error:
            return true
        case .opN, .other, .pushdata0, .pushdata1, .pushdata2, .pushdata4:
            return false
        }
    }
    
    var opN: UInt8? {
        switch self {
        case .opN(let i):
            return i
        case .error, .other, .pushdata0, .pushdata1, .pushdata2, .pushdata4:
            return nil
        }
    }
    
    init<C: Collection>(pushdata: C) where C.Element == UInt8 {
        let buffer = Array(pushdata)
        switch buffer.count {
        case (0..<Int(OpCodes.OP_PUSHDATA1)):
            self = .pushdata0(buffer)
        case (Int(OpCodes.OP_PUSHDATA1)...Int(UInt8.max)):
            self = .pushdata1(buffer)
        case ((Int(UInt8.max) + 1)...Int(UInt16.max)):
            self = .pushdata2(buffer)
        case ((Int(UInt16.max) + 1)...Int(UInt32.max)):
            self = .pushdata4(buffer)
        default:
            preconditionFailure()
        }
    }
}

public extension Sequence where Element == BitcoinScript.OpCodeData {
    var length: Int {
        self.reduce(0) { acc, next in
            acc + {
                switch next {
                case .error(_, let buffer),
                        .pushdata0(let buffer):
                    return MemoryLayout<UInt8>.size + buffer.count
                case .pushdata1(let buffer):
                    return MemoryLayout<UInt8>.size + MemoryLayout<UInt8>.size + buffer.count
                case .pushdata2(let buffer):
                    return MemoryLayout<UInt8>.size + MemoryLayout<UInt16>.size + buffer.count
                case .pushdata4(let buffer):
                    return MemoryLayout<UInt8>.size + MemoryLayout<UInt32>.size + buffer.count
                case .opN, .other:
                    return MemoryLayout<UInt8>.size
                }
            }()
        }
    }
    
    var isP2SH: Bool {
        var it = self.makeIterator()
        
        guard let op1 = it.next(), op1 == .other(OpCodes.OP_HASH160),
            let op2 = it.next(), case .pushdata0(let data) = op2, data.count == 20,
            let op3 = it.next(), op3 == .other(OpCodes.OP_EQUAL),
            it.next() == nil else {
                return false
        }
        
        return true
    }

    var segwitVersion: BitcoinScript.SegwitVersion? {
        var it = self.makeIterator()
        
        guard let version = it.next()?.opN else {
            return nil
        }
        
        switch version {
        case 0:
            guard let op2 = it.next(),
                case .pushdata0(let data) = op2,
                data.count == 20 || data.count == 32,
                it.next() == nil
            else { return nil }
            return .v0
        case 1:
            guard let op2 = it.next(),
                  case .pushdata0(let data) = op2,
                  data.count == 32,
                  it.next() == nil
            else { return nil }
            return .v1
        default:
            return nil
        }
    }
    
    func address(_ network: Network) -> BitcoinScript.AddressType {
        var it = self.makeIterator()
        
        switch it.next() {
        case .some(.opN(0)): // P2WPKH
            guard let op2 = it.next(),
                  case .pushdata0(let data) = op2,
                  data.count == 20,
                  it.next() == nil,
                  let bech32 = try? Bech32.addressEncode(network.bech32HumanReadablePart,
                                                         version: 0,
                                                         witnessProgram: data)
            else { return .unknown }

            return BitcoinScript.AddressType.P2WPKH(bech32)
        case .some(.opN(1)): // P2TR
            guard let op2 = it.next(),
                  case .pushdata0(let data) = op2,
                  data.count == 32,
                  it.next() == nil,
                  let bech32m = try? Bech32.addressEncode(network.bech32HumanReadablePart,
                                                          version: 1,
                                                          witnessProgram: data)
            else { return .unknown }
            
            return BitcoinScript.AddressType.P2TR(bech32m)
        case .some(.other(OpCodes.OP_DUP)): // P2PKH
            guard let op2 = it.next(),
                  op2 == .other(OpCodes.OP_HASH160),
                  let op3 = it.next(),
                  case .pushdata0(let data) = op3,
                  data.count == 20,
                  let op4 = it.next(),
                  op4 == .other(OpCodes.OP_EQUALVERIFY),
                  let op5 = it.next(),
                  op5 == .other(OpCodes.OP_CHECKSIG),
                  it.next() == nil
            else { return .unknown }
            
            return BitcoinScript.AddressType.P2PKH(
                ([ network
                    .legacyAddressPrefix
                    .rawValue
                    .pubkey ] + data)
                .base58CheckEncode()
            )
        case .some(.other(OpCodes.OP_HASH160)): // P2SH
            guard let op2 = it.next(),
                  case .pushdata0(let data) = op2,
                  data.count == 20,
                  let op3 = it.next(),
                  op3 == .other(OpCodes.OP_EQUAL),
                  it.next() == nil
            else { return .unknown }

            return BitcoinScript.AddressType.P2SH(
                ([ network
                    .legacyAddressPrefix
                    .rawValue
                    .script ] + data)
                .base58CheckEncode()
            )
        default:
            return.unknown
        }
    }
    
    var bytes: [UInt8] {
        self.reduce(into: []) {
            switch $1 {
            case .error(let opCode, let buffer):
                $0.append(opCode)
                $0.append(contentsOf: buffer)
            case .opN(let n) where n == 0:
                $0.append(n)
            case .opN(let n):
                $0.append(n + OpCodes.OP_1 - 1)
            case .other(let n):
                $0.append(n)
            case .pushdata0(let buffer):
                $0.append(UInt8(buffer.count))
                $0.append(contentsOf: buffer)
            case .pushdata1(let buffer):
                $0.append(OpCodes.OP_PUSHDATA1)
                $0.append(UInt8(buffer.count))
                $0.append(contentsOf: buffer)
            case .pushdata2(let buffer):
                $0.append(OpCodes.OP_PUSHDATA2)
                $0.append(contentsOf: UInt16(buffer.count).littleEndianBytes)
                $0.append(contentsOf: buffer)
            case .pushdata4(let buffer):
                $0.append(OpCodes.OP_PUSHDATA4)
                $0.append(contentsOf: UInt32(buffer.count).littleEndianBytes)
                $0.append(contentsOf: buffer)
            }
        }
    }
}

fileprivate extension BitcoinScript {
    struct NotEnoughBytes: Swift.Error {}
}

public extension BitcoinScript {
    enum ScriptDecodeError: Swift.Error {
        case emptyScript
        case insufficientPushData
    }
}

public extension Sequence where Element == UInt8 {
    var script: Result<Script, BitcoinScript.ScriptDecodeError> {
        var it = self.makeIterator()
        
        func read(length: Int) -> [UInt8]? {
            do {
                return try (0..<length).map { _ in
                    guard let next = it.next()
                    else { throw BitcoinScript.NotEnoughBytes() }
                    return next
                }
            } catch {
                return nil
            }
        }
        
        func littleEndian(bytes: [UInt8]) -> Int {
            Int(
                bytes.reversed().reduce(0) { soFar, byte in
                    return soFar << 8 | UInt64(byte)
                }
            )
        }
        
        func nextChunk() -> Result<BitcoinScript.OpCodeData,
                                   BitcoinScript.ScriptDecodeError>? {
            guard let opCode = it.next()
            else { return nil }
            
            switch opCode {
            case 0:
                return .success(.opN(0))
            case 1..<OpCodes.OP_PUSHDATA1:
                guard let data = read(length: Int(opCode))
                else { return .failure(.insufficientPushData) }
                
                return .success(.pushdata0(data))
            case OpCodes.OP_PUSHDATA1:
                guard let sizeBytes = it.next(),
                      let data = read(length: Int(sizeBytes))
                else { return .failure(.insufficientPushData) }
                
                return .success(.pushdata1(data))
            case OpCodes.OP_PUSHDATA2:
                guard let sizeBytes = read(length: 2),
                      let data = read(length: littleEndian(bytes: sizeBytes))
                else { return .failure(.insufficientPushData) }
                
                return .success(.pushdata2(data))
            case OpCodes.OP_PUSHDATA4:
                guard let sizeBytes = read(length: 4),
                      let data = read(length: littleEndian(bytes: sizeBytes))
                else { return .failure(.insufficientPushData) }
                
                return .success(.pushdata4(data))
            case (OpCodes.OP_1...OpCodes.OP_16):
                return .success(.opN(1 + opCode - OpCodes.OP_1))
            default:
                return .success(.other(opCode))
            }
        }
        
        var chunks: Script = []
        while let chunk = nextChunk() {
            switch chunk {
            case .success(let value):
                chunks.append(value)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(chunks)
    }
}
