import UIKit

/// Imperative haptic cues for gesture and action completions that happen inside
/// event closures, where no observable state change exists to drive the
/// declarative `.sensoryFeedback` modifier. Prefer `.sensoryFeedback` wherever a
/// state value already changes; call these only at completion points.
///
/// Every cue is a single subtle pulse — the interface stays quiet and tactile.
@MainActor
enum Haptics {
    /// An insertion point or option became active: drag hover target moved,
    /// accessibility reorder, list choice committed.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A light physical completion: a drag landed, an undo was applied.
    static func impact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Data was committed: protocol, vial, dose correction, export, purchase.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
