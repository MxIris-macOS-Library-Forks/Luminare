//
//  LuminarePopoverView.swift
//
//
//  Created by Kai Azim on 2024-06-02.
//

import SwiftUI

public enum LuminarePopoverTrigger {
    case onHover(delay: CGFloat = 0.5)
    case onForceTouch(
        threshold: CGFloat = 0.5,
        onGesture: (_ gesture: ForceTouchGesture, _ recognized: Bool) -> () = { _, _ in }
    )
}

public enum LuminarePopoverShade {
    case none
    case some(_ style: AnyShapeStyle)
    
    var style: AnyShapeStyle? {
        switch self {
        case .some(let style): style
        default: nil
        }
    }
    
    public static func styled<S: ShapeStyle>(_ style: S = .secondary) -> Self {
        .some(AnyShapeStyle(style))
    }
}

public struct LuminarePopoverView<Content, Badge>: View
where Content: View, Badge: View {
    public typealias Trigger = LuminarePopoverTrigger
    public typealias Shade = LuminarePopoverShade
    
    @Environment(\.luminareAnimationFast) private var animationFast
    
    private let arrowEdge: Edge
    private let trigger: Trigger
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let shade: Shade
    
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let badge: () -> Badge
    
    @State private var isPopoverPresented: Bool = false
    
    @State private var isHovering: Bool = false
    @State private var hoverTimer: Timer?
    
    @State private var forceTouchGesture: ForceTouchGesture = .inactive
    @State private var forceTouchRecognized: Bool = false
    @State private var forceTouchProgress: CGFloat = 0
    
    public init(
        arrowEdge: Edge = .bottom,
        trigger: Trigger = .onHover(),
        cornerRadius: CGFloat = 8,
        padding: CGFloat = 4,
        shade: Shade = .styled(),
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder badge: @escaping () -> Badge
    ) {
        self.arrowEdge = arrowEdge
        self.trigger = trigger
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shade = shade
        self.content = content
        self.badge = badge
    }
    
    public init(
        _ key: LocalizedStringKey,
        arrowEdge: Edge = .bottom,
        trigger: Trigger = .onHover(),
        highlight: Bool = true,
        cornerRadius: CGFloat = 8,
        padding: CGFloat = 4,
        shade: Shade = .styled(),
        @ViewBuilder badge: @escaping () -> Badge
    ) where Content == Text {
        self.init(
            arrowEdge: arrowEdge,
            trigger: trigger,
            cornerRadius: cornerRadius,
            padding: padding,
            shade: shade
        ) {
            Text(key)
        } badge: {
            badge()
        }
    }
    
    public init(
        arrowEdge: Edge = .bottom,
        trigger: Trigger = .onHover(),
        cornerRadius: CGFloat = 8,
        padding: CGFloat = 4,
        badgeSize: CGFloat = 4,
        @ViewBuilder content: @escaping () -> Content
    ) where Badge == AnyView {
        self.init(
            arrowEdge: arrowEdge,
            trigger: trigger,
            cornerRadius: cornerRadius,
            padding: padding,
            shade: .styled(.tint),
            content: content
        ) {
            AnyView(
                Circle()
                    .frame(width: badgeSize, height: badgeSize)
                    .foregroundStyle(.tint)
            )
        }
    }
    
    public var body: some View {
        Group {
            switch trigger {
            case .onHover(_):
                badge()
            case .onForceTouch(let threshold, let onGesture):
                ForceTouchView(threshold: threshold, gesture: $forceTouchGesture) {
                    badge()
                }
                .onChange(of: forceTouchGesture) { gesture in
                    switch gesture {
                    case .inactive:
                        let recognized = forceTouchRecognized
                        
                        forceTouchRecognized = false
                        isPopoverPresented = recognized
                    case .active(let event):
                        isPopoverPresented = true
                        
                        let stage = event.stage
                        
                        if stage == 1 {
                            if !forceTouchRecognized {
                                forceTouchProgress = event.pressure
                            }
                        }
                        
                        if stage == 2 {
                            forceTouchRecognized = true
                            forceTouchProgress = 1
                        }
                    }
                    
                    onGesture(gesture, forceTouchRecognized)
                }
            }
        }
        .padding(padding)
        .background {
            if let style = shade.style, isPopoverPresented {
                Group {
                    switch trigger {
                    case .onHover:
                        RoundedRectangle(cornerRadius: cornerRadius)
                    case .onForceTouch:
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .opacity(forceTouchProgress)
                    }
                }
                .foregroundStyle(style.opacity(0.1))
                .blur(radius: padding)
            }
        }
        .onHover { hover in
            isHovering = hover
            
            switch trigger {
            case .onHover(let delay):
                if isHovering {
                    hoverTimer = .scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                        isPopoverPresented = true
                        
                        hoverTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            isPopoverPresented = isHovering
                            hoverTimer?.invalidate()
                            hoverTimer = nil
                        }
                    }
                } else if hoverTimer == nil || !isPopoverPresented {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    isPopoverPresented = false
                }
            default:
                break
            }
            
        }
        .popover(isPresented: $isPopoverPresented, arrowEdge: arrowEdge) {
            Group {
                switch trigger {
                case .onHover:
                    content()
                case .onForceTouch:
                    content()
                        .opacity(0.5 + 0.5 * forceTouchProgress)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(-padding)
        .animation(animationFast, value: isPopoverPresented)
    }
}

public extension View {
    @ViewBuilder func luminarePopover<Content>(
        arrowEdge: Edge = .bottom,
        trigger: LuminarePopoverTrigger = .onHover(),
        cornerRadius: CGFloat = 8,
        padding: CGFloat = 4,
        shade: LuminarePopoverShade = .styled(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        LuminarePopoverView(
            arrowEdge: arrowEdge,
            trigger: trigger,
            cornerRadius: cornerRadius,
            padding: padding,
            shade: shade,
            content: content
        ) {
            self
        }
    }
}

private struct PopoverForceTouchPreview<Content, Badge>: View where Content: View, Badge: View {
    var arrowEdge: Edge = .bottom
    var cornerRadius: CGFloat = 8
    var padding: CGFloat = 4
    var shade: LuminarePopoverShade = .styled()
    
    @ViewBuilder var content: (_ gesture: ForceTouchGesture, _ recognized: Bool) -> Content
    @ViewBuilder var badge: () -> Badge
    
    @State private var gesture: ForceTouchGesture = .inactive
    @State private var recognized: Bool = false

    var body: some View {
        LuminarePopoverView(
            arrowEdge: arrowEdge,
            trigger: .onForceTouch { gesture, recognized in
                self.gesture = gesture
                self.recognized = recognized
            },
            cornerRadius: cornerRadius,
            padding: padding,
            shade: shade
        ) {
            content(gesture, recognized)
        } badge: {
            badge()
        }
    }
}

#Preview {
    LuminareSection {
        LuminareCompose {
        } label: {
            LuminarePopoverView(shade: .none) {
                Text("Here's to the *crazy* ones.")
                    .padding()
            } badge: {
                Text("Pops to bottom (hover me)")
            }
        }
        
        LuminareCompose {
        } label: {
            LuminarePopoverView(arrowEdge: .trailing) {
                VStack(alignment: .leading) {
                    Text("The **misfits.** The ~rebels.~")
                    Text("The [troublemakers](https://apple.com).")
                }
                .padding()
            } badge: {
                Text("Pops to trailing with highlight (hover me)")
            }
        }
        
        LuminareCompose {
        } label: {
            HStack {
                Text("Pops from a dot ↗")
                
                VStack {
                    LuminarePopoverView(arrowEdge: .top) {
                        VStack(alignment: .leading) {
                            Text("The round pegs in the square holes.")
                            Text("The ones **who see things differently.**")
                        }
                        .padding()
                    }
                    .tint(.violet)
                    
                    Spacer()
                }
            }
        }
        
        LuminareCompose {
        } label: {
            PopoverForceTouchPreview(arrowEdge: .top) { gesture, recognized in
                VStack(alignment: .leading) {
                    Text("**Think different.**")
                    
                    Group {
                        switch gesture {
                        case .active(let event) where event.stage == 1 && !recognized:
                            ProgressView(value: event.pressure)
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding()
                .frame(height: 100)
            } badge: {
                Text("Pops to top (force touch me)")
            }
        }
    }
    .padding()
}
