import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { engine, repeater }

class IntifaceConfigurationState {}

class IntifaceConfigurationStateNone extends IntifaceConfigurationState {}

class UseLightThemeState extends IntifaceConfigurationState {
  final bool value;
  UseLightThemeState(this.value);
}

class UseSideNavigationBar extends IntifaceConfigurationState {
  final bool value;
  UseSideNavigationBar(this.value);
}

class StartServerOnStartupState extends IntifaceConfigurationState {
  final bool value;
  StartServerOnStartupState(this.value);
}

class ServerNameState extends IntifaceConfigurationState {
  final String value;
  ServerNameState(this.value);
}

class UseBluetoothLEState extends IntifaceConfigurationState {
  final bool value;
  UseBluetoothLEState(this.value);
}

class UseXInputState extends IntifaceConfigurationState {
  final bool value;
  UseXInputState(this.value);
}

class UseLovenseConnectServiceState extends IntifaceConfigurationState {
  final bool value;
  UseLovenseConnectServiceState(this.value);
}

class UseDeviceWebsocketServerState extends IntifaceConfigurationState {
  final bool value;
  UseDeviceWebsocketServerState(this.value);
}

class UseSerialPortState extends IntifaceConfigurationState {
  final bool value;
  UseSerialPortState(this.value);
}

class UseHIDState extends IntifaceConfigurationState {
  final bool value;
  UseHIDState(this.value);
}

class UseLovenseHIDDongleState extends IntifaceConfigurationState {
  final bool value;
  UseLovenseHIDDongleState(this.value);
}

class UseLovenseSerialDongleState extends IntifaceConfigurationState {
  final bool value;
  UseLovenseSerialDongleState(this.value);
}

class WebsocketServerAllInterfacesState extends IntifaceConfigurationState {
  final bool value;
  WebsocketServerAllInterfacesState(this.value);
}

class WebsocketServerPortState extends IntifaceConfigurationState {
  final int value;
  WebsocketServerPortState(this.value);
}

class UseCompactDisplayState extends IntifaceConfigurationState {
  final bool value;
  UseCompactDisplayState(this.value);
}

class CurrentNewsEtagState extends IntifaceConfigurationState {
  final String value;
  CurrentNewsEtagState(this.value);
}

class CurrentDeviceConfigEtagState extends IntifaceConfigurationState {
  final String value;
  CurrentDeviceConfigEtagState(this.value);
}

class CurrentDeviceConfigVersionState extends IntifaceConfigurationState {
  final String value;
  CurrentDeviceConfigVersionState(this.value);
}

class LatestAppVersionState extends IntifaceConfigurationState {
  final String version;
  LatestAppVersionState(this.version);
}

class CheckForUpdateOnStartState extends IntifaceConfigurationState {
  final bool value;
  CheckForUpdateOnStartState(this.value);
}

class UseProcessEngineState extends IntifaceConfigurationState {
  final bool value;
  UseProcessEngineState(this.value);
}

class UseForegroundProcessState extends IntifaceConfigurationState {
  final bool value;
  UseForegroundProcessState(this.value);
}

class AllowRawMessagesState extends IntifaceConfigurationState {
  final bool value;
  AllowRawMessagesState(this.value);
}

class BroadcastServerMdnsState extends IntifaceConfigurationState {
  final bool value;
  BroadcastServerMdnsState(this.value);
}

class MdnsSuffixState extends IntifaceConfigurationState {
  final String? value;
  MdnsSuffixState(this.value);
}

class DisplayLogLevelState extends IntifaceConfigurationState {
  final String? value;
  DisplayLogLevelState(this.value);
}

class CrashReportingState extends IntifaceConfigurationState {
  final bool value;
  CrashReportingState(this.value);
}

class RepeaterLocalPortState extends IntifaceConfigurationState {
  final int value;
  RepeaterLocalPortState(this.value);
}

class RepeaterRemoteAddressState extends IntifaceConfigurationState {
  final String value;
  RepeaterRemoteAddressState(this.value);
}

