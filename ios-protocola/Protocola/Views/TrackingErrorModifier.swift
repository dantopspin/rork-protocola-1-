import SwiftUI
import UIKit

struct TrackingErrorModifier: ViewModifier {
    @Environment(TrackingStore.self) private var store

    func body(
        content: Content
    ) -> some View {
        content.alert(
            "Unable to complete action",
            isPresented: Binding(
                get: {
                    store.error != nil
                },
                set: {
                    if !$0 {
                        store.error = nil
                    }
                }
            )
        ) {
            Button("OK") {
                store.error = nil
            }
        } message: {
            Text(store.error ?? "")
        }
    }
}


extension View {

    func trackingErrors() -> some View {
        modifier(
            TrackingErrorModifier()
        )
    }


    /// Fixed app-wide list/form treatment.
    func paperList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper)
            .font(Theme.body)
            .textCase(nil)
            .listSectionSpacing(
                Theme.spaceL
            )
    }


    /// Fixed app-wide scroll-screen rhythm.
    func screenPadding() -> some View {
        padding(
            .horizontal,
            Theme.spaceL
        )
        .padding(
            .vertical,
            Theme.spaceM
        )
        .frame(
            maxWidth: Theme.maxContent
        )
        .font(Theme.body)
    }


    /// Standard app text treatment for custom non-List surfaces.
    func protocolaTypography() -> some View {
        font(Theme.body)
            .foregroundStyle(Theme.ink)
    }


    /// Decimal-pad dismissal affordance.
    func doneKeyboard() -> some View {
        scrollDismissesKeyboard(
            .interactively
        )
        .toolbar {
            ToolbarItemGroup(
                placement: .keyboard
            ) {
                Spacer()

                Button("Done") {
                    UIApplication.shared
                        .sendAction(
                            #selector(
                                UIResponder
                                    .resignFirstResponder
                            ),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                }
            }
        }
    }
}
