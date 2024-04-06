import AVFoundation

/// A class responsible for extracting the audio track from an `AVAsset`.
///
/// This class conforms to the `AVOperation` protocol and utilizes `AVFoundation` to perform audio extraction.
class ExtractAudioOperation: AVOperation {
  /// The source asset from which audio will be extracted.
  private let assetSource: AVAssetSource

  /// Initializes a new instance with the specified asset source.
  ///
  /// - Parameter assetSource: The `AVAssetSource` to extract audio from.
  init(assetSource: AVAssetSource) {
    self.assetSource = assetSource
  }

  /// Runs the audio extraction operation asynchronously.
  ///
  /// This method creates an `AVComposition` containing only the audio track of the source asset.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation.
  func run() async throws -> AVAssetEditContext? {
    let composition = await createComposition()
    return AVAssetEditContext(composition: composition)
  }

  /// Asynchronously creates an `AVComposition` with the audio track of the source asset.
  ///
  /// This method extracts the first audio track found in the source asset and adds it to a new `AVMutableComposition`.
  ///
  /// - Returns: An `AVComposition` containing the extracted audio track.
  func createComposition() async -> AVComposition {
    let composition = AVMutableComposition()

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? audioCompositionTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    return composition
  }
}
