import AppKit

@MainActor
struct StatusItem {
  let button: NSStatusBarButton
  private let item: NSStatusItem

  init() {
    item = NSStatusBar.system.statusItem(withLength: Layout.width)
    guard let statusBarButton = item.button else {
      fatalError("status item has no button")
    }
    button = statusBarButton
    item.menu = Self.makeMenu()
  }

  private static func makeMenu() -> NSMenu {
    let menu = NSMenu()
    menu.addItem(
      NSMenuItem(
        title: "Quit cpubeat",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q",
      )
    )
    return menu
  }
}
