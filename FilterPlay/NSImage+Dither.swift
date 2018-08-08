
//
//  File:       NSImage+Dither.swift
//  Project:    FilterPlay

import AppKit
import Foundation

public extension NSImage {

  // MARK: - DitherMethod -

  ///  2D Dither Methods
  ///  - Atkinson:
  ///  - FloydSteinberg:
  ///  - Burkes:
  ///  - Sierra:
  ///  - SierraTwoRow:
  ///  - SierraLite:
  ///  - Stucki:
  ///  - JarvisJudiceNinke:
  public enum Dither {
    case atkinson, floydSteinberg, burkes
    case sierra, sierraTwoRow, sierraLite
    case stucki, jarvisJudiceNinke, none

    ///  Divisor to be used with dither offsets
    ///  - returns: Integer divisor
    internal func divisor() -> Int {
      switch self {
      case .atkinson: return 8
      case .floydSteinberg: return 16
      case .burkes: return 32
      case .sierra: return 32
      case .sierraTwoRow: return 16
      case .sierraLite: return 4
      case .stucki: return 42
      case .jarvisJudiceNinke: return 48
      default: return 0
      }
    }

    /// Array containing all dither methods, excludes None
    public static var allValues: [Dither] = [
      .atkinson, .floydSteinberg, .burkes,
      .sierra, .sierraTwoRow, .sierraLite,
      .stucki, .jarvisJudiceNinke,
    ]

    ///  Matrix to stored dither offsets and the error ratio
    internal struct Matrix {
      let row: Int
      let column: Int
      let ratio: Int
    }

    private static let AtkinsonMatrix = [
      Matrix(row: 0, column: 1, ratio: 1),
      Matrix(row: 0, column: 2, ratio: 1),
      Matrix(row: 1, column: -1, ratio: 1),
      Matrix(row: 1, column: 0, ratio: 1),
      Matrix(row: 1, column: 1, ratio: 1),
      Matrix(row: 2, column: 0, ratio: 1),
    ]

    private static let FloydSteinbergMatrix = [
      Matrix(row: 0, column: 1, ratio: 7),
      Matrix(row: 1, column: -1, ratio: 3),
      Matrix(row: 1, column: 0, ratio: 5),
      Matrix(row: 1, column: 1, ratio: 1),
    ]

    private static let BurkesMatrix = [
      Matrix(row: 0, column: 1, ratio: 8),
      Matrix(row: 0, column: 2, ratio: 4),
      Matrix(row: 1, column: -2, ratio: 2),
      Matrix(row: 1, column: -1, ratio: 4),
      Matrix(row: 1, column: 0, ratio: 8),
      Matrix(row: 1, column: 1, ratio: 4),
      Matrix(row: 1, column: 2, ratio: 2),
    ]

    private static let SierraMatrix = [
      Matrix(row: 0, column: 1, ratio: 5),
      Matrix(row: 0, column: 2, ratio: 3),
      Matrix(row: 1, column: -2, ratio: 2),
      Matrix(row: 1, column: -1, ratio: 4),
      Matrix(row: 1, column: 0, ratio: 5),
      Matrix(row: 1, column: 1, ratio: 4),
      Matrix(row: 1, column: 2, ratio: 2),
      Matrix(row: 2, column: -1, ratio: 2),
      Matrix(row: 2, column: 0, ratio: 3),
      Matrix(row: 2, column: 1, ratio: 2),
    ]

    private static let SierraTwoRowMatrix = [
      Matrix(row: 0, column: 1, ratio: 4),
      Matrix(row: 0, column: 2, ratio: 3),
      Matrix(row: 1, column: -2, ratio: 1),
      Matrix(row: 1, column: -1, ratio: 2),
      Matrix(row: 1, column: 0, ratio: 3),
      Matrix(row: 1, column: 1, ratio: 2),
      Matrix(row: 1, column: 2, ratio: 1),
    ]

    private static let SierraLiteMatrix = [
      Matrix(row: 0, column: 1, ratio: 2),
      Matrix(row: 1, column: -1, ratio: 1),
      Matrix(row: 1, column: 0, ratio: 1),
    ]

    private static let StuckiMatrix = [
      Matrix(row: 0, column: 1, ratio: 8),
      Matrix(row: 0, column: 2, ratio: 4),
      Matrix(row: 1, column: -2, ratio: 2),
      Matrix(row: 1, column: -1, ratio: 4),
      Matrix(row: 1, column: 0, ratio: 8),
      Matrix(row: 1, column: 1, ratio: 4),
      Matrix(row: 1, column: 2, ratio: 2),
      Matrix(row: 2, column: -2, ratio: 1),
      Matrix(row: 2, column: -1, ratio: 2),
      Matrix(row: 2, column: 0, ratio: 4),
      Matrix(row: 2, column: 1, ratio: 2),
      Matrix(row: 2, column: 2, ratio: 1),
    ]

