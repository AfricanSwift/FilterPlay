//
//  File:       Helpers.swift
//  Project:    FilterPlay

import AppKit

public extension Array {
  public func mapWithIndex<T>(_ function: (Int, Element) -> T) -> [T] {
    return zip((self.indices), self).map(function)
  }
}

public struct Helper {
  private static let borderInset = CGFloat(15)
  private static let borderRadius = CGFloat(5)
  
  // Randomly pick an image
  public static func pickRandomImage() -> NSImage? {
    let imageNames = ["zork1", "zork3", "skull1a", "madpirate", "Trinquette", "ktavamp"]
    
    // Ensure Random Index within bounds
    let randomIndex = { () -> Int in
      let randomIndex = Int(arc4random_uniform(UInt32(imageNames.count)))
      let lastIndex = imageNames.count - 1
      return randomIndex >= 0 ? randomIndex <= lastIndex ? randomIndex : lastIndex : 0
    }

    guard let image = NSImage(named: imageNames[randomIndex()]) else {
      return NSImage(named: "zork1") ?? NSImage()
    }
    return image
  }
  
  // Initialize Example Filters
  public static func initializeExampleFilters(image: NSImage, stackView: NSStackView, scrollView: NSScrollView, imageRatio: CGFloat = 2.0) {
    stackView.subviews.forEach { $0.removeFromSuperview() }
    stackView.constraints.forEach { stackView.removeConstraint($0) }
    scrollView.constraints.forEach { scrollView.removeConstraint($0) }
    // Apply seven filters
    let images = Helper.generateFilterExamples(image: image)
    guard !images.isEmpty else { return }
    // Build NSImageViews using the seven filter output
    let imageViews = Helper.buildImageViews(images: images, imageRatio: imageRatio)
    let subWidth = images[0].size.width / imageRatio
    let subHeight = images[0].size.height / imageRatio
    let window = NSApplication.shared.mainWindow
    
    if let mainWindow = window {
      var windowFrame = mainWindow.frame
      windowFrame.size.width = subWidth
      mainWindow.setFrame(windowFrame, display: true, animate: true)
    }
    // Resize scrollView to match image width
    scrollView.frame.size = CGSize(width: subWidth, height: scrollView.frame.size.height)
    
    // Add stackView Width & Height constraints
    NSLayoutConstraint(item: stackView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: subWidth).isActive = true
    NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: subHeight * CGFloat(images.count)).isActive = true
    imageViews.forEach { stackView.addSubview($0) }
  }
  
  // Construct a ScrollView of the images provided
  private static func buildImageViews(images: [NSImage], imageRatio: CGFloat) -> [NSImageView] {
    let subWidth = images[0].size.width / imageRatio
    let subHeight = images[0].size.height / imageRatio
    
    // Create an array of NSImageView from Array of NSImage
    return images.mapWithIndex { (index: Int, image: NSImage) -> NSImageView in
      let imageViewFrame = CGRect(
        x: 0,
        y: (CGFloat(images.count) * subHeight) - (CGFloat(index + 1) * subHeight),
        width: subWidth,
        height: subHeight)
      let imageView = NSImageView(frame: imageViewFrame)
      imageView.image = image
      return imageView
    }
  }
  
  // Generate seven filter examples
  private static func generateFilterExamples(image: NSImage) -> [NSImage] {
    let imageFilter1 = image
      .filterSepia(level: 0.34, threshold: 0.00)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter2 = image
      .filterTint(red: 0.5, blue: 0.5, threshold: 0.01)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter3 = image
      .filterShading(green: -0.8, blue: 0.9, threshold: 0.01)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter4 = image
      .filterGamma(level: 0.8, threshold: 0.00)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter5 = image
      .dither(NSImage.Dither.atkinson)?
      .filterBinary(level: 0.335, transparent: false)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter6 = image
      .filterSolarize(red: 0.2, green: 0.2, blue: 0.1, threshold: 0.01)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    let imageFilter7 = image
      .dither(NSImage.Dither.jarvisJudiceNinke)?
      .filterBinary(level: 0.98, threshold: 0.0, transparent: true)?
      .filterTint(red: 0.5, blue: 0.5)?
      .border(inset: Helper.borderInset, radius: Helper.borderRadius)
    return [imageFilter1, imageFilter2, imageFilter3, imageFilter4, imageFilter5, imageFilter6, imageFilter7].compactMap { $0 }
  }
}
