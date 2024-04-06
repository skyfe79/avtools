import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools extract-audio --input video.mov --output only_audio.m4a
  /// testing:
  /// - swift run avtools extract-audio --input ./assets/video.mov --output only_audio.m4a
  struct ExtractAudioCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "extract-audio",
      abstract: "Extract audio from an asset"
    )

    @OptionGroup
    var options: CommonOptions

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      print("naturalSize size: \(assetSource.naturalSize)")

      let operation = ExtractAudioOperation(assetSource: assetSource)
      if let editContext = try await operation.run() {
        let exporter = AVExporter(editContext: editContext)
        do {
          try await exporter.export(outputURL: options.output, outputFileType: .m4a, presetName: AVAssetExportPresetAppleM4A)
        } catch {
          print("Export failed: \(error.localizedDescription)")
        }
      }
    }
  }
}
