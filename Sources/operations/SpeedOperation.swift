import AVFoundation
import CMTimeUtils

/// A class responsible for adjusting the speed of a video.
///
/// This operation takes an `AVAssetSource` and a speed multiplier as input. It adjusts the video and audio tracks of the asset source by the specified speed multiplier.
class SpeedOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let speed: Double

  /// Initializes a new instance with the specified asset source and speed multiplier.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to adjust the speed of.
  ///   - speed: The speed multiplier to apply. A value greater than 1.0 increases the speed, while a value less than 1.0 decreases it.
  init(assetSource: AVAssetSource, speed: Double) {
    self.assetSource = assetSource
    self.speed = speed
  }

  /// Executes the speed adjustment operation asynchronously.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVComposeContext` object representing the result of the operation.
  func run() async throws -> AVComposeContext? {
    let (composition, videoCompositon) = await createComposition()
    return AVComposeContext(composition: composition, videoComposition: videoCompositon)
  }

  /// Creates a composition and a video composition for the speed adjustment operation.
  ///
  /// This method asynchronously adds video and audio tracks from the asset source to a new composition and adjusts their speed by the specified multiplier.
  ///
  /// - Returns: A tuple containing an `AVComposition` and an optional `AVVideoComposition`.
  func createComposition() async -> (AVComposition, AVVideoComposition?) {
    let composition = AVMutableComposition()
    var videoComposition: AVVideoComposition?
    if let videoTrack = await assetSource.tracks(for: .video).first {
      let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionVideoTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
      compositionVideoTrack?.scaleTimeRange(assetSource.duration.range, toDuration: assetSource.duration * (1 / speed))
      videoComposition = createVideoComposition(for: compositionVideoTrack)
    }

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionAudioTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
      compositionAudioTrack?.scaleTimeRange(assetSource.duration.range, toDuration: assetSource.duration * (1 / speed))
    }

    return (composition, videoComposition)
  }

  /// Creates a video composition for the speed adjustment operation.
  ///
  /// This method configures the video composition with the necessary instructions and transformations to adjust the speed of the video track.
  ///
  /// - Parameter videoTrack: The video track to adjust the speed of.
  /// - Returns: An optional `AVVideoComposition` configured for the speed adjustment.
  func createVideoComposition(for videoTrack: AVMutableCompositionTrack?) -> AVVideoComposition? {
    guard let videoTrack = videoTrack else { return nil }
    let videoComposition = AVMutableVideoComposition()
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
    videoCompositionInstruction.timeRange = videoTrack.timeRange
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

    return videoComposition
  }
}
