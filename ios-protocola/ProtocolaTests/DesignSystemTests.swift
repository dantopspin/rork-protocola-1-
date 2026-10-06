import Foundation
import Testing
import XCTest

/// Prevent product screens from drifting away from DESIGN_SYSTEM.md.
///
/// This is intentionally a source-level guardrail: SwiftUI makes it easy to
/// introduce one-off fonts, radii, colors, and native button styles that compile
/// successfully but break the visual system.
struct DesignSystemTests {

    @Test
    func productViewsUseSharedDesignTokens() throws {
        let productDirectory =
            try Self.locateProductDirectory()

        let viewsDirectory =
            productDirectory
                .appendingPathComponent(
                    "Protocola/Views",
                    isDirectory: true
                )

        var files =
            try FileManager.default
                .contentsOfDirectory(
                    at: viewsDirectory,
                    includingPropertiesForKeys: nil
                )
                .filter {
                    $0.pathExtension == "swift"
                }

        files.append(
            productDirectory
                .appendingPathComponent(
                    "Protocola/ContentView.swift"
                )
        )

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
                "hard-coded nonzero spacing",
                #"spacing:\s*(?!0(?:\.0+)?\b)[0-9]"#
            ),
            (
                "hard-coded line width",
                #"lineWidth:\s*[0-9]"#
            ),
            (
                "hard-coded opacity",
                #"\.opacity\(\s*(?:0(?:\.\d+)?|1(?:\.0+)?)\s*\)"#
            ),
            (
                "hard-coded animation timing",
                #"(duration|response|dampingFraction):\s*[0-9]"#
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
                "hand-drawn horizontal rule (use EditorialRule)",
                #"\.fill\(\s*Theme\.hairline\s*\)\s*\.frame\(\s*height:"#
            ),
            (
                "rounded grouped list (product lists are plain)",
                #"\.listStyle\(\s*\.insetGrouped\s*\)"#
            ),
            (
                "sentence-case form header (use Eyebrow)",
                #"header:\s*\{\s*Text\("#
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
                    "\(file.lastPathComponent) violates the design system: \(rule.label)"
                )
            }

            if file.lastPathComponent
                != "TrackingCard.swift" {
                #expect(
                    !source.contains(
                        ".shadow("
                    ),
                    "\(file.lastPathComponent) adds a local shadow. Elevation belongs in the shared surface component."
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
                    "\(file.lastPathComponent) adds product material/glass. Material is reserved for native chrome or the transient Today undo surface."
                )
            }
        }
    }


    /// The managed build service can compile with relative source paths, so
    /// `#filePath` is not always absolute at the test process's working
    /// directory. Resolve the product sources from several anchors; when they
    /// are genuinely unreachable the guardrail skips explicitly rather than
    /// silently passing.
    private static func locateProductDirectory() throws -> URL {
        let fileManager =
            FileManager.default

        var candidates: [URL] = []

        candidates.append(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        )

        let environment =
            ProcessInfo.processInfo.environment

        for key in ["SRCROOT", "PROJECT_DIR"] {
            if let root = environment[key] {
                candidates.append(
                    URL(
                        fileURLWithPath: root,
                        isDirectory: true
                    )
                )
            }
        }

        var walk = URL(
            fileURLWithPath:
                fileManager.currentDirectoryPath,
            isDirectory: true
        )

        for _ in 0..<10 {
            candidates.append(walk)
            candidates.append(
                walk.appendingPathComponent(
                    "ios-protocola",
                    isDirectory: true
                )
            )

            let parent =
                walk.deletingLastPathComponent()

            if parent.path == walk.path {
                break
            }

            walk = parent
        }

        for candidate in candidates
        where fileManager.fileExists(
            atPath: candidate
                .appendingPathComponent(
                    "Protocola/Views"
                )
                .path
        ) {
            return candidate
        }

        throw XCTSkip(
            "Product sources are not reachable from the test process; the design-system guardrail needs them on disk."
        )
    }
}
