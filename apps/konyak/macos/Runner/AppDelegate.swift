import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var menuChannel: FlutterMethodChannel?

  func configureMenuChannel(binaryMessenger: FlutterBinaryMessenger) {
    menuChannel = FlutterMethodChannel(
      name: "konyak/menu",
      binaryMessenger: binaryMessenger
    )
  }

  @IBAction func openSettings(_ _: Any?) {
    menuChannel?.invokeMethod("openSettings", arguments: nil)
  }

  @IBAction func importBottleArchive(_ _: Any?) {
    menuChannel?.invokeMethod("importBottleArchive", arguments: nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
