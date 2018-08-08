
//
//  File:       ViewController.swift
//  Project:    FilterPlay

import Cocoa

class ViewController: NSViewController {
  @IBOutlet var scrollView: NSScrollView!
  @IBOutlet var stackView: NSStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    loadFilterExamples()
  }

  func loadFilterExamples() {
    guard let image = Helper.pickRandomImage() else { fatalError("Image failed to load") }
    Helper.initializeExampleFilters(image: image, stackView: stackView, scrollView: scrollView, imageRatio: 1.0)
  }

  func refresh() {
    loadFilterExamples()
  }
}