class AppModeState extends IntifaceConfigurationState {
  final AppMode value;
  AppModeState(this.value);
}

class RestoreWindowLocation extends IntifaceConfigurationState {
  final bool value;
  RestoreWindowLocation(this.value);
}

class ShowRepeaterModeState extends IntifaceConfigurationState {
  final bool value;
  ShowRepeaterModeState(this.value);
}

class ConfigurationResetState extends IntifaceConfigurationState {}

class IntifaceConfigurationCubit extends Cubit<IntifaceConfigurationState> {
  final SharedPreferences _prefs;

  IntifaceConfigurationCubit._create(this._prefs) : super(IntifaceConfigurationStateNone());

  static Future<IntifaceConfigurationCubit> create() async {
    final prefs = await SharedPreferences.getInstance();
    var cubit = IntifaceConfigurationCubit._create(prefs);
    await cubit._init();
    return cubit;
  }

  Future<void> _init() async {
    // Our initializer runs through all of our known configuration values, either setting them to what they already are,
    // or providing them with default values.

    // Window settings for desktop. Will be ignored on mobile. Default to expanded.
    useCompactDisplay = _prefs.getBool("useCompactDisplay") ?? false;

    // Crash reporting setting is now CrashReporting2, because it was originally slammed to true but never actually
    // used anywhere. With the addition of Sentry, it's now defaulted to off so we're not sending data without the
    // user's approval.
    crashReporting = _prefs.getBool("crashReporting2") ?? false;

    // Check all of our values to make sure they exist. If not, set defaults, based on platform if needed.
    serverName = _prefs.getString("serverName") ?? "Intiface Server";
    serverMaxPingTime = _prefs.getInt("maxPingTime") ?? 0;
    // This should automatically be true on phones, otherwise people are going to be VERY confused.
    websocketServerAllInterfaces = _prefs.getBool("websocketServerAllInterfaces") ?? isMobile();
    websocketServerPort = _prefs.getInt("websocketServerPort") ?? 12345;
    checkForUpdateOnStart = _prefs.getBool("checkForUpdateOnStart") ?? true;
    startServerOnStartup = _prefs.getBool("startServerOnStartup") ?? false;
    showNotifications = _prefs.getBool("showNotifications") ?? false;
    hasRunFirstUse = _prefs.getBool("hasRunFirstUse") ?? false;
    showExtendedUI = _prefs.getBool("showExtendedUI") ?? false;
    allowRawMessages = _prefs.getBool("allowRawMessages") ?? false;
    unreadNews = _prefs.getBool("unreadNews") ?? false;
    useSideNavigationBar = _prefs.getBool("useSideNavigationBar") ?? isDesktop();
    useLightTheme = _prefs.getBool("useLightTheme") ?? true;
    restoreWindowLocation = _prefs.getBool("restoreWindowLocation") ?? true;

    // True on all platforms
    useBluetoothLE = _prefs.getBool("useBluetoothLE") ?? true;

    // Only works on Windows
    useXInput = _prefs.getBool("useXInput") ?? Platform.isWindows;

    // Always default off, require user to turn them on.
    useLovenseConnectService = _prefs.getBool("useLovenseConnectService") ?? false;
    useDeviceWebsocketServer = _prefs.getBool("useDeviceWebsocketServer") ?? false;
    useSerialPort = _prefs.getBool("useSerialPort") ?? false;
    useHID = _prefs.getBool("useHID") ?? false;
    useLovenseHIDDongle = _prefs.getBool("useLovenseHIDDongle") ?? false;
    useLovenseSerialDongle = _prefs.getBool("useLovenseSerialDongle") ?? false;

    // Update settings
    currentNewsEtag = _prefs.getString("currentNewsEtag") ?? "";
    currentDeviceConfigEtag = _prefs.getString("currentDeviceConfigEtag") ?? "";
    currentDeviceConfigVersion = _prefs.getString("currentDeviceConfigVersion") ?? "0.0";

    var packageInfo = await PackageInfo.fromPlatform();
    currentAppVersion = packageInfo.version;
    latestAppVersion = _prefs.getString("latestAppVersion") ?? currentAppVersion;

    useProcessEngine = kDebugMode ? (_prefs.getBool("useProcessEngine") ?? false) : false;
    // Default to true on mobile.
    useForegroundProcess =
        (Platform.isAndroid || Platform.isIOS) ? (_prefs.getBool("useForegroundProcess3") ?? true) : false;

    broadcastServerMdns = _prefs.getBool("broadcastServerMdns") ?? false;
    mdnsSuffix = _prefs.getString("mdnsSuffix") ?? "";
    displayLogLevel = _prefs.getString("displayLogLevel") ?? "info";
    showRepeaterMode = _prefs.getBool("showRepeaterMode") ?? false;
    repeaterLocalPort = _prefs.getInt("repeaterLocalPort") ?? 12345;
    repeaterRemoteAddress = _prefs.getString("repeaterRemoteAddress") ?? "192.168.1.1:12345";
    // Default for appMode built into getter, since it also requires a type conversion.
  }

