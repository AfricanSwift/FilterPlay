//
//  File:       AppDelegate.swift
//  Project:    FilterPlay

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    return true
  }

  @IBAction func refresh(_: AnyObject) {
    guard let window = NSApplication.shared.mainWindow else { fatalError("No mainwindow found") }
    guard let viewController = window.contentViewController else { fatalError("Could not identify contentViewController") }

    // Refresh Image (Randomly pick another one)
    (viewController as! ViewController).refresh()
  }
}
