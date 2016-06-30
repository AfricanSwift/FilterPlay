//
//  File:       NSImage+Basics.swift
//  Project:    FilterPlay

import AppKit
import Foundation

// MARK: - NSImage to NSBitmapImageRep -
public extension NSImage
{
  ///  Convert NSImage to NSBitmapImageRep
  ///  - returns: NSBitmapImageRep
  public func bitmapImageRep() -> NSBitmapImageRep?
  {
    let width = Int(self.size.width)
    let height = Int(self.size.height)
    
    guard let bitmapImageRep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: width,
      pixelsHigh: height,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: NSCalibratedRGBColorSpace,
      bytesPerRow: width * 4,
      bitsPerPixel: 32) else { return nil }
    
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapImageRep)
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.setCurrent(graphicsContext)
    
    self.draw(at: NSZeroPoint,
              from: NSZeroRect,
              operation: NSCompositingOperation.copy,
              fraction: CGFloat(1.0))
    
    graphicsContext?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return bitmapImageRep
  }
}

// MARK: - NSImage to UnsafeMutablePointer<Pixel> -
public extension NSImage {
  
  ///  Pixel Components
  public struct Pixel {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
    
    private static func toUInt8(value: Double) -> UInt8
    {
      return value > 1.0 ? UInt8(255) : value < 0 ? UInt8(0) : UInt8(value * 255.0)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
    {
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha
    }
    
    init(red: Double, green: Double, blue: Double, alpha: Double)
    {
      self.red = Pixel.toUInt8(value: red)
      self.green = Pixel.toUInt8(value: green)
      self.blue = Pixel.toUInt8(value: blue)
      self.alpha = Pixel.toUInt8(value: alpha)
    }
  }
  
  ///  Converts NSImage to UnsafeMutablePointer<Pixel>
  ///  Used for pixel component access and/or manipulation
  ///  - returns: UnsafeMutablePointer<Pixel>
  public func pixelArray() -> UnsafeMutablePointer<Pixel>? {
    // Convert to NSBitmapImageRep For Pixel Access
    guard let imageRep = self.bitmapImageRep() else
    {
      return nil
    }
    return UnsafeMutablePointer<Pixel>(imageRep.bitmapData)
  }
  
  ///  Converts NSImage to UnsafeMutablePointer<UInt8>
  ///  Used for pixel component access and/or manipulation
  ///  - returns: UnsafeMutablePointer<Pixel>
  public func pixelData() -> UnsafeMutablePointer<UInt8>? {
    // Convert to NSBitmapImageRep For Pixel Access
    guard let imageRep = self.bitmapImageRep() else
    {
      return nil
    }
    return imageRep.bitmapData
  }
}

// MARK: - UnsafeMutablePointer<Pixel> to NSImage -
public extension NSImage {
  
  ///  Recomposites UnsafeMutablePointer<Pixel> Back To NSImage
  ///  Works in conjunction with pixelArray() functions.
  ///  - parameter pixelData: UnsafeMutablePointer<Pixel>
  ///  - parameter size: NSSize of image data contained in UnsafeMutablePointer<Pixel>
  ///  - returns: NSImage
  public static func recomposite(
    _ pixelData: UnsafeMutablePointer<UInt8>,
    size: NSSize) -> NSImage?
  {
    let width = Int(size.width)
    let height = Int(size.height)
    guard let colorSpace = NSColorSpace.genericRGB().cgColorSpace else { return nil }
    let bytesPerRow = sizeof(Pixel) * width
    let bitsPerComponent = 8
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue |
      CGImageAlphaInfo.premultipliedLast.rawValue
    
    /* Create empty CGcontext */
    guard let bitmapContext = CGContext(
      data: pixelData,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo) else
    {
      return nil
    }
    
    guard let cgImage = bitmapContext.makeImage() else
    {
      return nil
    }
    
    let imageSize = NSSize(width: width, height: height)
    return NSImage(cgImage: cgImage, size: imageSize)
  }
  
