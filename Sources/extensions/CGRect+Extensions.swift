import CoreGraphics
import Foundation

extension CGRect {
  /// Initializes a `CGRect` instance from a string.
  ///
  /// The string must contain four numeric values separated by spaces, representing `x`, `y`, `width`, and `height` respectively.
  /// If the string does not contain exactly four numeric values, a `CGRect` with all values set to `0` is returned.
  ///
  /// - Parameter string: A `String` containing the rectangle's origin and size values.
  init(string: String) {
    let values = string.trimmingCharacters(in: .alphanumerics.inverted).split(separator: " ").compactMap { Double($0) }
    guard values.count == 4 else {
      self.init(x: 0, y: 0, width: 0, height: 0)
      return
    }
    self.init(x: values[0], y: values[1], width: values[2], height: values[3])
  }
}
