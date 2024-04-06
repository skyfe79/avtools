import AVFoundation
import CMTimeUtils

/// A utility class for trimming `AVAsset` instances.
///
/// This class provides functionality to trim an `AVAsset` to a specified time range and export it to a new file.
class AVTrimmer {
  /// The source of the `AVAsset` to be trimmed.
  private let assetSource: AVAssetSource
  
  /// Initializes a new trimmer with the given asset source.
  ///
  /// - Parameter assetSource: The source of the `AVAsset` to be trimmed.
  init(assetSource: AVAssetSource) {
    self.assetSource = assetSource
  }

  /// Trims the asset to the specified time range and exports it to the given URL.
  ///
  /// This method asynchronously trims the asset to the specified start and end times, then exports the trimmed asset to the provided output URL.
  ///
  /// - Parameters:
  ///   - start: The start time of the trim range.
  ///   - end: The end time of the trim range.
  ///   - output: The URL to export the trimmed asset to.
  /// - Throws: An error if the trimming or export process fails.
  func trim(start: CMTime, end: CMTime, output: URL) async throws {
    guard let exportSession = AVAssetExportSession(asset: assetSource.asset, presetName: AVAssetExportPresetHighestQuality) else {
      throw "Failed to create AVAssetExportSession"
    }
    exportSession.outputURL = output
    exportSession.outputFileType = .mov
    exportSession.timeRange = start.range(to: end)
    await exportSession.export()
    if exportSession.status == .failed {
      if let error = exportSession.error {
        throw error
      }
    } else if exportSession.status == .completed {
      print("Trim completed")
    }
  }
}