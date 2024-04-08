import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools crop --input video.mov --output c.mov --crop-rect "0 0 100 100"
  /// Image Origin: left-bottom
  /// testing:
  /// - swift run avtools crop --input ./assets/video.mov --output c.mov --crop-rect "0 0 100 100"
  struct CropCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "crop",
      abstract: "Crop an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Crop rectangle in the format of 'x y width height'", transform: CGRect.init(string:))
    var cropRect: CGRect

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      print("naturalSize size: \(assetSource.naturalSize)")

      let cropOperation = CropOperation(assetSource: assetSource, cropRect: cropRect)
      if let composeContext = try await cropOperation.run() {
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
