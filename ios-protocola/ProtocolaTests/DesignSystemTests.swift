import Foundation
import Testing

/// Prevent product screens from drifting away from DESIGN_SYSTEM.md.
///
/// This is intentionally a source-level guardrail: SwiftUI makes it easy to
/// introduce one-off fonts, radii, colors, and native button styles that compile
/// successfully but break the visual system.
struct DesignSystemTests {

    @Test
    func productViewsUseSharedDesignTokens() throws {
        let testsDirectory =
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()

        let viewsDirectory =
            testsDirectory
                .deletingLastPathComponent()
                .appendingPathComponent(
                    "Protocola/Views",
                    isDirectory: true
                )

        let files =
            try FileManager.default
                .contentsOfDirectory(
                    at: viewsDirectory,
                    includingPropertiesForKeys: nil
                )
                .filter {
                    $0.pathExtension == "swift"
                }

        let forbiddenPatterns: [
            (
                label: String,
                pattern: String
            )
        ] = [
            (
                "native product typography",
                #"\.font\(\s*\.(largeTitle|title|title2|title3|headline|subheadline|body|caption|caption2|footnote|callout)"#
            ),
            (
                "weighted native product typography",
                #"\.(subheadline|headline|caption|caption2|footnote)\.weight\("#
            ),
            (
                "hard-coded system font size",
                #"\.font\(\s*\.system\(\s*size:\s*[0-9]"#
            ),
            (
                "hard-coded corner radius",
                #"cornerRadius:\s*[0-9]"#
            ),
            (
                "hard-coded padding",
                #"\.padding\(\s*[0-9]"#
            ),
            (
                "hard-coded frame dimension",
                #"(width|height|minHeight|maxHeight):\s*[0-9]"#
            ),
            (
                "un-tokenized secondary color",
                #"\.foregroundStyle\(\s*\.secondary\s*\)"#
            ),
            (
                "un-tokenized tertiary color",
                #"\.foregroundStyle\(\s*\.tertiary\s*\)"#
            ),
            (
                "native branded empty state",
                #"ContentUnavailableView"#
            ),
            (
                "native bordered button style",
                #"\.buttonStyle\(\s*\.bordered(Prominent)?\s*\)"#
            ),
            (
                "literal product color",
                #"Color\s*\("#
            ),
            (
                "literal white/black product color",
                #"Color\.(white|black|red|green|orange|blue|gray)"#
            )
        ]

        for file in files {
            let source =
                try String(
                    contentsOf: file,
                    encoding: .utf8
                )

            for rule in forbiddenPatterns {
                let match =
                    source.range(
                        of: rule.pattern,
                        options:
                            .regularExpression
                    )

                #expect(
                    match == nil,
                    Comment(
                        "\(file.lastPathComponent) violates the design system: \(rule.label)"
                    )
                )
            }

            if file.lastPathComponent
                != "TrackingCard.swift" {
                #expect(
                    !source.contains(
                        ".shadow("
                    ),
                    Comment(
                        "\(file.lastPathComponent) adds a local shadow. Elevation belongs in the shared surface component."
                    )
                )
            }

            if file.lastPathComponent
                != "TodayView.swift" {
                #expect(
                    !source.contains(
                        ".regularMaterial"
                    )
                    && !source.contains(
                        ".thinMaterial"
                    )
                    && !source.contains(
                        ".ultraThinMaterial"
                    ),
                    Comment(
                        "\(file.lastPathComponent) adds product material/glass. Material is reserved for native chrome or the transient Today undo surface."
                    )
                )
            }
        }
    }
}
