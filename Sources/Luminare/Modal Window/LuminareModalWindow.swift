//
//  LuminareModalWindow.swift
//
//
//  Created by Kai Azim on 2024-04-14.
//
// Huge thanks to https://cindori.com/developer/floating-panel :)

import SwiftUI

class LuminareModal<Content>: NSWindow, ObservableObject where Content: View {
    @Binding var isPresented: Bool
    let closeOnDefocus: Bool
    let compactMode: Bool

    init(
        view: () -> Content,
        isPresented: Binding<Bool>,
        closeOnDefocus: Bool,
        compactMode: Bool
    ) {
        self._isPresented = isPresented
        self.closeOnDefocus = closeOnDefocus
        self.compactMode = compactMode
        super.init(
            contentRect: .zero,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(
            rootView: LuminareModalView(view(), compactMode: compactMode)
                .environment(\.tintColor, LuminareSettingsWindow.tint)
                .environmentObject(self)
        )

        collectionBehavior.insert(.fullScreenAuxiliary)
        level = .floating
        backgroundColor = .clear
        contentView = hostingView
        contentView?.wantsLayer = true
        ignoresMouseEvents = false
        isOpaque = false
        hasShadow = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        animationBehavior = .documentWindow

        center()
    }

    func updateShadow(for duration: Double) {
        guard isPresented else { return }

        let frameRate: Double = 60
        let updatesCount = Int(duration * frameRate)
        let interval = duration / Double(updatesCount)

        for i in 0...updatesCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                self.invalidateShadow()
            }
        }
    }

    override func close() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.animator().alphaValue = 0
        }, completionHandler: {
            super.close()
            self.isPresented = false
        })
    }

    override func keyDown(with event: NSEvent) {
        let wKey = 13
        if event.keyCode == wKey, event.modifierFlags.contains(.command) {
            close()
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let titlebarHeight: CGFloat = compactMode ? 12 : 16
        if event.locationInWindow.y > frame.height - titlebarHeight {
            super.performDrag(with: event)
        } else {
            super.mouseDragged(with: event)
        }
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

struct LuminareModalModifier<PanelContent>: ViewModifier where PanelContent: View {
    @Binding var isPresented: Bool
    @ViewBuilder let view: () -> PanelContent
    @State private var panel: LuminareModal<PanelContent>?
    let closeOnDefocus: Bool
    let compactMode: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    present()
                } else {
                    close()
                }
            }
            .onDisappear {
                isPresented = false
                close()
            }
    }

    private func present() {
        guard panel == nil else { return }
        panel = LuminareModal(
            view: view,
            isPresented: $isPresented,
            closeOnDefocus: closeOnDefocus,
            compactMode: compactMode
        )

        DispatchQueue.main.async {
            panel?.center()
            panel?.orderFrontRegardless()
            panel?.makeKey()
        }
    }

    private func close() {
        panel?.close()
        panel = nil
    }
}

public extension View {
    func luminareModal(
        isPresented: Binding<Bool>,
        closeOnDefocus: Bool = false,
        compactMode: Bool = false,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(
            LuminareModalModifier(
                isPresented: isPresented,
                view: content,
                closeOnDefocus: closeOnDefocus,
                compactMode: compactMode
            )
        )
    }
}
