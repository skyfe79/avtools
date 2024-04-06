import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools overlay-sound --input video.mov --sound bgm.mp3 --output video_with_sound.mov
  /// testing:
  /// - swift run avtools overlay-sound --input ./assets/video.mov --sound ./assets/bgm.mp3 --output video_with_sound.mov
  struct OverlaySoundCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "overlay-sound",
      abstract: "Overlay sound on an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Sound file path", transform: URL.init(fileURLWithPath:))
    var sound: URL

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      let overlaySoundOperation = OverlaySoundOperation(assetSource: assetSource, soundURL: sound)
      if let editContext = try await overlaySoundOperation.run() {
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
