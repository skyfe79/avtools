import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools speed --input video.mov --output s1.mov --speed 3.0
  /// avtools speed --input video.mov --output s2.mov --speed 0.5
  /// testing:
  /// - swift run avtools speed --input ./assets/video.mov --output s1.mov --speed 3.0
  /// - swift run avtools speed --input ./assets/video.mov --output s2.mov --speed 0.5
  struct SpeedCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "speed",
      abstract: "Change the speed of an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Speed factor")
    var speed: Double

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      let speedOperation = SpeedOperation(assetSource: assetSource, speed: speed)
      if let editContext = try await speedOperation.run() {
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
