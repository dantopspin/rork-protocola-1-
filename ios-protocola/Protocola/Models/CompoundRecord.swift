import Foundation
import SwiftData

@Model
final class CompoundRecord {
    @Attribute(.unique)
    var id: UUID
    var protocolID: UUID
    var name: String

    /// Optional user-recorded reference used only by the estimated-level model.
    /// Existing stores migrate without requiring a value.
    var referenceHalfLifeHoursText:
        String?
    var referenceHalfLifeSource:
        String?

    init(
        protocolID: UUID,
        name: String
    ) {
        id = UUID()
        self.protocolID = protocolID
        self.name = name
        referenceHalfLifeHoursText = nil
        referenceHalfLifeSource = nil
    }

    var referenceHalfLifeHours:
        Decimal? {
        referenceHalfLifeHoursText
            .flatMap {
                Decimal(string: $0)
            }
    }
}
