import SwiftUI

enum FolderTrailDesign {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    enum Typography {
        static let title = Font.title2.weight(.semibold)
        static let section = Font.headline
        static let body = Font.body
        static let meta = Font.caption
        static let badge = Font.caption2.weight(.semibold)
    }

    enum Palette {
        static let primary = Color.accentColor
        static let secondaryText = Color.secondary
        static let panelStroke = Color.secondary.opacity(0.18)
        static let success = Color.green
        static let warning = Color.orange
    }
}

struct FolderTrailPanel<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FolderTrailDesign.Spacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FolderTrailDesign.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FolderTrailDesign.Radius.md)
                    .stroke(FolderTrailDesign.Palette.panelStroke)
            )
    }
}

struct FolderTrailPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FolderTrailDesign.Typography.meta.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, FolderTrailDesign.Spacing.md)
            .padding(.vertical, FolderTrailDesign.Spacing.sm)
            .background(
                FolderTrailDesign.Palette.primary.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: FolderTrailDesign.Radius.sm)
            )
    }
}

struct FolderTrailChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FolderTrailDesign.Typography.meta)
            .padding(.horizontal, FolderTrailDesign.Spacing.sm)
            .padding(.vertical, FolderTrailDesign.Spacing.xs)
            .background(.thinMaterial, in: Capsule())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct FolderTrailStatusPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(FolderTrailDesign.Typography.meta)
            .padding(.horizontal, FolderTrailDesign.Spacing.sm)
            .padding(.vertical, FolderTrailDesign.Spacing.xs)
            .background(.thinMaterial, in: Capsule())
    }
}
