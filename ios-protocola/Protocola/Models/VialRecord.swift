import Foundation
import SwiftData

enum VialLifecycleState:
    String,
    Codable,
    CaseIterable,
    Identifiable {
    case active = "Active"
    case reserve = "Reserve"
    case sealed = "Sealed"
    case archived = "Archived"

    var id: String { rawValue }
}

/// Cap colour of the drawn vial: a visual label the user picks so vials
/// are easy to tell apart. It carries no meaning about the contents.
enum VialCapColor:
    String,
    Codable,
    CaseIterable,
    Identifiable {
    case silver = "Silver"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case amber = "Amber"
    case red = "Red"

    var id: String { rawValue }

    /// Stable default per compound name so new vials differ without setup.
    static func automatic(for compound: String) -> VialCapColor {
        let sum =
            compound.lowercased()
                .unicodeScalars
                .reduce(0) { $0 + Int($1.value) }
        return allCases[sum % allCases.count]
    }
}

@Model final class VialRecord {
    @Attribute(.unique) var id: UUID
    var compoundName: String
    var name: String
    var originalMgText: String
    var diluentMlText: String
    var batch: String
    var supplier: String
    var storageNotes: String
    var expiry: Date?
    var reconstitutedAt: Date?
    var openedAt: Date?
    var stateRawValue: String?
    @Attribute(.externalStorage)
    var photoData: Data?
    /// Optional; nil means the automatic colour for the compound.
    var capColorRawValue: String? = nil
    var isArchived: Bool
    var createdAt: Date

    init(
        name: String,
        compoundName: String,
        originalMg: Decimal,
        diluentMl: Decimal,
        batch: String = "",
        supplier: String = "",
        storageNotes: String = "",
        expiry: Date? = nil
    ) {
        id = UUID()
        self.name = name
        self.compoundName = compoundName
        originalMgText =
            DoseCalculator.text(originalMg)
        diluentMlText =
            DoseCalculator.text(diluentMl)
        self.batch = batch
        self.supplier = supplier
        self.storageNotes = storageNotes
        self.expiry = expiry
        reconstitutedAt = nil
        openedAt = nil
        stateRawValue =
            VialLifecycleState
                .active.rawValue
        photoData = nil
        isArchived = false
        createdAt = .now
    }

    var capColor: VialCapColor {
        capColorRawValue
            .flatMap(VialCapColor.init(rawValue:))
        ?? .automatic(for: compoundName)
    }

    var originalMg: Decimal {
        Decimal(
            string: originalMgText
        ) ?? 0
    }

    var diluentMl: Decimal {
        Decimal(
            string: diluentMlText
        ) ?? 0
    }

    var concentration: Decimal? {
        try? DoseCalculator
            .concentration(
                vialAmount: originalMg,
                unit: .mg,
                diluentMl: diluentMl
            )
    }

    var lifecycleState:
        VialLifecycleState {
        get {
            if isArchived {
                return .archived
            }

            return VialLifecycleState(
                rawValue:
                    stateRawValue ?? ""
            ) ?? .active
        }
        set {
            stateRawValue =
                newValue.rawValue
            isArchived =
                newValue == .archived
        }
    }
}
