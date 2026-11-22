import AppKit

@MainActor
final class FloatingWindow {
  private let window: NSWindow

  init(content: NSView) {
    window = Self.makeWindow(contentView: Self.makeContentView(content))

    refreshOnEach(NSWorkspace.activeSpaceDidChangeNotification, from: NSWorkspace.shared.notificationCenter)
    refreshOnEach(NSApplication.didChangeScreenParametersNotification, from: .default)
  }

  private func refreshOnEach(_ name: Notification.Name, from center: NotificationCenter) {
    Task { [weak self] in
      for await _ in center.notifications(named: name) {
        self?.refresh()
      }
    }
  }

  func refresh() {
    if let screen = Self.targetScreen() {
      show(on: screen)
    } else {
      hide()
    }
  }

  private static func targetScreen() -> Screen? {
    guard let screen = Screen.preferred(), let skyLight = SkyLight() else { return nil }
    guard let spaces = skyLight.slice(screen.uuid) else {
      print("failed to find spaces of \(screen.nsScreen.localizedName)")
      return nil
    }
    guard let preferredSpace = spaces.all.first(where: \.isDesktop) else {
      print("failed to find a desktop space of \(screen.nsScreen.localizedName) in \(spaces.all)")
      return nil
    }
    return spaces.current == preferredSpace ? screen : nil
  }

  private func show(on screen: Screen) {
    if window.isVisible, window.isOnActiveSpace, window.screen.flatMap(Screen.init) == screen {
      pin(to: screen)
      return
    }
    window.orderOut(nil)
    pin(to: screen)
    window.orderFrontRegardless()
  }

  private func hide() {
    if window.isOnActiveSpace {
      window.orderOut(nil)
    }
  }

  private static func makeWindow(contentView: NSView) -> NSWindow {
    let window = UnconstrainedWindow(
      contentRect: NSRect(origin: .zero, size: windowSize),
      styleMask: [.titled, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
      window.standardWindowButton(button)?.isHidden = true
    }
    window.level = .floating
    window.collectionBehavior = [.ignoresCycle]
    window.isMovable = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = false
    window.contentView = contentView
    return window
  }

  private static let windowPadding: CGFloat = 10

  private static let windowSize = NSSize(
    width: Layout.width + 2 * windowPadding,
    height: Layout.height + 2 * windowPadding
  )

  private func pin(to screen: Screen) {
    let area = screen.nsScreen.visibleFrame
    window.setFrameTopLeftPoint(
      NSPoint(x: area.minX - Self.windowPadding, y: area.maxY + Self.windowPadding))
  }

  private static func makeContentView(_ content: NSView) -> NSView {
    let glass = NSGlassEffectView(
      frame: NSRect(x: windowPadding, y: windowPadding, width: Layout.width, height: Layout.height))
    glass.style = .regular
    glass.cornerRadius = Layout.cornerRadius
    glass.contentView = content
    glass.menu = makeMenu()

    let container = NSView(frame: NSRect(origin: .zero, size: windowSize))
    container.addSubview(glass)
    return container
  }

  private static func makeMenu() -> NSMenu {
    let menu = NSMenu()
    let quit = NSMenuItem(
      title: "Quit cpubeat",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q",
    )
    quit.target = NSApplication.shared
    menu.addItem(quit)
    return menu
  }
}

private final class UnconstrainedWindow: NSWindow {
  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    frameRect
  }
}
