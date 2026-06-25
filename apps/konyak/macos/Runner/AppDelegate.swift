import Cocoa
import Darwin
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
      case "visibleExternalWindowIds":
        result(
          visibleExternalWindowIds(
            matching: windowFilter(from: call.arguments)
          )
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    menuChannel = channel
  }

  @IBAction func openSettings(_ _: Any?) {
    menuChannel?.invokeMethod("openSettings", arguments: nil)
  }

  @IBAction func reinstallMacosRuntime(_ _: Any?) {
    menuChannel?.invokeMethod("reinstallMacosRuntime", arguments: nil)
  }

  @IBAction func checkKonyakUpdates(_ _: Any?) {
    menuChannel?.invokeMethod("checkKonyakUpdates", arguments: nil)
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

  private struct WindowFilter {
    let rootProcessIdentifiers: Set<pid_t>
    let includeWineProcessWindows: Bool

    var hasCriteria: Bool {
      return !rootProcessIdentifiers.isEmpty || includeWineProcessWindows
    }
  }

  private func windowFilter(from arguments: Any?) -> WindowFilter {
    guard let values = arguments as? [String: Any] else {
      return WindowFilter(
        rootProcessIdentifiers: rootProcessIdentifiers(from: arguments),
        includeWineProcessWindows: false
      )
    }

    let rootProcessIdentifiers = rootProcessIdentifiers(
      from: values["descendantOfProcessIds"]
    )
    let includeWineProcessWindows =
      values["includeWineProcessWindows"] as? Bool ?? false

    return WindowFilter(
      rootProcessIdentifiers: rootProcessIdentifiers,
      includeWineProcessWindows: includeWineProcessWindows
    )
  }

  private func rootProcessIdentifiers(from arguments: Any?) -> Set<pid_t> {
    if let values = arguments as? [NSNumber] {
      return Set(values.map(\.int32Value).filter { $0 > 0 })
    }

    guard let values = arguments as? [Any] else {
      return []
    }

    return Set(
      values.compactMap { value in
        if let number = value as? NSNumber {
          return number.int32Value
        }
        if let intValue = value as? Int {
          return pid_t(intValue)
        }
        return nil
      }.filter { $0 > 0 }
    )
  }

  private func visibleExternalWindowIds(matching filter: WindowFilter) -> [String] {
    guard filter.hasCriteria else {
      return []
    }

    let options: CGWindowListOption = [
      .optionOnScreenOnly,
      .excludeDesktopElements,
    ]
    guard let windows = CGWindowListCopyWindowInfo(
      options,
      kCGNullWindowID
    ) as? [[String: Any]] else {
      return []
    }

    let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
    return windows.compactMap { window in
      guard
        isVisibleExternalApplicationWindow(
          window,
          currentProcessIdentifier: currentProcessIdentifier,
          ownerName: window[kCGWindowOwnerName as String] as? String,
          filter: filter
        ),
        let windowNumber = window[kCGWindowNumber as String] as? NSNumber
      else {
        return nil
      }

      return windowNumber.stringValue
    }
  }

  private func isVisibleExternalApplicationWindow(
    _ window: [String: Any],
    currentProcessIdentifier: Int32,
    ownerName: String?,
    filter: WindowFilter
  ) -> Bool {
    guard
      let ownerProcessIdentifier =
        window[kCGWindowOwnerPID as String] as? NSNumber,
      let layer = window[kCGWindowLayer as String] as? NSNumber,
      layer.intValue == 0
    else {
      return false
    }

    let ownerProcessIdentifierValue = ownerProcessIdentifier.int32Value
    guard ownerProcessIdentifierValue != currentProcessIdentifier else {
      return false
    }

    guard
      isProcess(
        ownerProcessIdentifierValue,
        ownerName: ownerName,
        matching: filter
      )
    else {
      return false
    }

    if
      let isOnscreen = window[kCGWindowIsOnscreen as String] as? NSNumber,
      !isOnscreen.boolValue
    {
      return false
    }

    if
      let alpha = window[kCGWindowAlpha as String] as? NSNumber,
      alpha.doubleValue <= 0
    {
      return false
    }

    guard let bounds = window[kCGWindowBounds as String] as? [String: Any]
    else {
      return false
    }

    return windowDimension(bounds, key: "Width") >= 80
      && windowDimension(bounds, key: "Height") >= 60
  }

  private func isProcess(
    _ processIdentifier: pid_t,
    ownerName: String?,
    matching filter: WindowFilter
  ) -> Bool {
    if
      isProcess(
        processIdentifier,
        descendantOf: filter.rootProcessIdentifiers
      )
    {
      return true
    }

    guard filter.includeWineProcessWindows else {
      return false
    }

    return isWineProcessName(ownerName)
      || isWineProcessExecutablePath(processExecutablePath(processIdentifier))
  }

  private func isProcess(
    _ processIdentifier: pid_t,
    descendantOf rootProcessIdentifiers: Set<pid_t>
  ) -> Bool {
    guard !rootProcessIdentifiers.isEmpty else {
      return false
    }

    var currentProcessIdentifier = processIdentifier
    var visitedProcessIdentifiers = Set<pid_t>()

    while currentProcessIdentifier > 0
      && !visitedProcessIdentifiers.contains(currentProcessIdentifier)
    {
      if rootProcessIdentifiers.contains(currentProcessIdentifier) {
        return true
      }

      visitedProcessIdentifiers.insert(currentProcessIdentifier)
      guard
        let parentProcessIdentifier = parentProcessIdentifier(
          of: currentProcessIdentifier
        )
      else {
        return false
      }

      currentProcessIdentifier = parentProcessIdentifier
    }

    return false
  }

  private func isWineProcessName(_ name: String?) -> Bool {
    guard let normalizedName = name?.lowercased() else {
      return false
    }

    return normalizedName.contains("wine")
      || normalizedName.contains("crossover")
      || normalizedName.contains("cxmenu")
  }

  private func isWineProcessExecutablePath(_ path: String?) -> Bool {
    guard let normalizedPath = path?.lowercased() else {
      return false
    }

    return normalizedPath.contains("/wine")
      || normalizedPath.contains("wine64")
      || normalizedPath.contains("wine-preloader")
      || normalizedPath.contains("wine64-preloader")
      || normalizedPath.contains("crossover")
  }

  private func processExecutablePath(_ processIdentifier: pid_t) -> String? {
    var buffer = [CChar](repeating: 0, count: 4096)
    let length = proc_pidpath(processIdentifier, &buffer, UInt32(buffer.count))
    guard length > 0 else {
      return nil
    }

    return String(cString: buffer)
  }

  private func parentProcessIdentifier(
    of processIdentifier: pid_t
  ) -> pid_t? {
    var processInfo = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [
      CTL_KERN,
      KERN_PROC,
      KERN_PROC_PID,
      processIdentifier,
    ]

    let result = sysctl(&mib, u_int(mib.count), &processInfo, &size, nil, 0)
    guard result == 0, size > 0 else {
      return nil
    }

    let parentProcessIdentifier = processInfo.kp_eproc.e_ppid
    return parentProcessIdentifier > 0 ? parentProcessIdentifier : nil
  }

  private func windowDimension(_ bounds: [String: Any], key: String) -> Double {
    if let number = bounds[key] as? NSNumber {
      return number.doubleValue
    }

    if let value = bounds[key] as? Double {
      return value
    }

    return 0
  }
}
