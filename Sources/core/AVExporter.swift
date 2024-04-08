import AVFoundation

/// A class responsible for exporting AV assets.
class AVExporter {
  /// The editing context containing the asset to be exported.
  private let editContext: AVComposeContext
  
  /// Initializes a new exporter with the given editing context.
  /// - Parameter editContext: The context containing the asset to be exported.
  init(editContext: AVComposeContext) {
    self.editContext = editContext
  }

  /// Exports the asset to the specified URL with the given settings.
  /// - Parameters:
  ///   - outputURL: The URL to export the asset to.
  ///   - outputFileType: The file type of the exported asset. Defaults to `.mov`.
  ///   - presetName: The preset name to use for the export. Defaults to `AVAssetExportPresetHighestQuality`.
  /// - Throws: An error if the export fails.
  func export(outputURL: URL, outputFileType: AVFileType = .mov, presetName: String = AVAssetExportPresetHighestQuality) async throws {
    guard let exportSession = AVAssetExportSession(asset: editContext.composition, presetName: presetName) else {
      throw "Failed to create AVAssetExportSession"
    }
    exportSession.outputURL = outputURL
    exportSession.outputFileType = outputFileType
    
    // Apply video composition and audio mix if they exist.
    if let videoComposition = editContext.videoComposition {
      exportSession.videoComposition = videoComposition
    }
    if let audioMix = editContext.audioMix {
      exportSession.audioMix = audioMix
    }
    await exportSession.export()

    // Handle the export session's completion status.
    if exportSession.status == .failed {
      if let error = exportSession.error {
        throw error
      }
    } else if exportSession.status == .completed {
      print("Export completed")
    }
  }
}