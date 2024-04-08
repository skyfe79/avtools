import AVFoundation
import CMTimeUtils
import Cocoa
import CoreGraphics
import QuartzCore

/// A class responsible for overlaying text onto a video.
///
/// This operation takes an `AVAssetSource`, text, font size, and color as input. It overlays the specified text onto the video track of the asset source.
class OverlayTextOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let text: String
  private let fontSize: Double
  private let color: NSColor

  /// Initializes a new instance with the specified parameters.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to overlay the text onto.
  ///   - text: The text to overlay.
  ///   - fontSize: The font size of the text.
  ///   - color: The color of the text.
  init(assetSource: AVAssetSource, text: String, fontSize: Double, color: NSColor) {
    self.assetSource = assetSource
    self.text = text
    self.fontSize = fontSize
    self.color = color
  }

  /// Executes the overlay operation asynchronously.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVComposeContext` object representing the result of the operation.
  func run() async throws -> AVComposeContext? {
    let (composition, videoComposition) = await createComposition()
    return AVComposeContext(composition: composition, videoComposition: videoComposition)
  }

  /// Creates a composition and a video composition for the overlay operation.
  ///
  /// This method asynchronously adds video and audio tracks from the asset source to a new composition and creates a video composition for the overlay.
  ///
  /// - Returns: A tuple containing an `AVComposition` and an optional `AVVideoComposition`.
  func createComposition() async -> (AVComposition, AVVideoComposition?) {
    let composition = AVMutableComposition()
    var videoComposition: AVVideoComposition?

    if let videoTrack = await assetSource.tracks(for: .video).first {
      let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionVideoTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
      videoComposition = createVideoCompositon(for: compositionVideoTrack)
    }

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? compositionAudioTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    return (composition, videoComposition)
  }

  /// Creates a video composition for the overlay operation.
  ///
  /// This method configures the video composition with the necessary instructions and animations to overlay the specified text onto the video track.
  ///
  /// - Parameter videoTrack: The video track to overlay the text onto.
  /// - Returns: An optional `AVVideoComposition` configured for the overlay.
  func createVideoCompositon(for videoTrack: AVCompositionTrack?) -> AVVideoComposition? {
    guard let videoTrack = videoTrack else { return nil }
    let videoComposition = AVMutableVideoComposition()
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

    let orientationInfo = assetSource.orientationInfo
    if orientationInfo.isPortrait {
      let (transform, size) = assetSource.transformAndSizeForRotation(angle: 90, originalSize: assetSource.naturalSize)
      layerInstruction.setTransform(transform, at: .zero)
      videoComposition.renderSize = size
    } else {
      let (transform, size) = assetSource.transformAndSizeForRotation(angle: 0, originalSize: assetSource.naturalSize)
      layerInstruction.setTransform(transform, at: .zero)
      videoComposition.renderSize = size
    }
    videoComposition.animationTool = createOverlayTextAnimationTool(renderSize: videoComposition.renderSize)

    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    videoCompositionInstruction.timeRange = assetSource.duration.range
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    return videoComposition
  }

  /// Creates an animation tool for the overlay text.
  ///
  /// This method configures the overlay text with fade-in animation for the specified render size.
  ///
  /// - Parameter renderSize: The size of the render area for the overlay.
  /// - Returns: An `AVVideoCompositionCoreAnimationTool` configured with the overlay text and animation.
  func createOverlayTextAnimationTool(renderSize: CGSize) -> AVVideoCompositionCoreAnimationTool {
    let fontSize = scaledFontSize(for: renderSize, baseFontSize: fontSize)
    let textLayer = CATextLayer()
    textLayer.string = text
    textLayer.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
    textLayer.fontSize = fontSize
    textLayer.foregroundColor = color.cgColor
    textLayer.alignmentMode = .center
    textLayer.frame = CGRect(origin: .zero, size: textLayer.preferredFrameSize())
    textLayer.position = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
    // When using CATextLayer in CLI, it's mandatory to call the display() method.
    // Otherwise, the background is rendered but the text is not.
    textLayer.display()

    let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
    fadeInAnimation.fromValue = 0.0
    fadeInAnimation.toValue = 1.0
    fadeInAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    fadeInAnimation.duration = 1
    fadeInAnimation.isRemovedOnCompletion = false
    fadeInAnimation.fillMode = .forwards
    textLayer.add(fadeInAnimation, forKey: "showText")

    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: renderSize)

    let parentLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: renderSize)
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(textLayer)

    return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
  }

  /// Calculates the scaled font size based on the render size and a base font size.
  ///
  /// - Parameters:
  ///   - renderSize: The size of the render area.
  ///   - baseFontSize: The base font size to scale from.
  ///   - scaleFactor: The factor by which to scale the font size.
  /// - Returns: The scaled font size.
  func scaledFontSize(for renderSize: CGSize, baseFontSize: CGFloat = 18.0, scaleFactor: CGFloat = 0.05) -> CGFloat {
    let videoWidth = renderSize.width
    let scaledFontSize = baseFontSize + (videoWidth * scaleFactor)
    return scaledFontSize
  }
}
