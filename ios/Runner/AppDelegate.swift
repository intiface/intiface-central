import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let mdnsChannelName = "com.nonpolynomial.intiface_central/mdns_platform_service"
  private var mdnsMethodChannel: FlutterMethodChannel?
  private var mdnsPublisher: NetService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let dummy = dummy_method_to_enforce_bundling()
    print(dummy)
    GeneratedPluginRegistrant.register(with: self)
    // here, Without this code the task will not work.
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
    setupMdnsPlatformChannel()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    stopMdnsPublisher()
  }

  private func setupMdnsPlatformChannel() {
    guard mdnsMethodChannel == nil else {
      return
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("[mdns] unable to create method channel: missing FlutterViewController")
      return
    }

    let channel = FlutterMethodChannel(
      name: mdnsChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(false)
        return
      }

      switch call.method {
      case "startMdnsPublisher":
        self.handleStartMdnsPublisher(arguments: call.arguments, result: result)
      case "stopMdnsPublisher":
        self.handleStopMdnsPublisher(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    mdnsMethodChannel = channel
  }

  private func handleStartMdnsPublisher(arguments: Any?, result: @escaping FlutterResult) {
    guard let payload = arguments as? [String: Any] else {
      NSLog("[mdns] startMdnsPublisher failed: expected map arguments")
      result(false)
      return
    }

    guard let serviceType = payload["serviceType"] as? String, !serviceType.isEmpty else {
      NSLog("[mdns] startMdnsPublisher failed: missing serviceType")
      result(false)
      return
    }

    guard let instanceName = payload["instanceName"] as? String, !instanceName.isEmpty else {
      NSLog("[mdns] startMdnsPublisher failed: missing instanceName")
      result(false)
      return
    }

    guard let portValue = payload["port"] as? NSNumber else {
      NSLog("[mdns] startMdnsPublisher failed: missing port")
      result(false)
      return
    }

    let port = Int32(truncating: portValue)
    guard port > 0 && port <= Int32(UInt16.max) else {
      NSLog("[mdns] startMdnsPublisher failed: invalid port \(port)")
      result(false)
      return
    }

    guard let txtRecords = payload["txtRecords"] as? [String] else {
      NSLog("[mdns] startMdnsPublisher failed: missing txtRecords")
      result(false)
      return
    }

    guard let txtRecordDictionary = makeTxtRecordDictionary(from: txtRecords) else {
      NSLog("[mdns] startMdnsPublisher failed: invalid txtRecords")
      result(false)
      return
    }

    stopMdnsPublisher()

    let publisher = NetService(domain: "", type: serviceType, name: instanceName, port: port)
    publisher.delegate = self

    let txtRecordData = NetService.data(fromTXTRecord: txtRecordDictionary)
    if !publisher.setTXTRecord(txtRecordData) {
      NSLog("[mdns] startMdnsPublisher failed: could not set TXT record")
      publisher.delegate = nil
      publisher.stop()
      result(false)
      return
    }

    mdnsPublisher = publisher
    publisher.publish(options: [.noAutoRename])
    result(true)
  }

  private func handleStopMdnsPublisher(result: @escaping FlutterResult) {
    stopMdnsPublisher()
    result(true)
  }

  private func stopMdnsPublisher() {
    guard let publisher = mdnsPublisher else {
      return
    }

    mdnsPublisher = nil
    publisher.delegate = nil
    publisher.stop()
  }

  private func makeTxtRecordDictionary(from records: [String]) -> [String: Data]? {
    var dictionary: [String: Data] = [:]

    for record in records {
      guard let separatorIndex = record.firstIndex(of: "=") else {
        NSLog("[mdns] invalid TXT record \(record)")
        return nil
      }

      let key = String(record[..<separatorIndex])
      let value = String(record[record.index(after: separatorIndex)...])

      guard !key.isEmpty else {
        NSLog("[mdns] invalid TXT record \(record)")
        return nil
      }

      dictionary[key] = Data(value.utf8)
    }

    return dictionary
  }
}

extension AppDelegate: NetServiceDelegate {
  func netServiceDidPublish(_ sender: NetService) {
    NSLog("[mdns] published \(sender.name).\(sender.type) on port \(sender.port)")
  }

  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    NSLog("[mdns] publish failed for \(sender.name).\(sender.type): \(errorDict)")
    if sender == mdnsPublisher {
      mdnsPublisher = nil
    }
  }
}

// here
func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}
