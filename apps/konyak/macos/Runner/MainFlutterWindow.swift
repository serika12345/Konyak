//
//  MainFlutterWindow.swift
//  Konyak
//
//  This file is part of Konyak.
//
//  SPDX-License-Identifier: MIT
//

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    setDockIcon()

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.contentMinSize = NSSize(width: 600, height: 316)
    self.titleVisibility = .hidden
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
      appDelegate.configureMenuChannel(
        binaryMessenger: flutterViewController.engine.binaryMessenger
      )
    }
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func setDockIcon() {
    guard
      let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
      let icon = NSImage(contentsOf: iconURL)
    else {
      return
    }

    NSApplication.shared.applicationIconImage = icon
  }
}
