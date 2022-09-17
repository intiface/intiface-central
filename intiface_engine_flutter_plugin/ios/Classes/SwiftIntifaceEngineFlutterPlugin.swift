import Flutter
import UIKit

public class SwiftIntifaceEngineFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "intiface_engine_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftIntifaceEngineFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
