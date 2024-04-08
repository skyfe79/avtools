import AVFoundation

/// A context for composing `AVAsset` instances, encapsulating composition, video composition, and audio mix.
///
/// This class provides a structured way to manage the components required for editing an `AVAsset`, such as combining multiple assets, applying video and audio effects, and exporting the final composition.
class AVComposeContext {
  /// The composition of assets.
  ///
  /// This property holds the `AVComposition` object that represents the combined assets used in the editing context.
  let composition: AVComposition
  
  /// The video composition.
  ///
  /// This optional property holds an `AVVideoComposition` object, which describes how video tracks are composed and processed. It can include instructions for applying video effects, transitions, and other video manipulations.
  let videoComposition: AVVideoComposition?
  
  /// The audio mix.
  ///
  /// This optional property holds an `AVAudioMix` object, which defines how audio tracks are mixed and processed. It can include parameters for applying audio effects, volume adjustments, and other audio manipulations.
  let audioMix: AVAudioMix?

  /// Initializes a new `AVComposeContext`.
  ///
  /// - Parameters:
  ///   - composition: An `AVComposition` object representing the combined assets.
  ///   - videoComposition: An optional `AVVideoComposition` object for video processing. Defaults to `nil`.
  ///   - audioMix: An optional `AVAudioMix` object for audio processing. Defaults to `nil`.
  init(composition: AVComposition, videoComposition: AVVideoComposition? = nil, audioMix: AVAudioMix? = nil) {
    self.composition = composition
    self.videoComposition = videoComposition
    self.audioMix = audioMix
  }
}
