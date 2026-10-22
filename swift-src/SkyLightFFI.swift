import Foundation

@MainActor
enum SkyLightFFI {
  private static let handle = dlopen(
    "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)

  private static func lookup(_ name: String) -> UnsafeMutableRawPointer? {
    dlsym(handle, name)
  }

  private typealias MainConnectionID = @convention(c) () -> Int32
  private typealias CopyManagedDisplaySpaces = @convention(c) (Int32) -> Unmanaged<CFArray>?

  private static let mainConnectionID: MainConnectionID? = {
    guard let fn = lookup("SLSMainConnectionID") ?? lookup("CGSMainConnectionID") else { return nil }
    return unsafeBitCast(fn, to: MainConnectionID.self)
  }()

  private static let copyManagedDisplaySpaces: CopyManagedDisplaySpaces? = {
    guard let fn = lookup("SLSCopyManagedDisplaySpaces") ?? lookup("CGSCopyManagedDisplaySpaces") else {
      return nil
    }
    return unsafeBitCast(fn, to: CopyManagedDisplaySpaces.self)
  }()

  static func managedDisplaySpaces() -> [[String: Any]]? {
    guard let mainConnectionID, let copyManagedDisplaySpaces else { return nil }
    return copyManagedDisplaySpaces(mainConnectionID())?.takeRetainedValue() as? [[String: Any]]
  }
}
