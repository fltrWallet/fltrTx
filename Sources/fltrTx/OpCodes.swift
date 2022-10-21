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
public enum OpCodes {
    // push value
    public static let OP_0: UInt8 = 0x00
    public static let OP_FALSE: UInt8 = Self.OP_0
    public static let OP_PUSHDATA1: UInt8 = 0x4c
    public static let OP_PUSHDATA2: UInt8 = 0x4d
    public static let OP_PUSHDATA4: UInt8 = 0x4e
    public static let OP_1NEGATE: UInt8 = 0x4f
    public static let OP_RESERVED: UInt8 = 0x50
    public static let OP_1: UInt8 = 0x51
    public static let OP_TRUE: UInt8 = Self.OP_1
    public static let OP_2: UInt8 = 0x52
    public static let OP_3: UInt8 = 0x53
    public static let OP_4: UInt8 = 0x54
    public static let OP_5: UInt8 = 0x55
    public static let OP_6: UInt8 = 0x56
    public static let OP_7: UInt8 = 0x57
    public static let OP_8: UInt8 = 0x58
    public static let OP_9: UInt8 = 0x59
    public static let OP_10: UInt8 = 0x5a
    public static let OP_11: UInt8 = 0x5b
    public static let OP_12: UInt8 = 0x5c
    public static let OP_13: UInt8 = 0x5d
    public static let OP_14: UInt8 = 0x5e
    public static let OP_15: UInt8 = 0x5f
    public static let OP_16: UInt8 = 0x60
    
    // control
    public static let OP_NOP: UInt8 = 0x61
    public static let OP_VER: UInt8 = 0x62
    public static let OP_IF: UInt8 = 0x63
    public static let OP_NOTIF: UInt8 = 0x64
    public static let OP_VERIF: UInt8 = 0x65
    public static let OP_VERNOTIF: UInt8 = 0x66
    public static let OP_ELSE: UInt8 = 0x67
    public static let OP_ENDIF: UInt8 = 0x68
    public static let OP_VERIFY: UInt8 = 0x69
    public static let OP_RETURN: UInt8 = 0x6a
    
    // stack ops
    public static let OP_TOALTSTACK: UInt8 = 0x6b
    public static let OP_FROMALTSTACK: UInt8 = 0x6c
    public static let OP_2DROP: UInt8 = 0x6d
    public static let OP_2DUP: UInt8 = 0x6e
    public static let OP_3DUP: UInt8 = 0x6f
    public static let OP_2OVER: UInt8 = 0x70
    public static let OP_2ROT: UInt8 = 0x71
    public static let OP_2SWAP: UInt8 = 0x72
    public static let OP_IFDUP: UInt8 = 0x73
    public static let OP_DEPTH: UInt8 = 0x74
    public static let OP_DROP: UInt8 = 0x75
    public static let OP_DUP: UInt8 = 0x76
    public static let OP_NIP: UInt8 = 0x77
    public static let OP_OVER: UInt8 = 0x78
    public static let OP_PICK: UInt8 = 0x79
    public static let OP_ROLL: UInt8 = 0x7a
    public static let OP_ROT: UInt8 = 0x7b
    public static let OP_SWAP: UInt8 = 0x7c
    public static let OP_TUCK: UInt8 = 0x7d
    
    // splice ops
    public static let OP_CAT: UInt8 = 0x7e
    public static let OP_SUBSTR: UInt8 = 0x7f
    public static let OP_LEFT: UInt8 = 0x80
    public static let OP_RIGHT: UInt8 = 0x81
    public static let OP_SIZE: UInt8 = 0x82
    
    // bit logic
    public static let OP_INVERT: UInt8 = 0x83
    public static let OP_AND: UInt8 = 0x84
    public static let OP_OR: UInt8 = 0x85
    public static let OP_XOR: UInt8 = 0x86
    public static let OP_EQUAL: UInt8 = 0x87
    public static let OP_EQUALVERIFY: UInt8 = 0x88
    public static let OP_RESERVED1: UInt8 = 0x89
    public static let OP_RESERVED2: UInt8 = 0x8a
    
    // numeric
    public static let OP_1ADD: UInt8 = 0x8b
    public static let OP_1SUB: UInt8 = 0x8c
    public static let OP_2MUL: UInt8 = 0x8d
    public static let OP_2DIV: UInt8 = 0x8e
    public static let OP_NEGATE: UInt8 = 0x8f
    public static let OP_ABS: UInt8 = 0x90
    public static let OP_NOT: UInt8 = 0x91
    public static let OP_0NOTEQUAL: UInt8 = 0x92
    
    public static let OP_ADD: UInt8 = 0x93
    public static let OP_SUB: UInt8 = 0x94
    public static let OP_MUL: UInt8 = 0x95
    public static let OP_DIV: UInt8 = 0x96
    public static let OP_MOD: UInt8 = 0x97
    public static let OP_LSHIFT: UInt8 = 0x98
    public static let OP_RSHIFT: UInt8 = 0x99
    
    public static let OP_BOOLAND: UInt8 = 0x9a
    public static let OP_BOOLOR: UInt8 = 0x9b
    public static let OP_NUMEQUAL: UInt8 = 0x9c
    public static let OP_NUMEQUALVERIFY: UInt8 = 0x9d
    public static let OP_NUMNOTEQUAL: UInt8 = 0x9e
    public static let OP_LESSTHAN: UInt8 = 0x9f
    public static let OP_GREATERTHAN: UInt8 = 0xa0
    public static let OP_LESSTHANOREQUAL: UInt8 = 0xa1
    public static let OP_GREATERTHANOREQUAL: UInt8 = 0xa2
    public static let OP_MIN: UInt8 = 0xa3
    public static let OP_MAX: UInt8 = 0xa4
    
    public static let OP_WITHIN: UInt8 = 0xa5
    
    // crypto
    public static let OP_RIPEMD160: UInt8 = 0xa6
    public static let OP_SHA1: UInt8 = 0xa7
    public static let OP_SHA256: UInt8 = 0xa8
    public static let OP_HASH160: UInt8 = 0xa9
    public static let OP_HASH256: UInt8 = 0xaa
    public static let OP_CODESEPARATOR: UInt8 = 0xab
    public static let OP_CHECKSIG: UInt8 = 0xac
    public static let OP_CHECKSIGVERIFY: UInt8 = 0xad
    public static let OP_CHECKMULTISIG: UInt8 = 0xae
    public static let OP_CHECKMULTISIGVERIFY: UInt8 = 0xaf
    
    // expansion
    public static let OP_NOP1: UInt8 = 0xb0
    public static let OP_CHECKLOCKTIMEVERIFY: UInt8 = 0xb1
    public static let OP_NOP2: UInt8 = Self.OP_CHECKLOCKTIMEVERIFY
    public static let OP_CHECKSEQUENCEVERIFY: UInt8 = 0xb2
    public static let OP_NOP3: UInt8 = Self.OP_CHECKSEQUENCEVERIFY
    public static let OP_NOP4: UInt8 = 0xb3
    public static let OP_NOP5: UInt8 = 0xb4
    public static let OP_NOP6: UInt8 = 0xb5
    public static let OP_NOP7: UInt8 = 0xb6
    public static let OP_NOP8: UInt8 = 0xb7
    public static let OP_NOP9: UInt8 = 0xb8
    public static let OP_NOP10: UInt8 = 0xb9
    
    public static let OP_INVALIDOPCODE: UInt8 = 0xff
}
