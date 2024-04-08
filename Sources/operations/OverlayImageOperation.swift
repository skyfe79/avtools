import AVFoundation
import CMTimeUtils
import Cocoa
import CoreImage

/// A class responsible for overlaying an image onto a video.
///
/// This operation takes an `AVAssetSource`, an image URL, a start time, and a duration as input. It overlays the specified image onto the video track of the asset source for the given duration starting at the specified start time.
class OverlayImageOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let overlayImage: URL
  private let start: CMTime
  private let duration: CMTime

  /// Initializes a new instance with the specified parameters.
  ///
  /// - Parameters:
  ///   - assetSource: The `AVAssetSource` to overlay the image onto.
  ///   - overlayImage: The `URL` of the image to overlay.
  ///   - start: The `CMTime` at which to start the overlay.
  ///   - duration: The `CMTime` duration of the overlay.
  init(assetSource: AVAssetSource, overlayImage: URL, start: CMTime, duration: CMTime) {
    self.assetSource = assetSource
    self.overlayImage = overlayImage
    self.start = start
    self.duration = duration
  }

  /// Executes the overlay operation asynchronously.
  ///
  /// This method creates a composition and a video composition, then overlays the specified image onto the video track of the asset source.
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
      let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? videoCompositionTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
      videoComposition = createVideoComposition(for: videoCompositionTrack)
    }

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? audioCompositionTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    return (composition, videoComposition)
  }

  /// Creates a video composition for the overlay operation.
  ///
  /// This method configures the video composition with the necessary instructions and animations to overlay the specified image onto the video track.
  ///
  /// - Parameter videoTrack: The video track to overlay the image onto.
  /// - Returns: An optional `AVVideoComposition` configured for the overlay.
  func createVideoComposition(for videoTrack: AVCompositionTrack?) -> AVVideoComposition? {
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

    videoComposition.animationTool = createOverlayImageAnimationTool(renderSize: videoComposition.renderSize)

    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    videoCompositionInstruction.timeRange = assetSource.duration.range
    videoCompositionInstruction.layerInstructions = [layerInstruction]

    videoComposition.instructions = [videoCompositionInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

    return videoComposition
  }

  /// Creates an animation tool for the overlay image.
  ///
  /// This method configures the overlay image with fade-in and fade-out animations for the specified render size.
  ///
  /// - Parameter renderSize: The size of the render area for the overlay.
  /// - Returns: An `AVVideoCompositionCoreAnimationTool` configured with the overlay image and animations.
  func createOverlayImageAnimationTool(renderSize: CGSize) -> AVVideoCompositionCoreAnimationTool {
    let overlayLayer = CALayer()
    if let overlayNSImage = NSImage(contentsOfFile: overlayImage.path) {
      var rect = CGRect(x: 0, y: 0, width: overlayNSImage.size.width, height: overlayNSImage.size.height)
      let cgImage = overlayNSImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
      overlayLayer.contents = cgImage
      overlayLayer.frame = rect
      overlayLayer.opacity = 0.0

      let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
      fadeInAnimation.fromValue = 0.0
      fadeInAnimation.toValue = 1.0
      fadeInAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(start)
      fadeInAnimation.duration = 1
      fadeInAnimation.isRemovedOnCompletion = false
      fadeInAnimation.fillMode = .forwards
      overlayLayer.add(fadeInAnimation, forKey: "showOverlayImage")

      let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
      fadeOutAnimation.fromValue = 1.0
      fadeOutAnimation.toValue = 0.0
      fadeOutAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(start + duration)
      fadeOutAnimation.duration = 1
      fadeOutAnimation.isRemovedOnCompletion = false
      fadeOutAnimation.fillMode = .forwards
      overlayLayer.add(fadeOutAnimation, forKey: "hideOverlayImage")
    }

    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: renderSize)

    let parentLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: renderSize)
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(overlayLayer)

    return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
  }
}
