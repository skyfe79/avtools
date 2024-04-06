import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools rotate --input video.mov --output rv.mov --angle 180
  /// testing:
  /// - swift run avtools rotate --input ./assets/video.mov --output rv.mov --angle 180
  struct RotateCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "rotate",
      abstract: "Rotate an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Angle to rotate in degrees")
    var angle: Double

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      print("naturalSize size: \(assetSource.naturalSize)")

      let rotateOperation = RotateOperation(assetSource: assetSource, angle: angle)
      if let editContext = try await rotateOperation.run() {
        let exporter = AVExporter(editContext: editContext)
        do {
          try await exporter.export(outputURL: options.output)
        } catch {
          print("Export failed: \(error.localizedDescription)")
        }
      }
    }
  }
}
