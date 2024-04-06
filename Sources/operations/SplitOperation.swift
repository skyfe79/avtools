import AVFoundation
import CMTimeUtils

/// A class that handles the operation of splitting an `AVAsset` into multiple segments.
///
/// This operation takes an `AVAssetSource`, a duration for each segment, and an output URL as input. It then splits the asset into multiple segments, each with the specified duration, and saves them to the specified output URL.
class SplitOperation: AVOperation {
  /// The source of the `AVAsset` to be split.
  private let assetSource: AVAssetSource
  /// The duration for each segment of the split operation, in seconds.
  private let duration: Double
  /// The URL where the split segments will be saved.
  private let outputURL: URL

  /// Initializes a new instance of `SplitOperation` with the specified parameters.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to be split.
  ///   - duration: The duration for each segment, in seconds.
  ///   - outputURL: The URL where the split segments will be saved.
  init(assetSource: AVAssetSource, duration: Double, outputURL: URL) {
    self.assetSource = assetSource
    self.duration = duration
    self.outputURL = outputURL
  }

  /// Executes the split operation asynchronously.
  ///
  /// This method creates a directory at the output URL (if it doesn't already exist), calculates the time ranges for each segment based on the specified duration, and exports each segment to the output URL.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation, which is `nil` in this case as the operation does not modify the asset context.
  func run() async throws -> AVAssetEditContext? {
    do {
      try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
      let ranges = CMTimeRange.stride(range: assetSource.duration.range, by: CMTimeValue(duration))

      await withTaskGroup(of: Void.self) { group in
        for range in ranges {
          group.addTask {
            let exportSession = AVAssetExportSession(asset: self.assetSource.asset, presetName: AVAssetExportPresetHighestQuality)
            exportSession?.outputURL = self.outputURL.appendingPathComponent(String(format: "%05d", Int(range.start.seconds)) + ".mp4")
            exportSession?.outputFileType = .mov
            exportSession?.timeRange = range
            await exportSession?.export()
          }
        }
      }
      return nil
    } catch {
      print(error)
      return nil
    }
  }
}
