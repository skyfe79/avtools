import Foundation

/// An extension that conforms `String` to the `Error` protocol.
///
/// This extension allows any `String` instance to be used as an error object. The `localizedDescription` property returns the string itself.
extension String: Error {
  /// A description of the error.
  ///
  /// In this case, it simply returns the string itself.
  public var localizedDescription: String {
    return self
  }
}