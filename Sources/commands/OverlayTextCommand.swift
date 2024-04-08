import ArgumentParser
import AVFoundation
import Cocoa

extension AVTools {
  /// avtools overlay-text --input video.mov --output ot3.mov --text 'Hello World' --color '#FF5733FF'
  /// testing:
  /// - swift run avtools overlay-text --input ./assets/video.mov --output ot3.mov --text 'Hello World' --color '#FF5733FF'
  struct OverlayTextCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "overlay-text",
      abstract: "Overlay text on a video"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Text to overlay")
    var text: String

    @Option(help: "Font size, default is 18")
    var size: Double = 18.0

    @Option(help: "Font color in hexadecimal format, default is white", transform: NSColor.init(hex:))
    var color: NSColor = .white

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      let overlayTextOperation = OverlayTextOperation(assetSource: assetSource, text: text, fontSize: size, color: color)
      if let composeContext = try await overlayTextOperation.run() {
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
