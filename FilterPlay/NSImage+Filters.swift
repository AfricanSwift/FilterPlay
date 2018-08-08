
//
//  File:       NSImage+Filters.swift
//  Project:    FilterPlay

import AppKit

// MARK: - input validation -

private extension Double {
  func isWithinLimits() -> Bool {
    return self >= -1.0 && self <= 1.0
  }
}

// MARK: - Color Components -

public extension NSImage {
  ///  Color Components
  internal struct Components {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    private static func toUInt8(value: Double) -> UInt8 {
      return value > 1.0 ? UInt8(255) : value < 0 ? UInt8(0) : UInt8(value * 255.0)
    }

    private static func toDouble(value: UInt8) -> Double {
      return value > 255 ? 1.0 : value < 0 ? 0.0 : Double(value) / 255.0
    }

    func greaterEqualTo(_ threshold: Double) -> Bool {
      return red >= threshold && green >= threshold && blue >= threshold
    }

    init(pixel: Pixel) {
      red = Components.toDouble(value: pixel.red)
      green = Components.toDouble(value: pixel.green)
      blue = Components.toDouble(value: pixel.blue)
      alpha = Components.toDouble(value: pixel.alpha)
    }

    func toPixel() -> NSImage.Pixel {
      return NSImage.Pixel(
        red: Components.toUInt8(value: red),
        green: Components.toUInt8(value: green),
        blue: Components.toUInt8(value: blue),
        alpha: Components.toUInt8(value: alpha))
    }

    func median() -> Double {
      return (red + green + blue) / 3.0
    }
  }
}

// MARK: - Filter Transform Process -

public extension NSImage {
  internal typealias FilterTransform = (Components) -> Pixel
  ///  Convert NSImage To Grayscale
  ///  - parameter tone: Grayscale levels, default is semi
  ///  - returns: New Grayscale Instance Of NSImage
  internal func processFilterTransform(filter: FilterTransform) -> NSImage? {
    // Create a 2D pixel Array for dither pixel processing
    guard let pixelArray = self.pixelArray() else { return nil }
    let width = Int(size.width)
    let height = Int(size.height)
    for rowIndex in 0 ..< height {
      for columnIndex in 0 ..< width {
        let offset = rowIndex * width + columnIndex
        let currentColor = pixelArray[offset]
        let components = Components(pixel: currentColor)
        pixelArray[offset] = filter(components)
      }
    }
    return NSImage.recomposite(pixelData: pixelArray, size: size)
  }
}

// MARK: - Binary Filter -

public extension NSImage {
  public func filterBinary(level: Double = 1.0 / 2.0, threshold: Double = 0.0, transparent: Bool = false) -> NSImage? {
    precondition(level.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.Binary(level, threshold, transparent)
    return processFilterTransform(filter: filter)
  }
}

extension NSImage {
  // Filter formulas for single pixel adjustment
  internal struct Transform {
    // Color Black & White
    static func Binary(_ level: Double, _ threshold: Double, _ transparent: Bool) -> FilterTransform {
      return { (components: Components) -> Pixel in
        guard components.greaterEqualTo(threshold) else { return components.toPixel() }
        // Sort Black and White Pixels
        let color = components.median() > level ? 1.0 : 0.0
        let alpha = components.median() > level ? transparent ? 0 : components.alpha : components.alpha
        return Pixel(red: color, green: color, blue: color, alpha: alpha)
      }
    }
  }
}

// MARK: - Gray Tones Filter -

public extension NSImage {
  ///  Grayscale levels
  ///  - bright: All component channels set to red value
  ///  - semi:   All component channels set to blue value
  ///  - dark:   All component channels set to green value
  public enum GrayTone {
    case bright, median, dark, luminosity
    public static var allValues: [GrayTone] = [.bright, .median, .dark, .luminosity]
  }

