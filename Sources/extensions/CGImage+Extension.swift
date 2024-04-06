import CoreGraphics
import Foundation
import QuartzCore
import UniformTypeIdentifiers

extension CGImage {
  /// Writes the current `CGImage` as a JPEG to the specified URL.
  ///
  /// This method attempts to create a destination for the JPEG image and write the current image to it.
  /// If the destination cannot be created or the image cannot be written, an error is thrown.
  ///
  /// - Parameter url: The URL to write the JPEG image to.
  /// - Throws: An error if the destination cannot be created or if the image cannot be written.
  func writeJPG(to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
      throw "Error: Could not create destination image at \(url)"
    }
    CGImageDestinationAddImage(destination, self, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw "Error: Could not finalize destination image at \(url)"
    }
  }
}
