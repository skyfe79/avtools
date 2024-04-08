import AppKit
import AVFoundation

/// A class that converts a sequence of images into a video file.
///
/// This class takes a folder of images and combines them into a single video file. It supports basic video settings such as frame duration and output format.
class ImagesToVideoOperation: AVOperation {
  private let imagesFolder: URL
  private let outputURL: URL
  private let frameDuration: TimeInterval
  private var imageSize: CGSize = .zero
  private let framesPerSecond = 30

  /// Initializes a new instance with the specified parameters.
  ///
  /// - Parameters:
  ///   - imagesFolder: The `URL` of the folder containing the images to be converted.
  ///   - outputURL: The `URL` where the output video file will be saved.
  ///   - frameDuration: The duration of each frame in the video.
  init(imagesFolder: URL, outputURL: URL, frameDuration: TimeInterval) {
    self.imagesFolder = imagesFolder
    self.outputURL = outputURL
    self.frameDuration = frameDuration
  }

  /// Determines the size of the images to set the video size accordingly.
  ///
  /// Assumes all images are of the same size and uses the size of the first image as the video size.
  /// - Throws: An error if no images are found or the first image cannot be loaded.
  private func figureoutImageSize() throws { 
    do {
      let images = try loadImages(from: imagesFolder)
      if let firstImageURL = images.first, let image = NSImage(contentsOf: firstImageURL) {
        imageSize = CGSize(width: image.size.width, height: image.size.height)
      } else {
        throw "No images found or could not load the first image."
      }
    } catch {
      throw "Failed to load images: \(error)"
    }
  }

  /// Executes the operation to generate a video from the images.
  ///
  /// - Returns: An optional `AVComposeContext` object representing the result of the operation. Currently, this method always returns `nil`.
  /// - Throws: An error if the image size cannot be determined or the video cannot be written.
  @discardableResult
  func run() async throws -> AVComposeContext? {
    try figureoutImageSize()
    guard imageSize != .zero else {
      throw NSError(domain: "ImagesToVideoOperation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to determine image size."])
    }

    let images = try loadImages(from: imagesFolder)
    try await writeVideo(from: images)
    return nil
  }

  /// Loads the URLs of images from a specified folder.
  ///
  /// - Parameter folder: The `URL` of the folder to load images from.
  /// - Returns: An array of `URL` objects representing the images.
  /// - Throws: An error if the contents of the folder cannot be read.
  private func loadImages(from folder: URL) throws -> [URL] {
    let fileManager = FileManager.default
    let contents = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    let imageFiles = contents
      .filter { $0.pathExtension.lowercased() == "png" || $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
    return imageFiles
  }

  /// Creates a video file from an array of image URLs.
  ///
  /// - Parameter images: An array of `URL` objects representing the images to be included in the video.
  /// - Throws: An error if the video file cannot be written.
  private func writeVideo(from images: [URL]) async throws {
    try? FileManager.default.removeItem(at: outputURL)

    let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: imageSize.width,
      AVVideoHeightKey: imageSize.height,
    ]

    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)

    assetWriter.add(writerInput)
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: .zero)

    for (index, image) in images.enumerated() {
      guard let pixelBuffer = createPixelBuffer(from: image, size: imageSize),
            writerInput.isReadyForMoreMediaData
      else {
        continue
      }

      let frameTime = CMTime(value: Int64(index) * Int64(frameDuration * Double(framesPerSecond)), timescale: Int32(framesPerSecond))
      adaptor.append(pixelBuffer, withPresentationTime: frameTime)
    }

    await withCheckedContinuation { continuation in
      writerInput.markAsFinished()
      assetWriter.finishWriting {
        continuation.resume()
      }
    }
  }

  /// Creates a `CVPixelBuffer` from an image URL.
  ///
  /// The image is centered within the `CVPixelBuffer`.
  /// - Parameter url: The `URL` of the image to convert.
  /// - Parameter size: The `CGSize` to use for the `CVPixelBuffer`.
  /// - Returns: An optional `CVPixelBuffer` containing the image.
  private func createPixelBuffer(from url: URL, size: CGSize) -> CVPixelBuffer? {
    guard let image = NSImage(contentsOf: url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
      return nil
    }

    var pixelBuffer: CVPixelBuffer?
    let options: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]
    CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)

    guard let buffer = pixelBuffer else { return nil }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData,
                            width: Int(size.width),
                            height: Int(size.height),
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: rgbColorSpace,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    // Calculate x, y coordinates to center the image
    let dx = (size.width - CGFloat(cgImage.width)) / 2
    let dy = (size.height - CGFloat(cgImage.height)) / 2

    // Calculate the new CGRect to center the image
    let imageRect = CGRect(x: dx, y: dy, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
    context?.draw(cgImage, in: imageRect)

    return buffer
  }
}
