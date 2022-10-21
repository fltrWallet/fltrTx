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
public protocol IdentifiableTransactionProtocol: TransactionProtocol, Identifiable {
    @inlinable
    var txId: Tx.TxId { get }
    @inlinable
    var wtxId: Tx.WtxId { get }
}

public extension IdentifiableTransactionProtocol where Self.ID == Tx.TxId {
    @inlinable
    var id: Tx.TxId { self.txId }
}
