import Cocoa
import SwiftUI

@objc
public class RollupButtonWrapper: NSObject {
    @objc
    public static func createRollupButton(target: AnyObject, action: Selector) -> NSView {
        let buttonView = CustomButton(target: target, action: action)
        let hostingView = TrackingHostingView(rootView: buttonView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        return hostingView
    }
}

class TrackingHostingView<Content: View>: NSHostingView<Content> {
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let location = self.convert(event.locationInWindow, from: nil)
        if !self.bounds.contains(location) {
            NotificationCenter.default.post(name: NSNotification.Name("RollupMouseUpOutside"), object: nil)
        }
    }
}

struct CustomButton: View {
    var target: AnyObject
    var action: Selector

    var body: some View {
        Button {
            _ = target.perform(action, with: nil)
        } label: {
            EmptyView()
        }
        .buttonStyle(CustomButtonStyle(
            symbol: "square.split.1x2"
        ))
        // Frame matches native traffic lights (12pt / 24px HiDPI)
        .frame(width: 12, height: 12)
        .fixedSize()
    }
}

struct CustomButtonStyle: ButtonStyle {
    var symbol: String
    @State private var isHover: Bool = false
    @State private var isActive: Bool = true // We manage this via NSApplication notifications

    // Native traffic light colors extracted
    let activeFillLight = Color(NSColor(srgbRed: 0.88, green: 0.88, blue: 0.88, alpha: 1.0))
    let activeStrokeLight = Color(NSColor(white: 0.0, alpha: 0.12))
    
    let activeFillDark = Color(NSColor(white: 0.22, alpha: 1.0))
    let activeStrokeDark = Color(NSColor(white: 0.0, alpha: 0.2))

    let activeBlueFill = Color(NSColor.systemBlue)
    let pressedFill = Color(NSColor(srgbRed: 0.0, green: 0.35, blue: 0.85, alpha: 1.0))
    let pressedStroke = Color(NSColor(white: 0.0, alpha: 0.3))

    func makeBody(configuration: Self.Configuration) -> some View {
        // Evaluate active state continuously since Notifications can sometimes race
        let isWindowActive = isActive && NSApplication.shared.isActive
        
        Circle()
            .fill(fillColor(isPressed: configuration.isPressed, isActive: isWindowActive))
            .overlay(
                Circle().strokeBorder(strokeColor(isPressed: configuration.isPressed, isActive: isWindowActive), lineWidth: 0.5)
            )
            .overlay(
                Group {
                    if (isHover || configuration.isPressed) && isWindowActive {
                        if #available(macOS 11.0, *) {
                            Image(systemName: symbol)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color.black.opacity(0.55))
                        }
                    }
                }
            )
            .onHover { hover in
                self.isHover = hover
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RollupMouseUpOutside"))) { _ in
                self.isHover = false
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                isActive = false
                isHover = false
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                isActive = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                isActive = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
                isActive = false
                isHover = false
            }
    }
    
    private func fillColor(isPressed: Bool, isActive: Bool) -> Color {
        if !isActive {
            // Apple standard inactive grayish fill (macOS 11+)
            return Color(NSColor(white: 0.82, alpha: 1.0)) 
        }
        if isPressed {
            return pressedFill
        }
        if isHover {
            return activeBlueFill
        }
        return activeBlueFill
    }
    
    private func strokeColor(isPressed: Bool, isActive: Bool) -> Color {
        if !isActive {
            return Color.black.opacity(0.12)
        }
        if isPressed {
            return pressedStroke
        }
        if isHover || isActive {
            return activeStrokeLight
        }
        return Color.black.opacity(0.12)
    }
}
