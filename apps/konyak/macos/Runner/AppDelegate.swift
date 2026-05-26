import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var menuChannel: FlutterMethodChannel?
  private var pendingExecutableOpenPaths: [String] = []
  private var isFlutterReadyForExecutableOpenEvents = false

  func configureMenuChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "konyak/menu",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result([])
        return
      }

      switch call.method {
      case "takePendingExecutableOpenPaths":
        isFlutterReadyForExecutableOpenEvents = true
        let paths = pendingExecutableOpenPaths
        pendingExecutableOpenPaths.removeAll()
        result(paths)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    menuChannel = channel
  }

  @IBAction func openSettings(_ _: Any?) {
    menuChannel?.invokeMethod("openSettings", arguments: nil)
  }

  @IBAction func importBottleArchive(_ _: Any?) {
    menuChannel?.invokeMethod("importBottleArchive", arguments: nil)
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let executablePaths = executableOpenPaths(
      filenames.map { URL(fileURLWithPath: $0) }
    )

    if executablePaths.isEmpty {
      sender.reply(toOpenOrPrint: .failure)
      return
    }

    forwardExecutableOpenPaths(executablePaths)
    sender.reply(toOpenOrPrint: .success)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    forwardExecutableOpenPaths(executableOpenPaths(urls))
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func forwardExecutableOpenPaths(_ paths: [String]) {
    guard !paths.isEmpty else {
      return
    }

    guard let menuChannel, isFlutterReadyForExecutableOpenEvents else {
      pendingExecutableOpenPaths.append(contentsOf: paths)
      return
    }

    menuChannel.invokeMethod("openExecutableFiles", arguments: paths)
  }

  private func executableOpenPaths(_ urls: [URL]) -> [String] {
    return urls.compactMap { url in
      guard url.isFileURL, url.pathExtension.lowercased() == "exe" else {
        return nil
      }

      return url.path
    }
  }
}
