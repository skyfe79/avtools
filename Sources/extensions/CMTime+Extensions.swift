import ArgumentParser
import CoreMedia
import Foundation

extension CMTime {
  /// Initializes a `CMTime` instance from a string.
  ///
  /// This initializer attempts to convert the string to a `Double` representing seconds. If the conversion fails, it throws a `ValidationError`.
  ///
  /// - Parameter stringValue: A `String` representing the number of seconds.
  /// - Throws: A `ValidationError` if the string cannot be converted to a `Double`.
  init(from stringValue: String) throws {
    guard let seconds = Double(stringValue) else {
      throw ValidationError("Invalid seconds value")
    }
    self.init(seconds: seconds, preferredTimescale: 600)
  }
}
