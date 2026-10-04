import Foundation

@MainActor enum ExportService {
    static func historyCSV(_ logs: [DoseLog]) throws -> URL {
        let header = ["id", "recorded_at", "protocol", "compound", "scheduled_amount", "scheduled_unit", "actual_amount", "unit", "vial", "concentration_mg_ml", "status", "site", "symptoms", "severity", "notes"]
        let rows = logs.map { log in [log.id.uuidString, log.loggedAt.ISO8601Format(), log.protocolName, log.compoundName, log.scheduledAmountText, log.scheduledUnitText, log.actualAmountText, log.unitText, log.vialName, log.concentrationText ?? "", log.status, log.site, log.symptoms, String(log.symptomSeverity), log.notes] }
        let csv = ([header] + rows).map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Protocola-history-\(UUID().uuidString).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    private static func escape(_ value: String) -> String {
        let safe = ["=", "+", "-", "@", "\t", "\r"].contains(String(value.prefix(1))) ? "'" + value : value
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
