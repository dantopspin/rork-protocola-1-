import SwiftUI
import UIKit

extension VialCapColor {
    /// Theme colour for the drawn cap and the tint of the liquid.
    var tint: Color {
        switch self {
        case .silver: return Theme.textTertiary
        case .green: return Theme.teal
        case .blue: return Theme.info
        case .purple: return Theme.violet
        case .amber: return Theme.amber
        case .red: return Theme.danger
        }
    }
}


/// A drawn vial: coloured cap, crimp, glass body and a liquid level
/// that shows the recorded fraction remaining.
struct VialGlyph: View {
    let cap: VialCapColor
    /// 0...1 of the original amount still recorded in the vial.
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let capHeight = height * 0.24
            let crimpHeight = height * 0.08
            let bodyHeight = height - capHeight - crimpHeight
            let bodyRadius = width * 0.22
            let level = max(0, min(1, fraction))

            VStack(spacing: 0) {
                RoundedRectangle(
                    cornerRadius: width * 0.14,
                    style: .continuous
                )
                .fill(cap.tint)
                .frame(
                    width: width * 0.82,
                    height: capHeight
                )

                Rectangle()
                    .fill(Theme.inactiveFill)
                    .frame(
                        width: width * 0.62,
                        height: crimpHeight
                    )

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.surface)

                    Rectangle()
                        .fill(
                            cap.tint.opacity(Theme.liquidOpacity)
                        )
                        .frame(height: bodyHeight * 0.86 * level)

                    // Glass highlight along the left edge.
                    Capsule()
                        .fill(Theme.surface)
                        .frame(
                            width: width * 0.1,
                            height: bodyHeight * 0.6
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .leading
                        )
                        .padding(.leading, width * 0.16)
                }
                .frame(width: width, height: bodyHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: bodyRadius,
                        style: .continuous
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: bodyRadius,
                        style: .continuous
                    )
                    .strokeBorder(
                        Theme.controlBorder,
                        lineWidth: Theme.ruleThickness
                    )
                )
            }
            .frame(width: width, height: height)
        }
        .frame(
            width: Theme.vialGlyphWidth,
            height: Theme.vialGlyphHeight
        )
        .accessibilityHidden(true)
    }
}


/// The leading tile of a vial card: the user's own reference photo when
/// one is attached, otherwise the drawn vial.
struct VialTile: View {
    let vial: VialRecord
    let fraction: Double

    private var photo: UIImage? {
        guard let data = vial.photoData else { return nil }
        let side = Theme.iconTileSize * 3
        return UIImage(data: data)?
            .preparingThumbnail(
                of: CGSize(
                    width: side,
                    height: side
                )
            )
    }

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                VialGlyph(
                    cap: vial.capColor,
                    fraction: fraction
                )
            }
        }
        .frame(
            width: Theme.iconTileSize,
            height: Theme.iconTileSize
        )
        .background(Theme.subtleFill)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.radiusRow,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }
}


/// Row of cap colour swatches for the vial editor.
struct VialCapColorPicker: View {
    @Binding var selection: VialCapColor?
    let compound: String

    private var current: VialCapColor {
        selection ?? .automatic(for: compound)
    }

    var body: some View {
        HStack(spacing: Theme.spaceS) {
            VialGlyph(cap: current, fraction: 0.7)

            HStack(spacing: 0) {
            ForEach(VialCapColor.allCases) { color in
                Button {
                    selection = color
                } label: {
                    Circle()
                        .fill(color.tint)
                        .frame(
                            width: Theme.iconColumn,
                            height: Theme.iconColumn
                        )
                        .padding(Theme.spaceXXS)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    current == color
                                    ? Theme.ink
                                    : Color.clear,
                                    lineWidth: Theme.ruleThickness * 2
                                )
                        )
                        .minimumTapTarget()
                }
                .buttonStyle(TrackingCardButtonStyle())
                .accessibilityLabel(color.rawValue + " cap")
                .accessibilityAddTraits(
                    current == color ? .isSelected : []
                )
            }
        }
            }
    }
}
