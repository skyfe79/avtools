import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools images-to-video --images-folder images --duration 1.5 --output iv2.mov
  /// testing:
  /// - swift run avtools images-to-video --images-folder ./assets/images --duration 1.5 --output iv2.mov
  struct ImageToVideoCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
      commandName: "images-to-video",
      abstract: "Convert an images to a video"
    )

    @Option(help: "Folder path containing the images", transform: URL.init(fileURLWithPath:))
    var imagesFolder: URL

    @Option(help: "Duration of each frame in seconds")
    var duration: Double

    @Option(help: "Output file path", transform: URL.init(fileURLWithPath:))
    var output: URL

    mutating func run() async throws {
      let imageToVideoOperation = ImagesToVideoOperation(imagesFolder: imagesFolder, outputURL: output, frameDuration: duration)
      do {
        try await imageToVideoOperation.run()
        print("Images converted to video: \(output.path)")
      } catch {
        print("Failed to convert images to video: \(error.localizedDescription)")
      }
    }
  }
}
