//
//  SubscriptionManager.swift
//  Cloudship
//
//  StoreKit 2 subscription manager for Cloudship Premium.
//  Handles product loading, purchasing, entitlement checking,
//  and transaction listening.
//

import StoreKit
import Foundation

final class SubscriptionManager {

    static let shared = SubscriptionManager()
    private init() {}

    // MARK: - Product IDs

    static let monthlyID = "com.cloudship.premium.monthly"
    static let annualID  = "com.cloudship.premium.annual"
    private static let productIDs: Set<String> = [monthlyID, annualID]

    // MARK: - Notification

    static let premiumStatusChanged = Notification.Name("PremiumStatusChanged")

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private var transactionListener: Task<Void, Error>?

    /// Fast synchronous check backed by UserDefaults. Updated on every entitlement refresh.
    /// Nonisolated so it can be read from any context without awaiting.
    nonisolated var isPremiumCached: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "DemoModeEnabled") { return true }
        #endif
        return UserDefaults.standard.bool(forKey: "isPremiumCached")
    }

    /// Computed from live entitlement state.
    var isPremium: Bool {
        #if DEBUG
        if demoModeEnabled { return true }
        #endif
        return !purchasedProductIDs.isEmpty
    }

    // MARK: - Demo Mode (DEBUG only)

    #if DEBUG
    /// Whether demo mode is active — unlocks all premium features without a subscription.
    /// Only available in debug builds. Toggled via 5-tap on version label in Settings.
    nonisolated var demoModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "DemoModeEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "DemoModeEnabled")
            NotificationCenter.default.post(name: Self.premiumStatusChanged, object: nil)
        }
    }
    #endif

    // MARK: - Setup

    /// Call once on app launch to start listening for transaction updates.
    func start() {
        transactionListener = listenForTransactions()
        Task { await checkEntitlement() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("SubscriptionManager: Failed to load products — \(error)")
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Entitlement

    func checkEntitlement() async {
        await updatePurchasedProducts()
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        let wasPremium = isPremiumCached
        purchasedProductIDs = purchased

        let nowPremium = !purchased.isEmpty
        UserDefaults.standard.set(nowPremium, forKey: "isPremiumCached")

        if wasPremium != nowPremium {
            NotificationCenter.default.post(name: Self.premiumStatusChanged, object: nil)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