    private static let JarvisJudiceNinkeMatrix = [
      Matrix(row: 0, column: 1, ratio: 7),
      Matrix(row: 0, column: 2, ratio: 5),
      Matrix(row: 1, column: -2, ratio: 3),
      Matrix(row: 1, column: -1, ratio: 5),
      Matrix(row: 1, column: 0, ratio: 7),
      Matrix(row: 1, column: 1, ratio: 5),
      Matrix(row: 1, column: 2, ratio: 3),
      Matrix(row: 2, column: -2, ratio: 1),
      Matrix(row: 2, column: -1, ratio: 3),
      Matrix(row: 2, column: 0, ratio: 5),
      Matrix(row: 2, column: 1, ratio: 3),
      Matrix(row: 2, column: 2, ratio: 1),
    ]

    internal func matrix() -> [Matrix] {
      switch self {
      case .atkinson: return Dither.AtkinsonMatrix
      case .floydSteinberg: return Dither.FloydSteinbergMatrix
      case .burkes: return Dither.BurkesMatrix
      case .sierra: return Dither.SierraMatrix
      case .sierraTwoRow: return Dither.SierraTwoRowMatrix
      case .sierraLite: return Dither.SierraLiteMatrix
      case .stucki: return Dither.StuckiMatrix
      case .jarvisJudiceNinke: return Dither.JarvisJudiceNinkeMatrix
      default: return []
      }
    }
  }

  // MARK: - dither function -

  ///  Dither NSImage to improve clarity with low color or low resolution
  ///  - parameter method: optional DitherMethod type
  ///  - returns: new optional NSImage
  public func dither(_ method: Dither = .jarvisJudiceNinke) -> NSImage? {
    // Retrieve method divisor & matrix
    let divisor = method.divisor()
    let matrix = method.matrix()

    // Dimensions
    let width = Int(size.width)
    let height = Int(size.height)

    /* Calculate error to add to matrix values & curb UInt8 overflow */
    func addError(component: UInt8, pixelError: UInt8, ratio: Int) -> UInt8 {
      let _component = Int(component)
      let _pixelError = Int(pixelError)
      let apportionedError = _pixelError * ratio / divisor
      return UInt8(_component + apportionedError > 255 ? 255 : _component + apportionedError)
    }

    /* Subtract Dither from current component & curb UInt8 underflow */
    func subtractDither(component: UInt8, dither: UInt8) -> UInt8 {
      return Int(component) - Int(dither) < 0 ? 0 : component - dither
    }

    /* Distribute error to matrix color components */
    func distributeError(pixel: Pixel, pixelError: Pixel, ratio: Int) -> Pixel {
      return Pixel(
        red: addError(component: pixel.red, pixelError: pixelError.red, ratio: ratio),
        green: addError(component: pixel.green, pixelError: pixelError.green, ratio: ratio),
        blue: addError(component: pixel.blue, pixelError: pixelError.blue, ratio: ratio),
        alpha: pixel.alpha)
    }

    /* Calculate the dither for the current pixel */
    func calculateDither(pixel: Pixel) -> Pixel {
      return Pixel(red: pixel.red < 128 ? 0 : 255,
                   green: pixel.green < 128 ? 0 : 255,
                   blue: pixel.blue < 128 ? 0 : 255,
                   alpha: pixel.alpha)
    }

    /* Calculate Error by substracting dither from current color components */
    func calculateError(current: Pixel, dither: Pixel) -> Pixel {
      return Pixel(red: subtractDither(component: current.red, dither: dither.red),
                   green: subtractDither(component: current.green, dither: dither.green),
                   blue: subtractDither(component: current.blue, dither: dither.blue),
                   alpha: current.alpha)
    }

    // calculate memory offset
    func offset(row: Int, column: Int) -> Int {
      return row * width + column
    }

    /* Create a 2D pixel Array for dither pixel processing */
    guard let pixelArray = self.pixelArray() else { return nil }

    /* Loop through each pixel and apply dither */
    for y in 0 ..< height {
      for x in 0 ..< width {
        let currentOffset = offset(row: y, column: x)
        let currentColor = pixelArray[currentOffset]
        let ditherColor = calculateDither(pixel: currentColor)
        let errorColor = calculateError(current: currentColor, dither: ditherColor)

        /* Dither Current Pixel */
        pixelArray[currentOffset] = ditherColor

        /* Apply Error To Matrix Pixels */
        for neighbor in matrix {
          let row = y + neighbor.row
          let column = x + neighbor.column

          // Bounds check
          guard row >= 0 && row < height && column >= 0 && column < width else { continue }

          let neighborOffset = offset(row: row, column: column)
          let neighborColor = pixelArray[neighborOffset]
          pixelArray[neighborOffset] = distributeError(
            pixel: neighborColor,
            pixelError: errorColor,
            ratio: neighbor.ratio)
        }
      }
    }

    /* Recomposite image from pixelArray */
    return NSImage.recomposite(pixelData: pixelArray, size: size)
  }
}
