import SwiftUI

/// The same Settings entry point on every tab, so it is never hidden in a menu.
struct SettingsButton: View {
    @State private var open = false

    var body: some View {
        Button(
            "Settings",
            systemImage: "gearshape"
        ) {
            open = true
        }
        .sheet(isPresented: $open) {
            SettingsView()
        }
    }
}


struct SettingsToolbarItem: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(
            placement: .topBarLeading
        ) {
            SettingsButton()
        }
    }
}
