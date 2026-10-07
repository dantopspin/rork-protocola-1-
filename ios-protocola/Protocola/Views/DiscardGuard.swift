import SwiftUI

/// Keeps a half-filled editor from being lost: swipe-to-dismiss is blocked
/// while there are unsaved changes, and Cancel asks before discarding.
struct DiscardGuard: ViewModifier {
    let hasChanges: Bool
    @Binding var confirming: Bool
    let discard: () -> Void

    func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog(
                "Discard changes?",
                isPresented: $confirming,
                titleVisibility: .visible
            ) {
                Button(
                    "Discard changes",
                    role: .destructive,
                    action: discard
                )

                Button(
                    "Keep editing",
                    role: .cancel
                ) {}
            } message: {
                Text("What you entered hasn't been saved.")
            }
    }
}

extension View {
    func discardGuard(
        hasChanges: Bool,
        confirming: Binding<Bool>,
        discard: @escaping () -> Void
    ) -> some View {
        modifier(
            DiscardGuard(
                hasChanges: hasChanges,
                confirming: confirming,
                discard: discard
            )
        )
    }
}
