import CoreGraphics

struct EverywowLogoLayout: Equatable, Sendable {
    static let artworkAspectRatio: CGFloat = 239.4587 / 51.3128
    static let artworkWidthFraction: CGFloat = 0.08
    static let minimumHitTargetSize: CGFloat = 44

    let availableSize: CGSize
    let artworkFrame: CGRect
    let hitTargetFrame: CGRect

    init(availableSize: CGSize, edgeInset: CGFloat) {
        self.availableSize = availableSize

        let artworkWidth = availableSize.width * Self.artworkWidthFraction
        let artworkHeight = artworkWidth / Self.artworkAspectRatio
        artworkFrame = CGRect(
            x: edgeInset,
            y: availableSize.height - edgeInset - artworkHeight,
            width: artworkWidth,
            height: artworkHeight
        )

        let hitSize = CGSize(
            width: min(
                max(Self.minimumHitTargetSize, artworkWidth),
                availableSize.width
            ),
            height: min(
                max(Self.minimumHitTargetSize, artworkHeight),
                availableSize.height
            )
        )
        let centerX = min(
            max(artworkFrame.midX, hitSize.width / 2),
            availableSize.width - (hitSize.width / 2)
        )
        let centerY = min(
            max(artworkFrame.midY, hitSize.height / 2),
            availableSize.height - (hitSize.height / 2)
        )
        hitTargetFrame = CGRect(
            x: centerX - (hitSize.width / 2),
            y: centerY - (hitSize.height / 2),
            width: hitSize.width,
            height: hitSize.height
        )
    }
}
