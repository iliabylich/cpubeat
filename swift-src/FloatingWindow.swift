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
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: Layout.width, height: Layout.height),
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )
    window.level = .floating
    window.collectionBehavior = [.ignoresCycle]
    window.isMovable = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.contentView = contentView
    return window
  }

  private func pin(to screen: Screen) {
    let area = screen.nsScreen.visibleFrame
    window.setFrameTopLeftPoint(NSPoint(x: area.minX, y: area.maxY))
  }

  private static func makeContentView(_ content: NSView) -> NSView {
    let view = NSGlassEffectView(frame: NSRect(x: 0, y: 0, width: Layout.width, height: Layout.height))
    view.style = .regular
    view.cornerRadius = Layout.cornerRadius
    view.contentView = content
    view.menu = makeMenu()
    return view
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
