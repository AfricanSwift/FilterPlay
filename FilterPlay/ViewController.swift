
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
  
  func loadFilterExamples()
  {
    guard let image = Helper.pickRandomImage() else
    {
      assert(false, "Image failed to load")
      exit(0)
    }
    
    Helper.initializeExampleFilters(
      image: image,
      stackView: self.stackView,
      scrollView: self.scrollView,
      imageRatio: 1.0)
  }
  
  func refresh()
  {
    loadFilterExamples()
  }
}

