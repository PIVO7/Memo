import Foundation
import Observation
import OSLog
import StoreKit

/// Weet of het gezin de volledige versie heeft. Eén niet-verbruikbare,
/// gezinsdeelbare aankoop ontgrendelt alles; de laatste bekende stand staat
/// in UserDefaults zodat de app ook offline meteen goed opstart.
@MainActor
@Observable
final class EntitlementStore {
    static let familyProductID = "com.pivo7.memo.gezin"
    private static let cacheKey = "gezin-ontgrendeld"

    /// Hoe een aankooppoging afliep, zodat de paywall het verschil kent
    /// tussen "laat maar" en "er ging iets mis".
    enum PurchaseOutcome {
        case success
        case cancelled
        case pending
        case failed
    }

    private(set) var isFamilyUnlocked: Bool
    private(set) var familyProduct: Product?

    private var updatesTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.pivo7.memo", category: "aankoop")

    init() {
        isFamilyUnlocked = UserDefaults.standard.bool(forKey: Self.cacheKey)
        updatesTask = Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.refreshEntitlements()
            }
        }
        Task { await load() }
    }

    /// Voor previews en tests, zonder StoreKit.
    init(previewUnlocked: Bool) {
        isFamilyUnlocked = previewUnlocked
    }

    func load() async {
        do {
            familyProduct = try await Product.products(for: [Self.familyProductID]).first
        } catch {
            logger.error("Product laden mislukt: \(error.localizedDescription, privacy: .public)")
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.familyProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isFamilyUnlocked = unlocked
        UserDefaults.standard.set(unlocked, forKey: Self.cacheKey)
    }

    func purchaseFamily() async -> PurchaseOutcome {
        if familyProduct == nil {
            await load()
        }
        guard let product = familyProduct else { return .failed }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                await refreshEntitlements()
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                // Vraag-om-te-kopen: een ouder moet nog goedkeuren.
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            logger.error("Aankoop mislukt: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
    }

    /// Meldt of het synchroniseren zelf gelukt is, zodat de paywall een
    /// mislukking kan benoemen in plaats van stil te blijven.
    @discardableResult
    func restorePurchases() async -> Bool {
        var synced = true
        do {
            try await AppStore.sync()
        } catch {
            logger.error("Herstellen mislukt: \(error.localizedDescription, privacy: .public)")
            synced = false
        }
        await refreshEntitlements()
        return synced
    }
}
