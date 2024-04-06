import AVFoundation
import CoreImage
import Foundation

/// A class that performs a cropping operation on an audiovisual asset.
///
/// `CropOperation` conforms to `AVOperation` and is responsible for cropping an audiovisual asset to a specified rectangle.
class CropOperation: AVOperation {
  private let assetSource: AVAssetSource
  private let cropRect: CGRect

  /// Initializes a new crop operation with the specified asset source and crop rectangle.
  ///
  /// - Parameters:
  ///   - assetSource: The source of the AV asset to be cropped.
  ///   - cropRect: The rectangle to which the asset will be cropped.
  init(assetSource: AVAssetSource, cropRect: CGRect) {
    self.assetSource = assetSource
    self.cropRect = cropRect
  }

  /// Runs the crop operation asynchronously.
  ///
  /// This method creates a composition and a video composition, then returns an `AVAssetEditContext` containing these compositions.
  ///
  /// - Throws: An error if the operation cannot be completed.
  /// - Returns: An optional `AVAssetEditContext` object representing the result of the operation.
  func run() async throws -> AVAssetEditContext? {
    let composition = await createComposition()
    let videoComposition = await createVideoComposition()
    return AVAssetEditContext(composition: composition, videoComposition: videoComposition)
  }

  /// Creates an `AVComposition` from the asset source.
  ///
  /// This method asynchronously adds video and audio tracks from the asset source to a new composition.
  ///
  /// - Returns: An `AVComposition` containing the video and audio tracks.
  func createComposition() async -> AVComposition {
    let composition = AVMutableComposition()

    if let videoTrack = await assetSource.tracks(for: .video).first {
      let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? videoCompositionTrack?.insertTimeRange(assetSource.duration.range, of: videoTrack, at: .zero)
    }

    if let audioTrack = await assetSource.tracks(for: .audio).first {
      let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      try? audioCompositionTrack?.insertTimeRange(assetSource.duration.range, of: audioTrack, at: .zero)
    }

    return composition
  }

  /// Creates an `AVVideoComposition` applying a crop filter to the asset.
  ///
  /// This method asynchronously applies a Core Image crop filter to the video track of the asset, according to the specified `cropRect`.
  ///
  /// - Returns: An optional `AVVideoComposition` with the crop filter applied.
  func createVideoComposition() async -> AVVideoComposition? {
    let videoComposition = AVMutableVideoComposition(asset: assetSource.asset, applyingCIFiltersWithHandler: { [cropRect] request in
      guard let cropFilter = CIFilter(name: "CICrop") else { return }
      cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
      cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
      let imageAtOrigin = cropFilter.outputImage!.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))
      request.finish(with: imageAtOrigin, context: nil)
    })
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.renderSize = cropRect.size
    return videoComposition
  }
}