  ///  Recomposites UnsafeMutablePointer<Pixel> Back To NSImage
  ///  Works in conjunction with pixelArray() functions.
  ///  - parameter pixelData: UnsafeMutablePointer<Pixel>
  ///  - parameter size: NSSize of image data contained in UnsafeMutablePointer<Pixel>
  ///  - returns: NSImage
  public static func recompositePixelData(
    _ pixelData: UnsafeMutablePointer<Pixel>,
    size: NSSize) -> NSImage? {
    let width = Int(size.width)
    let height = Int(size.height)
    let colorSpace = NSColorSpace.genericRGB().cgColorSpace
    let bytesPerRow = sizeof(Pixel) * width
    let bitsPerComponent = 8
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue |
      CGImageAlphaInfo.premultipliedLast.rawValue
    
    /* Create empty CGcontext */
    guard let bitmapContext = CGContext(
      data: pixelData,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace!,
      bitmapInfo: bitmapInfo) else
    {
      return nil
    }
    
    guard let cgImage = bitmapContext.makeImage() else
    {
      return nil
    }
    
    let imageSize = NSSize(width: width, height: height)
    return NSImage(cgImage: cgImage, size: imageSize)
  }
}

// MARK: - Draws a border on the image -
public extension NSImage
{
  public func border(inset: CGFloat = 40.0, radius: CGFloat = 5.0) -> NSImage?
  {
    self.lockFocus()
    let rectangle = NSBezierPath(
      roundedRect: NSRect(
        x: 0,
        y: 0,
        width: self.size.width,
        height: self.size.height),
      xRadius: radius,
      yRadius: radius)
    
    NSColor.white().set()
    rectangle.lineWidth = inset * 2
    rectangle.stroke()
    
    NSColor.black().set()
    rectangle.lineWidth = 10
    rectangle.stroke()
    
    NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).set()
    let innerRectangle = NSBezierPath(
      roundedRect: NSRect(
        x: inset,
        y: inset,
        width: self.size.width - inset * 2,
        height: self.size.height - inset * 2),
      xRadius: 0,
      yRadius: 0)
    innerRectangle.lineWidth = 1
    innerRectangle.stroke()
    
    self.unlockFocus()
    return self
  }
  
}

// MARK: - Save NSImage -
public extension NSImage
{
  ///  Save NSImage to file
  ///  - parameter filename:  String filename (without or without path)
  ///  - parameter imageType: NSBitmapImageFileType, e.g. NSBitmapImageFileType.NSPNGFileType
  public func save(_ filename: String, imageType: NSBitmapImageFileType) throws
  {
    try self.bitmapImageRep()?
      .representation(using: imageType, properties: [:])?
      .write(to: URL(fileURLWithPath: filename), options: [])
  }
}

// MARK: - CGImage -
public extension NSImage
{
  
  ///  Convert NSImage to CGImage
  ///  - returns: CGImage
  public func cgImage() -> CGImage?
  {
    let colorSpace = NSColorSpace.genericRGB().cgColorSpace
    let width = Int(self.size.width)
    let height = Int(self.size.height)
    let bytesPerRow = 0
    let bitsPerComponent = 8
    
    /* Create empty CGcontext */
    guard let bitmapContext = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace!,
      bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
        CGImageAlphaInfo.premultipliedFirst.rawValue)
      else
    {
      return nil
    }
    
    /* Draw current NSImage into this CGContext */
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)
    NSGraphicsContext.setCurrent(context)
    let targetRect = NSMakeRect(0, 0, self.size.width, self.size.height)
    self.draw(in: targetRect,
              from: NSZeroRect,
              operation: NSCompositingOperation.copy,
              fraction: CGFloat(1.0))
    NSGraphicsContext.restoreGraphicsState()
    return bitmapContext.makeImage()
  }
}

// MARK: - Resize by Ratio & CGSize -
public extension NSImage
{
  ///  Resize Current NSImage
  ///  - parameter ratio: CGFloat factor to use for resizing
  ///  - returns: the current NSImage resized by ratio
  public func resize(_ ratio: CGFloat) -> NSImage?
  {
    let newWidth = self.size.width * ratio
    let newHeight = self.size.height * ratio
    return self.resize(CGSize(width: newWidth, height: newHeight))
  }
  
  ///  Resize Current NSImage
  ///  - parameter newSize: new CGSize
  ///  - parameter quality: optional required quality
  ///  - returns: the current NSImage resized to the new CGSize
  public func resize(
    _ newSize: CGSize,
    interpolationQuality quality: CGInterpolationQuality = .high) -> NSImage?
  {
    
    let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
    guard let imageRef = self.cgImage()
      else
    {
      return nil
    }
    
    // Build a newSize CGContext
    let width = Int(newRect.size.width)
    let height = Int(newRect.size.height)
    let bitsPerComponent = imageRef.bitsPerComponent
    let colorSpace = imageRef.colorSpace
    let bitmapInfo = imageRef.bitmapInfo.rawValue
    
    guard let bitmapContext = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: 0,
      space: colorSpace!,
      bitmapInfo: bitmapInfo)
      else
    {
      return nil
    }
    
    // Draw current image into CGContext
    bitmapContext.interpolationQuality = quality
    bitmapContext.draw(in: newRect, image: imageRef)
    
    guard let newImageRef = bitmapContext.makeImage() else
    {
      return nil
    }
    
    return NSImage(cgImage: newImageRef, size: newRect.size)
  }
}
