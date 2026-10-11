import CoreGraphics

struct BorderCache {
  private struct CacheKey: Hashable {
    let appearance: Appearance
    let scale: CGFloat
  }

  private var images: [CacheKey: CGImage] = [:]

  mutating func fetch(
    appearance: Appearance, scale: CGFloat, orInsert makeImage: () -> CGImage
  ) -> CGImage {
    let key = CacheKey(appearance: appearance, scale: scale)
    if let image = images[key] { return image }
    let image = makeImage()
    images[key] = image
    return image
  }
}
