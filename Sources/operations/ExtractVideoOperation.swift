import AVFoundation

/// A class responsible for extracting video tracks from an `AVAsset`.
///
/// This class conforms to the `AVOperation` protocol and utilizes `AVFoundation` to perform video extraction and composition tasks.
class ExtractVideoOperation: AVOperation {
  /// The source asset from which video will be extracted.
  private let assetSource: AVAssetSource

  /// Initializes a new instance with the specified asset source.
  ///
  /// - Parameter assetSource: The `AVAssetSource` to extract video from.
  init(assetSource: AVAssetSource) {
    self.assetSource = assetSource
  }

  /// Runs the video extraction operation asynchronously.
  ///
  /// This method creates an `AVComposition` and an `AVVideoComposition`, then returns an `AVAssetEditContext` containing these compositions.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation.
  func run() async throws -> AVAssetEditContext? {
    let composition = await createComposition()
    let videoComposition = await createVideoComposition()
    return AVAssetEditContext(composition: composition, videoComposition: videoComposition)
  }

  /// Asynchronously creates an `AVComposition` with the video track of the source asset.
  ///
  /// This method extracts the first video track found in the source asset and adds it to a new `AVMutableComposition`.
  ///
  /// - Returns: An `AVComposition` containing the video track.
  func createComposition() async -> AVComposition {
    let composition = AVMutableComposition()

    if let videoTrack = await assetSource.tracks(for: .video).first {
      let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? videoCompositionTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
    }

    return composition
  }

  /// Asynchronously creates an `AVVideoComposition` for the video track of the source asset.
  ///
  /// This method configures video composition settings, including orientation and render size, based on the source asset's properties.
  ///
  /// - Returns: An optional `AVVideoComposition` configured for the video track.
  func createVideoComposition() async -> AVVideoComposition? {
    let videoComposition = AVMutableVideoComposition()
    guard let videoTrack = await assetSource.tracks(for: .video).first else { return nil }
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

    let orientationInfo = assetSource.orientationInfo
    if orientationInfo.isPortrait {
      let (transform, size) = assetSource.transformAndSizeForRotation(angle: 90, originalSize: assetSource.naturalSize)
      layerInstruction.setTransform(transform, at: .zero)
      videoComposition.renderSize = size
    } else {
      let (transform, size) = assetSource.transformAndSizeForRotation(angle: 0, originalSize: assetSource.naturalSize)
      layerInstruction.setTransform(transform, at: .zero)
      videoComposition.renderSize = size
    }

    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    videoCompositionInstruction.timeRange = assetSource.duration.range
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

    return videoComposition
  }
}
