import ArgumentParser
import AVFoundation
import CMTimeUtils

extension AVTools {
  /// avtools trim --input video.mov --output t2.mov --start 2 --end 4
  /// testing:
  /// - swift run avtools trim --input ./assets/video.mov --output t2.mov --start 2 --end 4
  struct TrimCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "trim",
      abstract: "Trim an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(help: "Start time in seconds", transform: CMTime.init(from:))
    var start: CMTime

    @Option(help: "End time in seconds", transform: CMTime.init(from:))
    var end: CMTime

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      try await assetSource.load()
      do {
        let trimmer = AVTrimmer(assetSource: assetSource)
        try await trimmer.trim(start: start, end: end, output: options.output)
      } catch {
        print("Trim failed: \(error.localizedDescription)")
      }
    }
  }
}
