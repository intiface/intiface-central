import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:intl/intl.dart';

const String userDeviceConfigFilename = 'buttplug-user-device-config-v3.json';
const String deviceConfigFilename = 'buttplug-device-config-v3.json';
const String intifaceNewsFilename = 'intiface.news.md';
const String intifaceAppDirectoryName = 'IntifaceCentralFlutter';
const String intifaceConfigDirectoryName = 'config';
const String intifaceLoggingDirectoryName = 'logs';
const String intifaceNewsDirectoryName = 'news';
const String intifaceEngineDirectoryName = 'engine';
const String intifaceEngineFilename = 'intiface-engine';

class IntifacePaths {
  static late Directory _configPath;
  static late Directory _logPath;
  static late File _logFile;
  static late File _deviceConfigFile;
  static late File _userDeviceConfigFile;
  static late Directory _enginePath;
  static late File _engineFile;
  static late Directory _newsPath;
  static late File _newsFile;
  static Directory get configPath => IntifacePaths._configPath;
  static Directory get logPath => IntifacePaths._logPath;
  static File get logFile => IntifacePaths._logFile;
  static File get deviceConfigFile => IntifacePaths._deviceConfigFile;
  static File get userDeviceConfigFile => IntifacePaths._userDeviceConfigFile;
  static Directory get enginePath => IntifacePaths._enginePath;
  static File get engineFile => IntifacePaths._engineFile;
  static Directory get newsPath => IntifacePaths._newsPath;
  static File get newsFile => IntifacePaths._newsFile;
  static Future<void> init() async {
    (await getApplicationSupportDirectory()).create(recursive: true);

    var docsDir = (await getApplicationSupportDirectory()).path;

    IntifacePaths._configPath = Directory(p.join(docsDir, intifaceConfigDirectoryName));
    await IntifacePaths._configPath.create(recursive: true);

    IntifacePaths._logPath = Directory(p.join(docsDir, intifaceLoggingDirectoryName));
    await IntifacePaths._logPath.create(recursive: true);

    // Take care of eliminating old log files here. Since we store date/time in their name, we can just use that.
    var logFiles = IntifacePaths.logPath.listSync(followLinks: false, recursive: false);
    // Only keep last 5 log files.
    if (logFiles.length >= 5) {
      FileSystemEntity oldestFile = logFiles[0];
      for (var file in logFiles) {
        if (oldestFile.path.compareTo(file.path) > 0) {
          oldestFile = file;
        }
      }
      await oldestFile.delete();
    }

    final formatter = NumberFormat("00");
    final now = DateTime.now();
    var logFilename =
        "intiface-central-${now.year}-${formatter.format(now.month)}-${formatter.format(now.day)}-${formatter.format(now.hour)}-${formatter.format(now.minute)}-${formatter.format(now.second)}.log";
    IntifacePaths._logFile = File(p.join(IntifacePaths._logPath.path, logFilename));
    await IntifacePaths._logFile.create();

    IntifacePaths._deviceConfigFile = File(p.join(IntifacePaths._configPath.path, deviceConfigFilename));
    IntifacePaths._userDeviceConfigFile = File(p.join(IntifacePaths._configPath.path, userDeviceConfigFilename));

    IntifacePaths._enginePath = Directory(p.join(docsDir, intifaceEngineDirectoryName));
    await IntifacePaths._enginePath.create(recursive: true);

    IntifacePaths._engineFile = File(p.join(
        IntifacePaths._enginePath.path, Platform.isWindows ? "$intifaceEngineFilename.exe" : intifaceEngineFilename));

    IntifacePaths._newsPath = Directory(p.join(docsDir, intifaceNewsDirectoryName));
    await IntifacePaths._newsPath.create(recursive: true);

    IntifacePaths._newsFile = File(p.join(IntifacePaths._newsPath.path, intifaceNewsFilename));
  }
}

bool isDesktop() => Platform.isLinux || Platform.isMacOS || Platform.isWindows;
bool isMobile() => Platform.isAndroid || Platform.isIOS;
bool canShowUpdate() => !(const bool.fromEnvironment('NO_VISIBLE_UPDATES'));
