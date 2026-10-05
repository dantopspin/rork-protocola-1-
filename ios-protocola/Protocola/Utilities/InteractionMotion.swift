import SwiftUI

/// Restrained entrance motion for small groups of content.
///
/// Only the first few items stagger. Later lazy-list content appears normally,
/// so scrolling never feels animated for its own sake.
private struct TrackingStaggerModifier: ViewModifier {
    let index: Int

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var visible = false

    func body(
        content: Content
    ) -> some View {
        let shouldAnimate =
            !reduceMotion
            && index
                <= Theme.motionStaggerMaxIndex

        content
            .opacity(
                visible || !shouldAnimate
                ? 1
                : Theme.motionEntranceOpacity
            )
            .offset(
                y:
                    visible || !shouldAnimate
                    ? 0
                    : Theme.motionEntranceOffset
            )
            .onAppear {
                guard !visible else {
                    return
                }

                if shouldAnimate {
                    withAnimation(
                        .easeOut(
                            duration:
                                Theme.motionStateDuration
                        )
                        .delay(
                            Theme.motionStaggerDelay
                            * Double(index)
                        )
                    ) {
                        visible = true
                    }

                } else {
                    visible = true
                }
            }
    }
}


extension View {

    /// Use only for compact groups where sequence helps the eye establish
    /// hierarchy, such as protocol rows or the first days in History.
    func trackingStagger(
        index: Int
    ) -> some View {
        modifier(
            TrackingStaggerModifier(
                index: index
            )
        )
    }


    /// Standard state-change animation for product data. Reduce Motion turns
    /// it into an immediate state update.
    func trackingStateAnimation<
        Value: Equatable
    >(
        value: Value
    ) -> some View {
        modifier(
            TrackingStateAnimationModifier(
                value: value
            )
        )
    }
}


private struct TrackingStateAnimationModifier<
    Value: Equatable
>: ViewModifier {
    let value: Value

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(
        content: Content
    ) -> some View {
        content.animation(
            reduceMotion
                ? nil
                : .easeOut(
                    duration:
                        Theme.motionStateDuration
                ),
            value: value
        )
    }
}
