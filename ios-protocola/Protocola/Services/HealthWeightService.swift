import Foundation
import HealthKit

/// Read-only access to body weight in Apple Health. Protocola never writes
/// to Health and never stores these samples; they are read when shown.
@MainActor
final class HealthWeightService {
    struct Sample: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    static let shared = HealthWeightService()

    private let store = HKHealthStore()
    private let weightType = HKQuantityType(.bodyMass)

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Asks once, in context. Health never reveals whether read access was
    /// denied, so callers treat "no samples" as the empty state.
    func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(
                toShare: [],
                read: [weightType]
            )
            return true
        } catch {
            return false
        }
    }

    /// The unit the person prefers in the Health app (kg or lb).
    func preferredUnit() async -> HKUnit {
        let units =
            try? await store.preferredUnits(for: [weightType])
        return units?[weightType] ?? .gramUnit(with: .kilo)
    }

    func samples(
        from start: Date,
        to end: Date,
        unit: HKUnit
    ) async -> [Sample] {
        let predicate =
            HKQuery.predicateForSamples(
                withStart: start,
                end: end
            )
        let descriptor =
            HKSampleQueryDescriptor(
                predicates: [
                    .quantitySample(
                        type: weightType,
                        predicate: predicate
                    )
                ],
                sortDescriptors: [
                    SortDescriptor(\.startDate)
                ]
            )
        let results =
            (try? await descriptor.result(for: store)) ?? []
        return results.map {
            Sample(
                date: $0.startDate,
                value: $0.quantity.doubleValue(for: unit)
            )
        }
    }
}
