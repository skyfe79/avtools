import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools extract-video --input video.mov --output only_video.mov
  /// testing:
  /// - swift run avtools extract-video --input ./assets/video.mov --output only_video.mov
  struct ExtractVideoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "extract-video",
      abstract: "Extract video from an asset"
    )

    @OptionGroup
    var options: CommonOptions

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      print("naturalSize size: \(assetSource.naturalSize)")

      let operation = ExtractVideoOperation(assetSource: assetSource)
      if let composeContext = try await operation.run() {
        let exporter = AVExporter(composeContext: composeContext)
        do {
          try await exporter.export(outputURL: options.output)
        } catch {
          print("Export failed: \(error.localizedDescription)")
        }
      }
    }
  }
}
