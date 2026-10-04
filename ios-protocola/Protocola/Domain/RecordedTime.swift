import Foundation

struct RecordedTime: Identifiable {
    let id: UUID
    var date: Date
    init(date: Date = .now) { id = UUID(); self.date = date }
}
