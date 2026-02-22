import Cocoa
import SwiftUI

struct CustomButton: View {
    var fillColor: Color
    var bezelColor: Color
    var symbol: String

    var body: some View {
        Button {

        } label: {
            EmptyView()
        }
        .buttonStyle(CustomButtonStyle(
            fillColor: fillColor,
            bezelColor: bezelColor,
            symbol: symbol
        ))
        .frame(width: 14, height: 14)
        .fixedSize()
    }
}

struct CustomButtonStyle: ButtonStyle {
    var fillColor: Color
    var bezelColor: Color
    var symbol: String
    @State private var isHover: Bool = false
    @State private var isActive: Bool = false

    func makeBody(configuration: Self.Configuration) -> some View {
        Circle()
            .fill(isActive ? fillColor : Color(.inactive))
            .overlay {
                if isActive {
                    Circle()
                        .stroke(bezelColor, lineWidth: 1)
                }
            }
            .overlay {
                if isHover, isActive {
                    Image(systemName: symbol)
                        .font(.system(size: 8).weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.5))
                }
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .onHover { isHover in
                self.isHover = isHover
            }
            .onBackground {
                isActive = false
            }
            .onForeground {
                isActive = true
            }
    }
}


extension View {
    func onBackground(_ f: @escaping () -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification),
            perform: { _ in f() }
        )
    }

    func onForeground(_ f: @escaping () -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification),
            perform: { _ in f() }
        )
    }
}

final class CustomView: NSView {
    var windowButtons = [NSView]()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(childView: NSView) {
        super.init(frame: .zero)
        childView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(childView)
        childView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        childView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        childView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        childView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func setWindowButton(zoomButton: NSButton?) {
        guard let zoomButton, let parentView = zoomButton.superview else { return }

        let button1 = NSHostingView(rootView: CustomButton(
            fillColor: Color(.starFill),
            bezelColor: Color(.starBezel),
            symbol: "star.fill"
        ))
        button1.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(button1)
        button1.leftAnchor.constraint(equalTo: zoomButton.rightAnchor, constant: 9).isActive = true
        button1.centerYAnchor.constraint(equalTo: zoomButton.centerYAnchor).isActive = true
        windowButtons.append(button1)

        let button2 = NSHostingView(rootView: CustomButton(
            fillColor: Color(.heartFill),
            bezelColor: Color(.heartBezel),
            symbol: "heart.fill"
        ))
        button2.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(button2)
        button2.leftAnchor.constraint(equalTo: button1.rightAnchor, constant: 9).isActive = true
        button2.centerYAnchor.constraint(equalTo: button1.centerYAnchor).isActive = true
        windowButtons.append(button2)
    }
}

class CustomWindow: NSWindow {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.closable, .miniaturizable, .resizable, .fullSizeContentView, .titled],
            backing: .buffered,
            defer: false
        )
    }

    func setChildView(_ childView: NSView) {
        contentView = CustomView(childView: childView)
    }

    override var canBecomeKey: Bool { true }

    override var canBecomeMain: Bool { true }

    override func updateConstraintsIfNeeded() {
        super.updateConstraintsIfNeeded()
        guard let customView = contentView as? CustomView else { return }
        if customView.subviews.count == 1, customView.windowButtons.isEmpty {
            customView.setWindowButton(zoomButton: standardWindowButton(.zoomButton))
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .frame(width: 300, height: 200)
            .fixedSize()
            .padding()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var customWindow: CustomWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        customWindow = CustomWindow()
        customWindow?.setChildView(NSHostingView(rootView: ContentView()))
        customWindow?.center()
        customWindow?.orderFront(nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}