  Future<bool> reset() async {
    var result = await _prefs.clear();
    emit(ConfigurationResetState());
    await _init();
    return result;
  }

  String get currentNewsEtag => _prefs.getString("currentNewsEtag")!;
  set currentNewsEtag(String value) {
    _prefs.setString("currentNewsEtag", value);
    emit(CurrentNewsEtagState(value));
  }

  String get currentDeviceConfigEtag => _prefs.getString("currentDeviceConfigEtag")!;
  set currentDeviceConfigEtag(String value) {
    _prefs.setString("currentDeviceConfigEtag", value);
    emit(CurrentDeviceConfigEtagState(value));
  }

  // Slam to false until we figure out how to window resizing.
  bool get useCompactDisplay => false; //_prefs.getBool("useCompactDisplay")!;
  set useCompactDisplay(bool value) {
    _prefs.setBool("useCompactDisplay", value);
    emit(UseCompactDisplayState(value));
  }

  bool get useSideNavigationBar => _prefs.getBool("useSideNavigationBar")!;
  set useSideNavigationBar(bool value) {
    _prefs.setBool("useSideNavigationBar", value);
    emit(UseSideNavigationBar(value));
  }

  bool get useLightTheme => _prefs.getBool("useLightTheme")!;
  set useLightTheme(bool value) {
    _prefs.setBool("useLightTheme", value);
    emit(UseLightThemeState(value));
  }

  bool get restoreWindowLocation => _prefs.getBool("restoreWindowLocation")!;
  set restoreWindowLocation(bool value) {
    _prefs.setBool("restoreWindowLocation", value);
    emit(RestoreWindowLocation(value));
  }

  String get serverName => _prefs.getString("serverName")!;
  set serverName(String value) {
    _prefs.setString("serverName", value);
    emit(ServerNameState(value));
  }

  int get serverMaxPingTime => _prefs.getInt("maxPingTime")!;
  set serverMaxPingTime(int value) {
    _prefs.setInt("maxPingTime", value);
  }

  bool get websocketServerAllInterfaces => _prefs.getBool("websocketServerAllInterfaces")!;
  set websocketServerAllInterfaces(bool value) {
    _prefs.setBool("websocketServerAllInterfaces", value);
    emit(WebsocketServerAllInterfacesState(value));
  }

  int get websocketServerPort => _prefs.getInt("websocketServerPort")!;
  set websocketServerPort(int value) {
    _prefs.setInt("websocketServerPort", value);
    emit(WebsocketServerPortState(value));
  }

  bool get checkForUpdateOnStart => _prefs.getBool("checkForUpdateOnStart")!;
  set checkForUpdateOnStart(bool value) {
    _prefs.setBool("checkForUpdateOnStart", value);
    emit(CheckForUpdateOnStartState(value));
  }

  bool get startServerOnStartup => _prefs.getBool("startServerOnStartup")!;
  set startServerOnStartup(bool value) {
    _prefs.setBool("startServerOnStartup", value);
    emit(StartServerOnStartupState(value));
  }

