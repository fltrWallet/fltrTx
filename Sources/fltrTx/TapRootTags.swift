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
import HaByLo

public enum TapBranch: TaggedHash {
    public static var tag: [UInt8] = "TapBranch".utf8.sha256
}

public enum TapLeaf: TaggedHash {
    public static var tag: [UInt8] = "TapLeaf".utf8.sha256
}

public enum TapSighash: TaggedHash {
    public static var tag: [UInt8] = "TapSighash".utf8.sha256
}

public enum TapTweak: TaggedHash {
    public static var tag: [UInt8] = "TapTweak".utf8.sha256
}

public enum TapChallenge: TaggedHash {
    public static var tag: [UInt8] = "BIP0340/challenge".utf8.sha256
}

