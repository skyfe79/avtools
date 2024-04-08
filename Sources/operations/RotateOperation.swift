import ArgumentParser
import AVFoundation
import CMTimeUtils

/// A class responsible for rotating a video by a specified angle.
///
/// This operation takes an `AVAssetSource` and an angle as input. It rotates the video track of the asset source by the specified angle.
class RotateOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let angle: Double
  
  /// Initializes a new instance with the specified asset source and rotation angle.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to rotate.
  ///   - angle: The angle by which to rotate the video, in degrees.
  init(assetSource: AVAssetSource, angle: Double) {
    self.assetSource = assetSource
    self.angle = angle
  }

  /// Executes the rotation operation asynchronously.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVComposeContext` object representing the result of the rotation operation.
  func run() async throws -> AVComposeContext? {
    let composition = await createComposition()
    let videoComposition = await createVideoComposition()
    return AVComposeContext(composition: composition, videoComposition: videoComposition)
  }

  /// Creates a composition for the rotation operation.
  ///
  /// This method asynchronously adds video and audio tracks from the asset source to a new composition.
  ///
  /// - Returns: An `AVComposition` that contains the video and audio tracks from the asset source.
  func createComposition() async -> AVComposition {
    let composition = AVMutableComposition()

    if let videoTrack = await assetSource.tracks(for: .video).first {
      let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionVideoTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
    }

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionAudioTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    return composition
  }

  /// Creates a video composition for the rotation operation.
  ///
  /// This method configures the video composition with the necessary instructions and transformations to rotate the video by the specified angle.
  ///
  /// - Returns: An optional `AVVideoComposition` configured for the rotation.
  func createVideoComposition() async -> AVVideoComposition? {
    let videoComposition = AVMutableVideoComposition()
    guard let videoTrack = await assetSource.tracks(for: .video).first else { return nil }
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let (t, newSize) = assetSource.transformAndSizeForRotation(angle: angle, originalSize: assetSource.naturalSize)
    layerInstruction.setTransform(t, at: .zero)

    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    videoCompositionInstruction.timeRange = assetSource.duration.range
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.renderSize = newSize

    return videoComposition
  }
}
