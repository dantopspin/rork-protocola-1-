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
    var placement: ToolbarItemPlacement = .topBarLeading

    var body: some ToolbarContent {
        ToolbarItem(
            placement: placement
        ) {
            SettingsButton()
        }
        .plainToolbarBackground()
    }
}


extension ToolbarContent {
    /// iOS 26: a plain icon without the shared glass circle, like the
    /// reference design. Earlier systems already draw plain bar buttons.
    @ToolbarContentBuilder
    func plainToolbarBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
