import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools overlay-image --input video.mov --image cat.png --start 1.0 --duration 2.0 --output video_with_overlay.mov
  /// testing:
  /// - swift run avtools overlay-image --input ./assets/video.mov --image ./assets/cat.png --start 1.0 --duration 2.0 --output video_with_overlay.mov
  struct OverlayImageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "overlay-image",
      abstract: "Overlay an image on a video"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Image file path", transform: URL.init(fileURLWithPath:))
    var image: URL

    @Option(help: "Start time in seconds", transform: CMTime.init(from:))
    var start: CMTime

    @Option(help: "Duration in seconds", transform: CMTime.init(from:))
    var duration: CMTime

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      print("naturalSize size: \(assetSource.naturalSize)")

      let operation = OverlayImageOperation(assetSource: assetSource, overlayImage: image, start: start, duration: duration)
      if let editContext = try await operation.run() {
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
