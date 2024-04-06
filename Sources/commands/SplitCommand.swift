import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools split --input video.mov --output splitted_videos --duration 1.0
  /// testing:
  /// - swift run avtools split --input ./assets/video.mov --output splitted_videos --duration 1.0
  struct SplitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "split",
      abstract: "Split asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Duration in seconds")
    var duration: Double

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      do {
        try await assetSource.load()
        let splitOperation = SplitOperation(assetSource: assetSource, duration: duration, outputURL: options.output)
        let _ = try await splitOperation.run()
        print("Split completed: \(options.output.path)")
      } catch {
        print("Split failed: \(error.localizedDescription)")
      }
    }
  }
}
