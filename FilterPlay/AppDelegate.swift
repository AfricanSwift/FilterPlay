//
//  File:       AppDelegate.swift
//  Project:    FilterPlay

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  @IBAction func refresh(_ sender: AnyObject) {
    guard let window = NSApplication.shared().mainWindow else
    {
      print("No mainWindow found")
      return
    }
    
    guard let viewController = window.contentViewController else {
      print("Could not identify contentViewController")
      return
    }
    
    // Refresh Image (Randomly pick another one)
    (viewController as! ViewController).refresh()
  }
}

