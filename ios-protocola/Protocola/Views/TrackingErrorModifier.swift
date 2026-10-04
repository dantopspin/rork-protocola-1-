import SwiftUI
import UIKit

struct TrackingErrorModifier: ViewModifier {
    @Environment(TrackingStore.self) private var store
    func body(content: Content) -> some View {
        content.alert("Unable to complete action", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
    }
}

extension View {
    func trackingErrors() -> some View { modifier(TrackingErrorModifier()) }
    func paperList() -> some View { scrollContentBackground(.hidden).background(Theme.paper) }
    /// The one screen-container rhythm for every scroll screen: 20pt horizontal,
    /// 16pt vertical, and a shared max content width — spacing never drifts per screen.
    func screenPadding() -> some View {
        padding(.horizontal, Theme.spaceL)
            .padding(.vertical, Theme.spaceM)
            .frame(maxWidth: Theme.maxContent)
    }
    /// Dismissal affordance for decimal-pad forms, which have no return key on iPhone:
    /// a keyboard "Done" button plus interactive swipe-to-dismiss.
    func doneKeyboard() -> some View {
        scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
    }
}
