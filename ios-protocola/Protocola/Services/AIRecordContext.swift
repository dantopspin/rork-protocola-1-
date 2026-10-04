import Foundation

nonisolated struct AIRecordContext: Sendable {
    let lines: [String]
    var text: String { lines.joined(separator: "\n") }
}
