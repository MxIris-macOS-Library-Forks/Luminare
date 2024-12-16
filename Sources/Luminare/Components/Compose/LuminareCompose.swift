//
//  LuminareCompose.swift
//  Luminare
//
//  Created by KrLite on 2024/10/25.
//

import SwiftUI

/// The control size for views based on ``LuminareCompose``.
///
/// Typically, this is eligible for views that have additional controls beside static contents.
public enum LuminareComposeControlSize: String, Equatable, Hashable, Identifiable, CaseIterable, Codable {
    /// The regular size where the content is separated into two lines.
    case regular
    /// The compact size where the content is in one single line.
    case compact

    public var id: String { rawValue }

    var height: CGFloat {
        switch self {
        case .regular: 70
        case .compact: 34
        }
    }
}

public enum LuminareComposeStyle: String, Equatable, Hashable, Identifiable, CaseIterable, Codable {
    case automatic
    case regular
    case inline

    public var id: String { rawValue }
}

// MARK: - Compose

/// A stylized view that composes a content with a label.
public struct LuminareCompose<Label, Content>: View
    where Label: View, Content: View {
    // MARK: Environments

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.luminareMinHeight) private var minHeight
    @Environment(\.luminareHorizontalPadding) private var horizontalPadding
    @Environment(\.luminareComposeStyle) private var style

    // MARK: Fields

    private let contentMaxWidth: CGFloat?
    private let spacing: CGFloat?

    @ViewBuilder private var content: () -> Content, label: () -> Label

    @State private var size: CGSize = .zero

    // MARK: Initializers

    /// Initializes a ``LuminareCompose``.
    ///
    /// - Parameters:
    ///   - contentMaxWidth: the maximum width of the content area.
    ///   - spacing: the spacing between the label and the content.
    ///   - content: the content.
    ///   - label: the label.
    public init(
        contentMaxWidth: CGFloat? = 270,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.contentMaxWidth = contentMaxWidth
        self.spacing = spacing
        self.label = label
        self.content = content
    }

    /// Initializes a ``LuminareCompose`` where the label is a localized text.
    ///
    /// - Parameters:
    ///   - key: the `LocalizedStringKey` to look up the label text.
    ///   - contentMaxWidth: the maximum width of the content area.
    ///   - spacing: the spacing between the label and the content.
    ///   - content: the content.
    public init(
        _ key: LocalizedStringKey,
        contentMaxWidth: CGFloat? = 270,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Label == Text {
        self.init(
            contentMaxWidth: contentMaxWidth,
            spacing: spacing
        ) {
            content()
        } label: {
            Text(key)
        }
    }

    // MARK: Body

    public var body: some View {
        HStack(spacing: spacing) {
            HStack(spacing: 0) {
                label()
                    .opacity(isEnabled ? 1 : 0.5)
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)

            Spacer()

            if let contentMaxWidth {
                HStack(spacing: 0) {
                    Spacer()

                    content()
                }
                .frame(maxWidth: contentMaxWidth)
            } else {
                content()
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            size = newValue
        }
        .padding(insets)
    }

    private var computedStyle: LuminareComposeStyle {
        switch style {
        case .automatic:
            // Automatically use `.inline` if content is small enough, like a single `Button` or `Toggle`
            if size.height <= minHeight {
                .inline
            } else {
                .regular
            }
        default:
            style
        }
    }

    private var insets: EdgeInsets {
        switch computedStyle {
        case .regular: .init(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding)
        case .inline: .init(top: 2, leading: horizontalPadding, bottom: 2, trailing: 2)
        default: .init(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding)
        }
    }
}

// MARK: - Preview

@available(macOS 15.0, *)
#Preview(
    "LuminareCompose",
    traits: .sizeThatFitsLayout
) {
    LuminareSection {
        LuminareCompose("Label") {
            Button {} label: {
                Text("Button")
            }
            .buttonStyle(.luminareCompact)
        }

        LuminareCompose("Label") {
            Button {} label: {
                Text("Button")
            }
            .buttonStyle(.luminareCompact)
        }
        .disabled(true)
    }
}

@available(macOS 15.0, *)
#Preview(
    "LuminareCompose (Constrained)",
    traits: .sizeThatFitsLayout
) {
    LuminareSection {
        LuminareCompose("Label") {
            Color.red
                .frame(height: 30)
        }

        LuminareCompose("Culpa nisi sint reprehenderit sit.") {
            Color.red
                .frame(height: 30)
        }

        LuminareCompose("Culpa nisi sint reprehenderit sit.") {
            Text("A very wide content")
                .frame(width: 250, height: 30)
                .background(.red)
        }
    }
    .frame(width: 400)
}
