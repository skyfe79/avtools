import ArgumentParser
import AVFoundation

extension AVTools {
  /// avtools merge --input splits --output merged2.mov
  /// testing:
  /// - swift run avtools merge --input ./assets/splits --output merged2.mov
  struct MergeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "merge",
      abstract: "Merge assets"
    )

    @OptionGroup
    var options: CommonOptions

    mutating func run() async throws {
      let mergeOperation = MergeOperation(inputURL: options.input)
      if let editContext = try await mergeOperation.run() {
        let exporter = AVExporter(editContext: editContext)
        do {
          try await exporter.export(outputURL: options.output, outputFileType: .mov, presetName: AVAssetExportPresetHighestQuality)
        } catch {
          print("Export failed: \(error.localizedDescription)")
        }
      }
    }
  }
}
