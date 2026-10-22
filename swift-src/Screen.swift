import AppKit

@MainActor
struct Screen: Equatable {
  private enum Kind: Comparable { case external, builtin }

  let nsScreen: NSScreen
  let displayID: CGDirectDisplayID
  let uuid: String
  private let kind: Kind
  private let name: String
  private let serial: UInt32

  init?(_ nsScreen: NSScreen) {
    guard
      let displayID = nsScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
        as? CGDirectDisplayID
    else {
      print("failed to get display ID of \(nsScreen.localizedName)")
      return nil
    }
    guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
      print("failed to get UUID of display \(displayID) (\(nsScreen.localizedName))")
      return nil
    }
    guard let uuid = CFUUIDCreateString(nil, cfUUID) as String? else {
      fatalError("failed to convert UUID of display \(displayID) (\(nsScreen.localizedName)) to string")
    }
    self.nsScreen = nsScreen
    self.displayID = displayID
    self.uuid = uuid
    kind = CGDisplayIsBuiltin(displayID) != 0 ? .builtin : .external
    name = nsScreen.localizedName
    serial = CGDisplaySerialNumber(displayID)
  }

  static func preferred() -> Self? {
    let key = { (screen: Self) in (screen.kind, screen.name, screen.serial, screen.displayID) }
    return NSScreen.screens.compactMap(Self.init).min { key($0) < key($1) }
  }

  nonisolated static func == (a: Self, b: Self) -> Bool {
    a.displayID == b.displayID
  }
}
