import AVFoundation

/// A source for managing and manipulating AVAssets.
///
/// This class provides functionalities to load and manipulate media assets using AVFoundation.
public class AVAssetSource {
  /// The underlying AVAsset.
  private(set) var asset: AVAsset
  /// The duration of the asset.
  private(set) var duration: CMTime = .zero
  /// The natural size of the asset.
  private(set) var naturalSize: CGSize = .zero
  /// The preferred transform of the asset.
  private(set) var preferredTransform: CGAffineTransform = .identity

  /// Information about the orientation of the asset.
  public var orientationInfo: AVAssetOrientationInfo {
    let (orientation, isPortrait) = orientationFromTransform(preferredTransform)
    return AVAssetOrientationInfo(orientation: orientation, isPortrait: isPortrait)
  }

  /// Initializes a new `AVAssetSource` with the specified URL.
  ///
  /// This initializer creates an `AVURLAsset` with the given URL and sets the `AVURLAssetPreferPreciseDurationAndTimingKey` option to `true` to prefer precise duration and timing information.
  ///
  /// - Parameter url: The URL of the asset to be loaded.
  public init(url: URL) {
    asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
  }

  /// Initializes a new `AVAssetSource` with an existing `AVAsset`.
  ///
  /// This initializer allows for the creation of an `AVAssetSource` instance using a pre-existing `AVAsset`. This can be useful when you already have an `AVAsset` instance and wish to utilize the functionalities provided by `AVAssetSource`.
  ///
  /// - Parameter asset: The `AVAsset` to be used for initializing the `AVAssetSource`.
  public init(asset: AVAsset) {
    self.asset = asset
  }

  /// Asynchronously loads the asset's properties such as duration and tracks.
  ///
  /// This method initiates an asynchronous operation to load the essential properties of the asset, specifically its duration and tracks. If the asset contains a video track, it further loads specific properties like the duration of the video track, its natural size, and the preferred transform.
  ///
  /// - Parameter completion: A closure that is called upon completion of the loading operation. It receives an optional `NSError` object that indicates whether the operation was successful. A `nil` value indicates success.
  ///
  /// - Note: This method is deprecated and no longer supported as of macOS 13.0.
  @available(macOS, introduced: 10.0, deprecated: 13.0, message: "This method is no longer supported.")
  public func load(completion: @escaping (NSError?) -> Void) {
    asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) { [weak self] in
      guard let self = self else {
        completion(nil)
        return
      }

      var error: NSError?
      let trackStatus = asset.statusOfValue(forKey: "tracks", error: &error)
      if trackStatus != .loaded {
        completion(error)
      }

      let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
      if durationStatus != .loaded {
        completion(error)
      }

      if let videoTrack = self.tracks(for: .video).first {
        self.duration = videoTrack.timeRange.duration
        self.naturalSize = videoTrack.naturalSize
        self.preferredTransform = videoTrack.preferredTransform
      } else {
        self.duration = asset.duration
      }

      completion(nil)
    }
  }

  /// Asynchronously loads asset properties required for editing operations using the async/await pattern.
  ///
  /// This method asynchronously loads essential properties of the asset such as tracks and duration. If the asset contains a video track, it further loads specific properties like timeRange, naturalSize, and preferredTransform for that video track.
  ///
  /// - Throws: An error if loading any of the asset properties fails.
  @available(macOS 13, *)
  public func load() async throws {
    let (tracks, duration) = try await asset.load(.tracks, .duration)
    if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
      let timeRange = try await videoTrack.load(.timeRange)
      self.duration = timeRange.duration
      self.naturalSize = try await videoTrack.load(.naturalSize)
      let preferredTransform = try await videoTrack.load(.preferredTransform)
      self.preferredTransform = preferredTransform
    } else {
      self.duration = duration
    }
  }

  /// Retrieves all tracks of the specified media type from the asset.
  ///
  /// This method returns an array of `AVAssetTrack` objects that match the specified media type.
  /// It synchronously fetches the tracks associated with the `AVAsset` instance.
  ///
  /// - Parameter mediaType: The media type for which tracks are to be retrieved.
  /// - Returns: An array of `AVAssetTrack` objects.
  @available(macOS, introduced: 10.0, deprecated: 13.0, message: "This method is no longer supported.")
  func tracks(for mediaType: AVMediaType) -> [AVAssetTrack] {
    return asset.tracks(withMediaType: mediaType)
  }

  /// Fetches tracks of a specified media type asynchronously.
  ///
  /// This method asynchronously retrieves all tracks of the specified media type from the asset.
  ///
  /// - Parameter mediaType: The media type for which tracks are to be retrieved.
  /// - Returns: An array of `AVAssetTrack` objects that match the specified media type.
  @available(macOS 13, *)
  func tracks(for mediaType: AVMediaType) async -> [AVAssetTrack] {
    let tracks = (try? await asset.load(.tracks)) ?? []
    return tracks.filter { $0.mediaType == mediaType }
  }

  /// Determines the orientation and if the asset is in portrait mode from its transform.
  ///
  /// This method examines the given `CGAffineTransform` to determine the asset's orientation and whether it is in portrait mode.
  ///
  /// - Parameter transform: The `CGAffineTransform` applied to the asset.
  /// - Returns: A tuple containing the asset's orientation and a Boolean indicating if it is in portrait mode.
  func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: AVAssetOrientaion, isPortrait: Bool) {
    let t = transform
    var assetOrientation = AVAssetOrientaion.up
    var isPortrait = false

    if t.a == 0, t.b == 1.0, t.c == -1.0, t.d == 0 { // Portrait
      assetOrientation = .up
      isPortrait = true
    } else if t.a == 0, t.b == -1.0, t.c == 1.0, t.d == 0 { // PortraitUpsideDown
      assetOrientation = .down
      isPortrait = true
    } else if t.a == 1.0, t.b == 0, t.c == 0, t.d == 1.0 { // LandscapeRight
      assetOrientation = .right
    } else if t.a == -1.0, t.b == 0, t.c == 0, t.d == -1.0 { // LandscapeLeft
      assetOrientation = .left
    } else {
      assetOrientation = .up
      isPortrait = true
    }
    return (assetOrientation, isPortrait)
  }

  /// Calculates the transform and new size for a rotation operation.
  /// Calculates the transform and new size for a rotation operation based on the given angle and the original size of the asset.
  /// - Parameters:
  ///   - angle: The angle in degrees by which the asset is to be rotated.
  ///   - originalSize: The original size of the asset before rotation.
  /// - Returns: A tuple containing the transform and the new size of the asset after rotation.
  func transformAndSizeForRotation(angle: Double, originalSize: CGSize) -> (transform: CGAffineTransform, newSize: CGSize) {
    let radians = angle * Double.pi / 180
    var transform: CGAffineTransform
    var newSize: CGSize

    switch angle.truncatingRemainder(dividingBy: 360) {
    case 90, -270:
      transform = CGAffineTransform(translationX: originalSize.height, y: 0.0).rotated(by: radians)
      newSize = CGSize(width: originalSize.height, height: originalSize.width)
    case 180, -180:
      transform = CGAffineTransform(translationX: originalSize.width, y: originalSize.height).rotated(by: radians)
      newSize = originalSize
    case 270, -90:
      transform = CGAffineTransform(translationX: 0.0, y: originalSize.width).rotated(by: radians)
      newSize = CGSize(width: originalSize.height, height: originalSize.width)
    default: // 0 degrees and other cases
      transform = CGAffineTransform(rotationAngle: radians)
      newSize = originalSize
    }

    return (transform, newSize)
  }
}
