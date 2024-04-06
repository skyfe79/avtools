import AVFoundation
import Cocoa

/// A class responsible for generating images from an `AVAssetSource`.
class AVAssetSourceImageGenerator {
  /// The source of the asset from which images will be generated.
  let assetSource: AVAssetSource
  /// The image generator used to create images from the asset.
  let imageGenerator: AVAssetImageGenerator

  /// Initializes a new image generator with the specified asset source.
  /// - Parameter assetSource: The `AVAssetSource` to use for generating images.
  init(assetSource: AVAssetSource) {
    self.assetSource = assetSource
    imageGenerator = AVAssetImageGenerator(asset: assetSource.asset)
  }

  /// Asynchronously generates images for the specified times and saves them to the given folder.
  /// - Parameters:
  ///   - times: An array of `CMTime` objects representing the times at which to generate images.
  ///   - outputFolderURL: The URL of the folder where the generated images will be saved.
  func generateImages(for times: [CMTime], outputFolderURL: URL) async {
    // Attempt to create the output directory if it doesn't already exist.
    try? FileManager.default.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)

    // Configure the image generator for precise image timing.
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero

    // Generate the images for the specified times.
    let images = imageGenerator.images(for: times)
    for await image in images {
      let requestedTime = image.requestedTime
      // If the image could be generated, save it to the output folder.
      if let cgImage = try? image.image {
        let url = outputFolderURL.appendingPathComponent("\(requestedTime.seconds).jpg")
        try? cgImage.writeJPG(to: url)
      }
    }
  }
}
