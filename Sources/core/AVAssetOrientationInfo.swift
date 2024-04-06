/// An enumeration that defines the orientation of an `AVAsset`.
public enum AVAssetOrientaion {
  /// The orientation where the asset is oriented upwards.
  case up
  /// The orientation where the asset is oriented downwards.
  case down
  /// The orientation where the asset is oriented to the left.
  case left
  /// The orientation where the asset is oriented to the right.
  case right
}

/// A structure that contains information about the orientation of an `AVAsset`.
public struct AVAssetOrientationInfo {
  /// The orientation of the asset.
  let orientation: AVAssetOrientaion
  /// A Boolean value that indicates whether the asset is in portrait mode.
  let isPortrait: Bool
}