  public func filterGray(tone: GrayTone = .median, threshold: Double = 0) -> NSImage? {
    precondition(threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.gray(tone, threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Gray Tones
  static func gray(_ tone: NSImage.GrayTone, _ threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      // Skips pixels below a value threshold
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      // Tones Are Based On Color Components,
      // Red is Brightest, Green is Semi and Blue is Dark
      let colorTone: Double

      switch tone {
      case .bright: colorTone = components.red
      case .median: colorTone = components.green
      case .dark: colorTone = components.blue
      case .luminosity: colorTone = components.median()
      }

      // Set all components to the same colorTone to effect grayscale
      return NSImage.Pixel(red: colorTone, green: colorTone, blue: colorTone, alpha: components.alpha)
    }
  }
}

// MARK: - Color Shading Filter -

public extension NSImage {
  public func filterShading(red: Double = 0.0, green: Double = 0.0, blue: Double = 0.0, threshold: Double = 0) -> NSImage? {
    precondition(red.isWithinLimits() && green.isWithinLimits() && blue.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.shading(red: red, green: green, blue: blue, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Shading
  static func shading(red: Double, green: Double, blue: Double, threshold: Double) -> NSImage.FilterTransform {
    let initial = 0.0
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      return NSImage.Pixel(
        red: red == initial ? components.red : components.red * red,
        green: green == initial ? components.green : components.green * green,
        blue: blue == initial ? components.blue : components.blue * blue,
        alpha: components.alpha)
    }
  }
}

// MARK: - Tint Filter -

public extension NSImage {
  public func filterTint(red: Double = 0.0, green: Double = 0.0, blue: Double = 0.0, threshold: Double = 0) -> NSImage? {
    precondition(red.isWithinLimits() && green.isWithinLimits() && blue.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.tint(red: red, green: green, blue: blue, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Tint
  static func tint(red: Double, green: Double, blue: Double, threshold: Double) -> NSImage.FilterTransform {
    let initial = 0.0
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else {
        return components.toPixel()
      }
      let redAdd = red > initial ? (1.0 - components.red) * red : components.red * red
      let greenAdd = green > initial ? (1.0 - components.green) * green : components.green * green
      let blueAdd = blue > initial ? (1.0 - components.blue) * blue : components.blue * blue
      return NSImage.Pixel(
        red: red == initial ? components.red : components.red + redAdd,
        green: green == initial ? components.green : components.green + greenAdd,
        blue: blue == initial ? components.blue : components.blue + blueAdd,
        alpha: components.alpha)
    }
  }
}

// MARK: - Solarize Filter -

public extension NSImage {
  public func filterSolarize(red: Double = 0.0, green: Double = 0.0, blue: Double = 0.0, threshold: Double = 0) -> NSImage? {
    precondition(red.isWithinLimits() && green.isWithinLimits() && blue.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.solarize(red: red, green: green, blue: blue, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Solarize
  static func solarize(red: Double, green: Double, blue: Double, threshold: Double) -> NSImage.FilterTransform {
    let initial = 0.0
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.median() > threshold else { return components.toPixel() }
      return NSImage.Pixel(
        red: red == initial ? components.red : components.red < red ? 1.0 - components.red : components.red,
        green: green == initial ? components.green : components.green < green ? 1.0 - components.green : components.green,
        blue: blue == initial ? components.blue : components.blue < blue ? 1.0 - components.blue : components.blue,
        alpha: components.alpha)
    }
  }
}

// MARK: - Invert Filter -

public extension NSImage {
  public func filterInvert(threshold: Double = 0.0) -> NSImage? {
    precondition(threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.invert(threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Inversion
  static func invert(threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      return NSImage.Pixel(red: 1.0 - components.red, green: 1.0 - components.green, blue: 1.0 - components.blue, alpha: components.alpha)
    }
  }
}

// MARK: - Gamma Filter -

public extension NSImage {
  public func filterGamma(level: Double = 1.0, threshold: Double = 0.0) -> NSImage? {
    precondition(level.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.gamma(level: level, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Gamma
  static func gamma(level: Double, threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      let gammaCorrection = 1 / (level * 5)
      return NSImage.Pixel(
        red: pow(components.red, gammaCorrection),
        green: pow(components.green, gammaCorrection),
        blue: pow(components.blue, gammaCorrection),
        alpha: components.alpha)
    }
  }
}

// MARK: - Brightness Filter -

public extension NSImage {
  public func filterBrightness(level: Double = 0, threshold: Double = 0.0) -> NSImage? {
    precondition(level.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.brightness(level: level, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Brightness
  static func brightness(level: Double, threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      return NSImage.Pixel(
        red: components.red + level,
        green: components.green + level,
        blue: components.blue + level,
        alpha: components.alpha)
    }
  }
}

// MARK: - Contrast Filter -

public extension NSImage {
  public func filterContrast(level: Double = 0.0, threshold: Double = 0.0) -> NSImage? {
    precondition(level.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.contrast(level: level, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Contrast
  static func contrast(level: Double, threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      let factor = (level + 1.0) / (1.0 - level)
      return NSImage.Pixel(
        red: factor * (components.red - 0.5) + 0.5,
        green: factor * (components.green - 0.5) + 0.5,
        blue: factor * (components.blue - 0.5) + 0.5,
        alpha: components.alpha)
    }
  }
}

// MARK: - Sepia Filter -

public extension NSImage {
  public func filterSepia(level: Double = 1.0, threshold: Double = 0.0) -> NSImage? {
    precondition(level.isWithinLimits() && threshold.isWithinLimits(), "Input values out of scope -1.0 to 1.0")
    let filter = Transform.sepia(level: level, threshold: threshold)
    return processFilterTransform(filter: filter)
  }
}

private extension NSImage.Transform {
  // Color Sepia
  static func sepia(level: Double, threshold: Double) -> NSImage.FilterTransform {
    return { (components: NSImage.Components) -> NSImage.Pixel in
      guard components.greaterEqualTo(threshold) else { return components.toPixel() }
      let red = components.red * 0.393 * level * 5 +
        components.green * 0.769 * level * 5 +
        components.blue * 0.189 * level * 5
      let green = components.red * 0.349 * level * 5 +
        components.green * 0.686 * level * 5 +
        components.blue * 0.168 * level * 5
      let blue = components.red * 0.272 * level * 5 +
        components.green * 0.534 * level * 5 +
        components.blue * 0.131 * level * 5
      return NSImage.Pixel(red: red, green: green, blue: blue, alpha: components.alpha)
    }
  }
}
