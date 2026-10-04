import SwiftData

@MainActor enum LocalPersistence {
    static let schema = Schema([ProtocolRecord.self, CompoundRecord.self, ScheduleRevision.self, VialRecord.self, DoseLog.self, InventoryAdjustment.self, ProtocolEvent.self, PreferencesRecord.self])
    static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)])
    }
}
