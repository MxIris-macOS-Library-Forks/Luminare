//
//  LuminareSidebarTab.swift
//  Luminare
//
//  Created by Kai Azim on 2024-09-29.
//

import SwiftUI

public struct LuminareSidebarTab<Tab>: View where Tab: LuminareTabItem {
    @Environment(\.luminareTint) private var tint
    @Environment(\.luminareAnimation) private var animation
    @Environment(\.luminareAnimationFast) private var animationFast

    @Binding private var activeTab: Tab
    private let tab: Tab

    @State private var isActive = false

    public init(_ tab: Tab, _ activeTab: Binding<Tab>) {
        self._activeTab = activeTab
        self.tab = tab
    }

    public var body: some View {
        Button {
            activeTab = tab
        } label: {
            HStack(spacing: 8) {
                tab.iconView()

                HStack(spacing: 0) {
                    Text(tab.title)

                    if tab.hasIndicator {
                        VStack {
                            Circle()
                                .foregroundStyle(.tint)
                                .frame(width: 4, height: 4)
                                .padding(.leading, 4)
                                .shadow(color: tint(), radius: 4)

                            Spacer()
                        }
                        .transition(.opacity.animation(animation))
                    }
                }
                .fixedSize()

                Spacer()
            }
        }
        .buttonStyle(SidebarButtonStyle(isActive: $isActive))
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
        }
        .onAppear {
            processActiveTab()
        }
        .onChange(of: activeTab) { _ in
            processActiveTab()
        }
    }

    func processActiveTab() {
        withAnimation(animationFast) {
            isActive = activeTab == tab
        }
    }
}

struct SidebarButtonStyle: ButtonStyle {
    @Environment(\.luminareAnimationFast) private var animationFast
    
    let cornerRadius: CGFloat = 12
    @State var isHovering: Bool = false
    @Binding var isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background {
                if configuration.isPressed {
                    Rectangle().foregroundStyle(.quaternary)
                } else if isHovering || isActive {
                    Rectangle().foregroundStyle(.quaternary.opacity(0.7))
                }
            }
            .onHover { hover in
                isHovering = hover
            }
            .animation(animationFast, value: [isHovering, isActive, configuration.isPressed])
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
