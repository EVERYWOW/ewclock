import SwiftUI

struct EverywowLogoView: View {
    let edgeInset: CGFloat
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let layout = EverywowLogoLayout(
                availableSize: geometry.size,
                edgeInset: edgeInset
            )

            Image("EverywowLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: layout.artworkFrame.width,
                    height: layout.artworkFrame.height
                )
                .position(
                    x: layout.artworkFrame.midX,
                    y: layout.artworkFrame.midY
                )

            Button(action: onDismiss) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .focusEffectDisabled()
            .accessibilityLabel("Hide EVERYWOW logo")
            .frame(
                width: layout.hitTargetFrame.width,
                height: layout.hitTargetFrame.height
            )
            .position(
                x: layout.hitTargetFrame.midX,
                y: layout.hitTargetFrame.midY
            )
        }
    }
}