  bool get useBluetoothLE => _prefs.getBool("useBluetoothLE")!;
  set useBluetoothLE(bool value) {
    _prefs.setBool("useBluetoothLE", value);
    emit(UseBluetoothLEState(value));
  }

  bool get useSerialPort => _prefs.getBool("useSerialPort")!;
  set useSerialPort(bool value) {
    _prefs.setBool("useSerialPort", value);
    emit(UseSerialPortState(value));
  }

  bool get useHID => _prefs.getBool("useHID")!;
  set useHID(bool value) {
    _prefs.setBool("useHID", value);
    emit(UseHIDState(value));
  }

  bool get useLovenseHIDDongle => _prefs.getBool("useLovenseHIDDongle")!;
  set useLovenseHIDDongle(bool value) {
    _prefs.setBool("useLovenseHIDDongle", value);
    emit(UseLovenseHIDDongleState(value));
  }

  bool get useLovenseSerialDongle => _prefs.getBool("useLovenseSerialDongle")!;
  set useLovenseSerialDongle(bool value) {
    _prefs.setBool("useLovenseSerialDongle", value);
    emit(UseLovenseSerialDongleState(value));
  }

  bool get useLovenseConnectService => _prefs.getBool("useLovenseConnectService")!;
  set useLovenseConnectService(bool value) {
    _prefs.setBool("useLovenseConnectService", value);
    emit(UseLovenseConnectServiceState(value));
  }

  bool get useXInput => _prefs.getBool("useXInput")!;
  set useXInput(bool value) {
    _prefs.setBool("useXInput", value);
    emit(UseXInputState(value));
  }

  bool get useDeviceWebsocketServer => _prefs.getBool("useDeviceWebsocketServer")!;
  set useDeviceWebsocketServer(bool value) {
    _prefs.setBool("useDeviceWebsocketServer", value);
    emit(UseDeviceWebsocketServerState(value));
  }

  bool get crashReporting => _prefs.getBool("crashReporting2")!;
  set crashReporting(bool value) {
    _prefs.setBool("crashReporting2", value);
    emit(CrashReportingState(value));
  }

  bool get showNotifications => _prefs.getBool("showNotifications")!;
  set showNotifications(bool value) {
    _prefs.setBool("showNotifications", value);
  }

  bool get hasRunFirstUse => _prefs.getBool("hasRunFirstUse")!;
  set hasRunFirstUse(bool value) {
    _prefs.setBool("hasRunFirstUse", value);
  }

  bool get showExtendedUI => _prefs.getBool("showExtendedUI")!;
  set showExtendedUI(bool value) {
    _prefs.setBool("showExtendedUI", value);
  }

  bool get allowRawMessages => _prefs.getBool("allowRawMessages")!;
  set allowRawMessages(bool value) {
    _prefs.setBool("allowRawMessages", value);
    emit(AllowRawMessagesState(value));
  }

  bool get unreadNews => _prefs.getBool("unreadNews")!;
  set unreadNews(bool value) {
    _prefs.setBool("unreadNews", value);
  }

  String get currentAppVersion => _prefs.getString("currentAppVersion")!;
  set currentAppVersion(String value) {
    _prefs.setString("currentAppVersion", value);
  }

  String get latestAppVersion => _prefs.getString("latestAppVersion")!;
  set latestAppVersion(String value) {
    _prefs.setString("latestAppVersion", value);
    emit(LatestAppVersionState(value));
  }

  String get currentDeviceConfigVersion => _prefs.getString("currentDeviceConfigVersion")!;
  set currentDeviceConfigVersion(String value) {
    _prefs.setString("currentDeviceConfigVersion", value);
    emit(CurrentDeviceConfigVersionState(value));
  }

  bool get useProcessEngine => _prefs.getBool("useProcessEngine")!;
  set useProcessEngine(bool value) {
    _prefs.setBool("useProcessEngine", value);
    emit(UseProcessEngineState(value));
  }

