import AppKit

@MainActor
struct SkyLight {
  struct Space: Equatable {
    let id: Int
    let isDesktop: Bool

    fileprivate static func parse(_ raw: [String: Any]) -> Self? {
      guard let id = raw["ManagedSpaceID"] as? Int, let type = raw["type"] as? Int else { return nil }
      return Self(id: id, isDesktop: type == 0)
    }

    fileprivate static func parse(_ raw: [[String: Any]]) -> [Self] {
      raw.compactMap { parse($0) }
    }
  }

  struct DisplaySpaces {
    let current: Space
    let all: [Space]
  }

  private static let sharedDisplayUUID = "Main"
  private static let screensHaveSeparateSpaces = NSScreen.screensHaveSeparateSpaces

  private var spacesByDisplay: [String: DisplaySpaces] = [:]

  init?() {
    guard let displays = SkyLightFFI.managedDisplaySpaces() else {
      print("failed to query spaces, private API is unavailable")
      return nil
    }
    for display in displays {
      guard
        let displayUUID = display["Display Identifier"] as? String,
        let currentSpace = (display["Current Space"] as? [String: Any]).flatMap(Space.parse),
        let spaces = (display["Spaces"] as? [[String: Any]]).map(Space.parse)
      else { continue }
      spacesByDisplay[displayUUID] = DisplaySpaces(current: currentSpace, all: spaces)
    }
  }

  func slice(_ displayUUID: String) -> DisplaySpaces? {
    let key = Self.screensHaveSeparateSpaces ? displayUUID : Self.sharedDisplayUUID
    return spacesByDisplay[key]
  }
}
