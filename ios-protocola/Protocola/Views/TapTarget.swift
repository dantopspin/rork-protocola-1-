import SwiftUI

extension View {
    /// Grows a small control's hit area to the 44×44pt minimum without
    /// changing how it looks.
    func minimumTapTarget() -> some View {
        frame(
            minWidth: Theme.minimumTapTarget,
            minHeight: Theme.minimumTapTarget
        )
        .contentShape(Rectangle())
    }
}
