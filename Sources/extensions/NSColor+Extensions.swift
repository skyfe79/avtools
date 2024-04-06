import Cocoa
import Foundation

extension NSColor {
  /// Creates an `NSColor` object from a hexadecimal color code.
  ///
  /// This initializer allows you to specify a color using a hexadecimal string. The string must start with a `#` and be exactly eight characters long, representing the red, green, blue, and alpha values in that order. Each pair of characters represents a value between 00 and FF (in hexadecimal notation), which corresponds to a decimal value between 0 and 255.
  ///
  /// If the string does not meet these criteria, the initializer will default to creating a white color.
  ///
  /// - Parameter hex: A `String` representing the hexadecimal color code.
  /// - SeeAlso: [How to convert a hex color to a UIColor](https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-hex-color-to-a-uicolor)
  convenience init(hex: String) {
    let r, g, b, a: CGFloat

    if hex.hasPrefix("#") {
      let start = hex.index(hex.startIndex, offsetBy: 1)
      let hexColor = String(hex[start...])

      if hexColor.count == 8 {
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
          r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
          g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
          b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
          a = CGFloat(hexNumber & 0x0000_00FF) / 255
          self.init(red: r, green: g, blue: b, alpha: a)
          return
        }
      }
    }
    self.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  }
}
