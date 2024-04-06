import AVFoundation
import CMTimeUtils

/// A class responsible for overlaying sound onto a video.
///
/// This operation takes an `AVAssetSource` and a sound URL as input. It overlays the specified sound onto the video track of the asset source.
class OverlaySoundOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let soundURL: URL

  /// Initializes a new instance with the specified asset source and sound URL.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to overlay the sound onto.
  ///   - soundURL: The `URL` of the sound to overlay.
  init(assetSource: AVAssetSource, soundURL: URL) {
    self.assetSource = assetSource
    self.soundURL = soundURL
  }

  /// Executes the overlay operation asynchronously.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation.
  func run() async throws -> AVAssetEditContext? {
    let (composition, videoComposition, audioMix) = await createComposition()
    return AVAssetEditContext(composition: composition, videoComposition: videoComposition, audioMix: audioMix)
  }

  /// Creates a composition and optionally an audio mix for the overlay operation.
  ///
  /// This method asynchronously adds video and audio tracks from the asset source to a new composition and overlays the specified sound.
  ///
  /// - Returns: A tuple containing an `AVComposition` and an optional `AVAudioMix`.
  func createComposition() async -> (AVComposition, AVVideoComposition?, AVAudioMix?) {
    let composition = AVMutableComposition()
    var videoComposition: AVVideoComposition?
    var audioMix: AVAudioMix?

    // Add video track to composition
    if let videoTrack = await assetSource.tracks(for: .video).first {
      let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? videoCompositionTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
      videoComposition = createVideoComposition(for: videoCompositionTrack)
    }

    // Add audio track to composition
    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? audioCompositionTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    // Overlay sound onto composition
    let soundAssetSource = AVAssetSource(url: soundURL)
    try? await soundAssetSource.load()
    if let soundTrack = await soundAssetSource.tracks(for: .audio).first {
      let soundCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? soundCompositionTrack?.insertTimeRange(soundAssetSource.duration.range, of: soundTrack, at: .zero)
      audioMix = createAudioMix(for: soundCompositionTrack)
    }

    return (composition, videoComposition, audioMix)
  }

  /// Creates a video composition for the overlay operation.
  ///
  /// This method configures the video composition with the necessary instructions based on the video track's orientation and sets the appropriate transform and render size.
  ///
  /// - Parameter videoTrack: The video track to create the video composition for.
  /// - Returns: An optional `AVVideoComposition` configured for the overlay operation.
  func createVideoComposition(for videoTrack: AVCompositionTrack?) -> AVVideoComposition? {
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
    videoCompositionInstruction.timeRange = assetSource.duration.range
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

    return videoComposition
  }

  /// Creates an audio mix with volume ramps for the specified audio track.
  ///
  /// This method configures the audio mix to gradually increase the volume of the sound at the beginning and decrease it at the end.
  ///
  /// - Parameter audioTrack: The audio track to create the audio mix for.
  /// - Returns: An optional `AVAudioMix` configured with volume ramps.
  func createAudioMix(for audioTrack: AVCompositionTrack?) -> AVAudioMix? {
    guard let audioTrack = audioTrack else { return nil }
    let audioMix = AVMutableAudioMix()
    let audioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
    let timeRange = audioTrack.timeRange.duration > assetSource.duration ? assetSource.duration.range : audioTrack.timeRange
    let (startToMid, midToEnd) = timeRange.splitByMidTime()
    audioMixInputParameters.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: startToMid)
    audioMixInputParameters.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: midToEnd)
    audioMix.inputParameters = [audioMixInputParameters]
    return audioMix
  }
}
