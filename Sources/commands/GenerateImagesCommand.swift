import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools generate-images --input video.mov --output images --times 1.0 2.0 3.0
  /// avtools generate-images --input video.mov --output images --stride 1.0
  /// testing:
  /// - swift run avtools generate-images --input ./assets/video.mov --output images --times 1.0 2.0 3.0
  /// - swift run avtools generate-images --input ./assets/video.mov --output images --stride 1.0
  struct GenerateImagesCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
      commandName: "generate-images",
      abstract: "Generate images from an asset"
    )

    @OptionGroup
    var options: CommonOptions

    @Option(parsing: .upToNextOption, help: "Times in seconds", transform: CMTime.init(from:))
    var times: [CMTime] = []

    @Option(help: "Stride in seconds")
    var stride: Double?

    lazy var assetSource: AVAssetSource = .init(url: options.input)

    mutating func run() async throws {
      do {
        try await assetSource.load()
        let generateImagesOperation = GenerateImagesOperation(assetSource: assetSource, times: times, stride: stride, outputURL: options.output)
        try await generateImagesOperation.run()
        print("Images generated at: \(options.output.path)")
      } catch {
        print("Generate images failed: \(error.localizedDescription)")
      }
    }
  }
}