  bool get useForegroundProcess => _prefs.getBool("useForegroundProcess3")!;
  set useForegroundProcess(bool value) {
    _prefs.setBool("useForegroundProcess3", value);
    emit(UseForegroundProcessState(value));
  }

  bool get broadcastServerMdns => _prefs.getBool("broadcastServerMdns")!;
  set broadcastServerMdns(bool value) {
    _prefs.setBool("broadcastServerMdns", value);
    emit(BroadcastServerMdnsState(value));
  }

  String get mdnsSuffix => _prefs.getString("mdnsSuffix")!;
  set mdnsSuffix(String value) {
    _prefs.setString("mdnsSuffix", value);
    emit(MdnsSuffixState(value));
  }

  String get displayLogLevel => _prefs.getString("displayLogLevel")!;
  set displayLogLevel(String value) {
    _prefs.setString("displayLogLevel", value);
    emit(DisplayLogLevelState(value));
  }

  int get repeaterLocalPort => _prefs.getInt("repeaterLocalPort")!;
  set repeaterLocalPort(int value) {
    _prefs.setInt("repeaterLocalPort", value);
    emit(RepeaterLocalPortState(value));
  }

  String get repeaterRemoteAddress => _prefs.getString("repeaterRemoteAddress")!;
  set repeaterRemoteAddress(String value) {
    _prefs.setString("repeaterRemoteAddress", value);
    emit(RepeaterRemoteAddressState(value));
  }

  AppMode get appMode {
    var mode = _prefs.getString("appMode");
    return AppMode.values.firstWhere((element) => mode == element.name, orElse: () => AppMode.engine);
  }

  set appMode(AppMode value) {
    _prefs.setString("appMode", value.name);
    emit(AppModeState(value));
  }

  bool get showRepeaterMode => _prefs.getBool("showRepeaterMode")!;
  set showRepeaterMode(bool value) {
    _prefs.setBool("showRepeaterMode", value);
    if (!value) {
      appMode = AppMode.engine;
    }
    emit(ShowRepeaterModeState(value));
  }

  bool get canUseCrashReporting => const String.fromEnvironment("SENTRY_DSN").isNotEmpty;

  Future<EngineOptionsExternal> getEngineOptions() async {
    String? deviceConfigFile;
    if (await IntifacePaths.deviceConfigFile.exists()) {
      deviceConfigFile = await File(IntifacePaths.deviceConfigFile.path).readAsString();
    }

    String? userDeviceConfigFile;
    if (await IntifacePaths.userDeviceConfigFile.exists()) {
      userDeviceConfigFile = await File(IntifacePaths.userDeviceConfigFile.path).readAsString();
    }

    return EngineOptionsExternal(
        serverName: serverName,
        deviceConfigJson: deviceConfigFile,
        userDeviceConfigJson: userDeviceConfigFile,
        userDeviceConfigPath: IntifacePaths.userDeviceConfigFile.path,
        websocketUseAllInterfaces: websocketServerAllInterfaces,
        websocketPort: websocketServerPort,
        frontendInProcessChannel: isMobile(),
        maxPingTime: serverMaxPingTime,
        allowRawMessages: allowRawMessages,
        useBluetoothLe: useBluetoothLE,
        useSerialPort: isDesktop() ? useSerialPort : false,
        useHid: isDesktop() ? useHID : false,
        useLovenseDongleSerial: isDesktop() ? useLovenseSerialDongle : false,
        useLovenseDongleHid: isDesktop() ? useLovenseHIDDongle : false,
        useXinput: isDesktop() ? useXInput : false,
        useLovenseConnect: isDesktop() ? useLovenseConnectService : false,
        useDeviceWebsocketServer: useDeviceWebsocketServer,
        crashMainThread: false,
        crashTaskThread: false,
        broadcastServerMdns: broadcastServerMdns,
        mdnsSuffix: mdnsSuffix,
        // If we're getting options from config, the repeater won't have anything to do with it.
        repeaterMode: appMode == AppMode.repeater,
        repeaterLocalPort: repeaterLocalPort,
        repeaterRemoteAddress: repeaterRemoteAddress);
  }
}
