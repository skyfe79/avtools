import ArgumentParser
import AVFoundation

/// A class that generates images from an `AVAsset`.
///
/// This class conforms to the `AVOperation` protocol and utilizes `AVFoundation` to generate images at specified times or intervals (strides) from an audiovisual asset.
class GenerateImagesOperation: AVOperation {
  /// The source asset from which images will be generated.
  let assetSource: AVAssetSource
  /// An array of `CMTime` objects representing the times at which to generate images.
  let times: [CMTime]
  /// The interval between each image generation in seconds. A stride of 0 means no striding is used.
  let stride: Double
  /// The URL of the folder where the generated images will be saved.
  let outputURL: URL

  /// Initializes a new instance with the specified parameters.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to generate images from.
  ///   - times: An array of `CMTime` objects specifying the times at which to generate images.
  ///   - stride: An optional `Double` specifying the interval between each image generation in seconds. Defaults to 0 if not provided.
  ///   - outputURL: The `URL` of the folder where the generated images will be saved.
  init(assetSource: AVAssetSource, times: [CMTime], stride: Double?, outputURL: URL) {
    self.assetSource = assetSource
    self.times = times
    self.stride = stride ?? 0
    self.outputURL = outputURL
  }

  /// Runs the image generation operation asynchronously.
  ///
  /// This method generates images from the source asset at the specified times or at intervals defined by `stride`. The generated images are saved to the folder specified by `outputURL`.
  ///
  /// - Throws: An error if neither times nor stride are provided.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation. Currently, this method always returns `nil`.
  @discardableResult
  func run() async throws -> AVAssetEditContext? {
    guard times.isEmpty == false || stride > 0 else {
      throw "Either times or stride must be provided"
    }

    let imageGenerator = AVAssetSourceImageGenerator(assetSource: assetSource)
    if !times.isEmpty {
      await imageGenerator.generateImages(for: times, outputFolderURL: outputURL)
    } else if stride > 0 {
      let stridedTimes = assetSource.duration.stride(by: CMTime(seconds: stride, preferredTimescale: assetSource.duration.timescale))
      await imageGenerator.generateImages(for: stridedTimes, outputFolderURL: outputURL)
    }

    return nil
  }
}