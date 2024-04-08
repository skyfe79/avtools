import AVFoundation
import CMTimeUtils

/// A class responsible for merging multiple audio and video files into a single composition.
///
/// This operation takes a directory URL as input, reads all files within the directory, and merges them into a single audio and video composition. The files are sorted by their names before merging to maintain a specific order.
class MergeOperation: AVOperation {
  /// The URL of the directory containing the files to be merged.
  private let inputURL: URL

  /// Initializes a new instance with the specified input directory URL.
  ///
  /// - Parameter inputURL: The `URL` of the directory containing the files to merge.
  init(inputURL: URL) {
    self.inputURL = inputURL
  }

  /// Executes the merge operation asynchronously.
  ///
  /// This method reads all files from the input directory, sorts them, and merges their audio and video tracks into a single composition. It also creates a video composition to ensure consistent frame rate across the merged video.
  ///
  /// - Throws: An error if the files cannot be read or the merge operation fails.
  /// - Returns: An optional `AVComposeContext` object representing the result of the merge operation.
  func run() async throws -> AVComposeContext? {
    // Retrieve and sort files from the input directory.
    let files = try FileManager.default.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil)
    let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }

    // Create a new composition to hold merged audio and video tracks.
    let composition = AVMutableComposition()
    var insertTime = CMTime.zero

    // Iterate over sorted files and merge their audio and video tracks into the composition.
    for file in sortedFiles {
      let assetSource = AVAssetSource(url: file)
      try await assetSource.load()

      // Merge audio tracks.
      if let audioTrack = await assetSource.tracks(for: .audio).first {
        let audioCompostionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try audioCompostionTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: insertTime)
      }

      // Merge video tracks.
      if let videoTrack = await assetSource.tracks(for: .video).first {
        let videoCompostionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try videoCompostionTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: insertTime)
      }

      // Update insert time for the next file.
      insertTime += assetSource.duration
    }

    // Create a video composition to ensure consistent frame rate across the merged video.
    // Note: There was an issue where only the first video played, and the rest were frozen. This was fixed by setting a consistent frame rate.
    let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

    // Return the editing context containing the merged composition and video composition.
    return AVComposeContext(composition: composition, videoComposition: videoComposition)
  }
}
