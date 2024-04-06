import ArgumentParser
import Foundation

import ArgumentParser
import Foundation

/// A structure that defines common options for command-line parsing.
///
/// This structure uses the `ParsableCommand` protocol from the ArgumentParser library to define common options that can be used across different commands in the AVTools utility. It includes options for specifying input and output file or folder paths.
struct CommonOptions: ParsableCommand {
  /// The input file or folder path.
  ///
  /// This option allows the user to specify the path to the input file or folder. The path is transformed into a URL object.
  @Option(help: "Input file or folder path", transform: URL.init(fileURLWithPath:))
  var input: URL

  /// The output file or folder path.
  ///
  /// This option allows the user to specify the path to the output file or folder. The path is transformed into a URL object.
  @Option(help: "Output file or folder path", transform: URL.init(fileURLWithPath:))
  var output: URL
}

/// The main structure for the AVTools command-line utility.
///
/// This structure defines the AVTools utility, including its name, abstract description, and the subcommands it supports. It uses the `AsyncParsableCommand` protocol from the ArgumentParser library to enable asynchronous command execution.
@main
struct AVTools: AsyncParsableCommand {
  /// The configuration for the AVTools command-line utility.
  ///
  /// This configuration includes the command name, an abstract description of the utility, and a list of subcommands that the utility supports. Each subcommand corresponds to a specific operation that can be performed by the utility, such as rotating a video, extracting audio, and more.
  static var configuration = CommandConfiguration(
    commandName: "avtools",
    abstract: "avtools, a comprehensive command-line utility, facilitates a variety of audio and video processing tasks including rotation, extraction, splitting, merging, cropping, speed modification, and overlaying of sound, images, and text.",
    subcommands: [
      RotateCommand.self,
      ExtractVideoCommand.self,
      ExtractAudioCommand.self,
      SplitCommand.self,
      MergeCommand.self,
      CropCommand.self,
      ImageToVideoCommand.self,
      TrimCommand.self,
      SpeedCommand.self,
      OverlaySoundCommand.self,
      OverlayImageCommand.self,
      OverlayTextCommand.self,
      GenerateImagesCommand.self,
    ]
  )
}
