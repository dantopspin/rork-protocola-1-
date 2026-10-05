import Foundation
import SwiftData

@Model final class LabRecord {
    @Attribute(.unique) var id: UUID
    var protocolID: UUID?
    var marker: String
    var valueText: String
    var unit: String
    var referenceLowText: String?
    var referenceHighText: String?
    var notes: String
    var collectedAt: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        protocolID: UUID?,
        marker: String,
        value: Decimal,
        unit: String,
        referenceLow: Decimal? = nil,
        referenceHigh: Decimal? = nil,
        notes: String = "",
        collectedAt: Date,
        now: Date = .now
    ) {
        id = UUID()
        self.protocolID = protocolID
        self.marker = marker
        valueText = Self.text(value)
        self.unit = unit
        referenceLowText =
            referenceLow.map(Self.text)
        referenceHighText =
            referenceHigh.map(Self.text)
        self.notes = notes
        self.collectedAt = collectedAt
        createdAt = now
        updatedAt = now
    }

    var value: Decimal? {
        Decimal(string: valueText)
    }

    var referenceLow: Decimal? {
        referenceLowText.flatMap {
            Decimal(string: $0)
        }
    }

    var referenceHigh: Decimal? {
        referenceHighText.flatMap {
            Decimal(string: $0)
        }
    }

    var displayValue: String {
        unit.isEmpty
            ? valueText
            : valueText + " " + unit
    }

    var referenceRangeText: String? {
        switch (
            referenceLowText,
            referenceHighText
        ) {
        case let (low?, high?):
            return low + " – " + high
                + (unit.isEmpty ? "" : " " + unit)

        case let (low?, nil):
            return "≥ " + low
                + (unit.isEmpty ? "" : " " + unit)

        case let (nil, high?):
            return "≤ " + high
                + (unit.isEmpty ? "" : " " + unit)

        default:
            return nil
        }
    }

    private static func text(
        _ number: Decimal
    ) -> String {
        NSDecimalNumber(
            decimal: number
        ).stringValue
    }
}
