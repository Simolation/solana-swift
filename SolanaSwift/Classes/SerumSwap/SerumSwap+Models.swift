//
//  SerumSwap+Models.swift
//  SolanaSwift
//
//  Created by Chung Tran on 11/08/2021.
//

import Foundation
import BufferLayoutSwift

extension SerumSwap {
    public struct SignersAndInstructions {
        let signers: [Account]
        let instructions: [TransactionInstruction]
    }
    
    /**
     * Parameters to perform a swap.
     */
    public struct SwapParams {
        /**
         * Token mint to swap from.
         */
        let fromMint: PublicKey
        
        /**
         * Token mint to swap to.
         */
        let toMint: PublicKey
        
        /**
         * Token mint used as the quote currency for a transitive swap, i.e., the
         * connecting currency.
         */
        let quoteMint: PublicKey?
        
        /**
         * Amount of `fromMint` to swap in exchange for `toMint`.
         */
        let amount: Lamports
        
        /**
         * The minimum rate used to calculate the number of tokens one
         * should receive for the swap. This is a safety mechanism to prevent one
         * from performing an unexpecteed trade.
         */
        let minExchangeRate: ExchangeRate
        
        /**
         * Token account to receive the Serum referral fee. The mint must be in the
         * quote currency of the trade (USDC or USDT).
         */
        let referral: PublicKey?
        
        /**
         * Wallet for `fromMint`. If not provided, uses an associated token address
         * for the configured provider.
         */
        let fromWallet: PublicKey?
        
        /**
         * Wallet for `toMint`. If not provided, an associated token account will
         * be created for the configured provider.
         */
        let toWallet: PublicKey?
        
        /**
         * Wallet of the quote currency to use in a transitive swap. Should be either
         * a USDC or USDT wallet. If not provided an associated token account will
         * be created for the configured provider.
         */
        let quoteWallet: PublicKey?
        
        /**
         * Market client for the first leg of the swap. Can be given to prevent
         * the client from making unnecessary network requests.
         */
        let fromMarket: Market
        
        /**
         * Market client for the second leg of the swap. Can be given to prevent
         * the client from making unnecessary network requests.
         */
        let toMarket: Market?
        
        /**
         * Open orders account for the first leg of the swap. If not given, an
         * open orders account will be created.
         */
        let fromOpenOrders: PublicKey?
        
        /**
         * Open orders account for the second leg of the swap. If not given, an
         * open orders account will be created.
         */
        let toOpenOrders: PublicKey?
        
        /**
         * RPC options. If not given the options on the program's provider are used.
         */
        let options: SolanaSDK.RequestConfiguration? = nil
        
        /**
         * True if all new open orders accounts should be automatically closed.
         * Currently disabled.
         */
        let close: Bool?
        
        /**
         * The payer that pays the creation transaction.
         * nil if the current user is the payer
         */
        let feePayer: PublicKey? = nil
        
        /**
         * Additional transactions to bundle into the swap transaction
         */
        let additionalTransactions: [SignersAndInstructions]? = nil
    }
    
    public struct ExchangeRate {
        let rate: Lamports
        let fromDecimals: Decimals
        let quoteDecimals: Decimals
        let strict: Bool
    }
    
    public struct DidSwap: BufferLayout {
        public let givenAmount: UInt64
        public let minExpectedSwapAmount: UInt64
        public let fromAmount: UInt64
        public let toAmount: UInt64
        public let spillAmount: UInt64
        public let fromMint: PublicKey
        public let toMint: PublicKey
        public let quoteMint: PublicKey
        public let authority: PublicKey
    }
    
    // Side rust enum used for the program's RPC API.
    public enum Side {
        case bid, ask
        var params: [String: [String: String]] {
            switch self {
            case .bid:
                return ["bid": [:]]
            case .ask:
                return ["ask": [:]]
            }
        }
        var byte: UInt8 {
            switch self {
            case .bid:
                return 0
            case .ask:
                return 1
            }
        }
    }
}

// MARK: - BufferLayout properties
extension SerumSwap {
    public struct Blob5: BufferLayoutProperty {
        public static var numberOfBytes: Int {5}
        
        public static func fromBytes(bytes: [UInt8]) throws -> Blob5 {
            Blob5()
        }
    }
    
    public struct AccountFlags: BufferLayout, BufferLayoutProperty {
        private(set) var initialized: Bool
        private(set) var market: Bool
        private(set) var openOrders: Bool
        private(set) var requestQueue: Bool
        private(set) var eventQueue: Bool
        private(set) var bids: Bool
        private(set) var asks: Bool
        
        public static var numberOfBytes: Int { 8 }
        
        public static func fromBytes(bytes: [UInt8]) throws -> AccountFlags {
            try .init(buffer: Data(bytes))
        }
    }
    
    public struct Seq128Elements<T: FixedWidthInteger>: BufferLayoutProperty {
        var elements: [T]
        
        public static var numberOfBytes: Int {
            128 * MemoryLayout<T>.size
        }
        
        public static func fromBytes(bytes: [UInt8]) throws -> Seq128Elements<T> {
            guard bytes.count > Self.numberOfBytes else {
                throw BufferLayoutSwift.Error.bytesLengthIsNotValid
            }
            var elements = [T]()
            let chunkedArray = bytes.chunked(into: MemoryLayout<T>.size)
            for element in chunkedArray {
                let data = Data(element)
                let num = T(littleEndian: data.withUnsafeBytes { $0.load(as: T.self) })
                elements.append(num)
            }
            return .init(elements: elements)
        }
    }
    
    public struct Blob1024: BufferLayoutProperty {
        public static var numberOfBytes: Int {1024}
        
        public static func fromBytes(bytes: [UInt8]) throws -> Blob1024 {
            Blob1024()
        }
    }
    
    public struct Blob7: BufferLayoutProperty {
        public static var numberOfBytes: Int {7}
        
        public static func fromBytes(bytes: [UInt8]) throws -> Blob7 {
            Blob7()
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
