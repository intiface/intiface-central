import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:isolate';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/src/rust/api/runtime.dart';
import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:intiface_central/src/rust/frb_generated.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

String _kMainBackdoorPortName = "intifaceCentralBackdoorMain";
String _kMainServerPortName = "intifaceCentralServerMain";
String _kMainShutdownPortName = "intifaceCentralShutdownMain";

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(IntifaceEngineTaskHandler());
}

class IntifaceEngineTaskHandler extends TaskHandler {
  final ReceivePort _serverMessageReceivePort;
  final ReceivePort _backdoorMessageReceivePort;
  final ReceivePort _shutdownReceivePort;
  Stream<String>? _stream;
  final Completer<void> _serverExited = Completer();

  void _sendProviderLog(String level, String outgoingMessage) {
    var message = EngineProviderLog();
    message.timestamp = DateTime.now().toString();
    message.level = level;
    message.message = outgoingMessage;
    var engineMessage = EngineMessage();
    engineMessage.engineProviderLog = message;
    FlutterForegroundTask.sendDataToMain(jsonEncode(engineMessage));
  }

  IntifaceEngineTaskHandler()
    : _serverMessageReceivePort = ReceivePort(),
      _backdoorMessageReceivePort = ReceivePort(),
      _shutdownReceivePort = ReceivePort() {
    final serverSendPort = _serverMessageReceivePort.sendPort;
    final backdoorSendPort = _backdoorMessageReceivePort.sendPort;
    final shutdownSendPort = _shutdownReceivePort.sendPort;
    // Defensively remove any stale mappings before registering. registerPortWithName()
    // returns false without overwriting if a name is already taken, so without this
    // a restarted service would silently fail to register its ports.
    IsolateNameServer.removePortNameMapping(_kMainServerPortName);
    IsolateNameServer.removePortNameMapping(_kMainBackdoorPortName);
    IsolateNameServer.removePortNameMapping(_kMainShutdownPortName);
    IsolateNameServer.registerPortWithName(serverSendPort, _kMainServerPortName);
    IsolateNameServer.registerPortWithName(backdoorSendPort, _kMainBackdoorPortName);
    IsolateNameServer.registerPortWithName(shutdownSendPort, _kMainShutdownPortName);
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sendProviderLog("Info", "Trying to start engine in foreground service.");
    await RustLib.init();

    // Due to the way the foregrounding package we're using works, we can't store the options across the foregrounding
    // process boundary. Trying to encode to/decode from JSON also isn't easily possible because EngineOptionsExternal
    // is a FFI generated class. Therefore we just bring up what is considered to be a readonly version of our config
    // repo in order to build the engine options, then we just drop it when done.
    //
    // Under the covers, flutter_foreground_task is just using SharedPreferences for its data commands anyways, so this
    // is basically doing what it does, while not having to deal with shuffling things around.
    _sendProviderLog("INFO", "Creating config repo");
    var configRepo = await IntifaceConfigurationCubit.create();
    _sendProviderLog("INFO", "Building arguments");

    // Since we're on another process we'll have to reinitialize our paths.
    await IntifacePaths.init();

    // Ok, NOW we can build our engine options.
    var engineOptions = await configRepo.getEngineOptions();
    _sendProviderLog("INFO", "Starting engine");

    _sendProviderLog(
      "INFO",
      "Starting library internal engine with the following arguments: $engineOptions",
    );
    try {
      _stream = runEngine(args: engineOptions);
    } catch (e) {
      _sendProviderLog("ERROR", "Engine start failed!");
      return;
    }
    _sendProviderLog("INFO", "Engine started");
    _stream!.listen((element) {
      try {
        // Send first
        FlutterForegroundTask.sendDataToMain(element);
        // Then check to see if this is a EngineStopped message.
        // Try parsing the JSON first to make sure it's even valid JSON.
        var jsonElement = jsonDecode(element);
        var message = EngineMessage.fromJson(jsonElement);
        if (message.engineStopped != null) {
          _serverExited.complete();
        }
      } catch (e) {
        // There's a chance the message may not decode it could possibly be from the backend server. So just no-op here.
      }
    });
    _serverMessageReceivePort.listen((element) async {
      await sendRuntimeMsg(msgJson: element);
    });
    _backdoorMessageReceivePort.listen((element) async {
      await sendBackendServerMessage(msg: element);
    });
    _shutdownReceivePort.listen((element) async {
      _sendProviderLog("INFO", "Engine shutdown request received");
      await stopEngine();
      await _serverExited.future;
      _sendProviderLog("INFO", "Engine shutdown successful");
      // We'll never send a bool type over this port otherwise, so we can use that as a trigger to say we're done.
      FlutterForegroundTask.sendDataToMain(false);
      RustLib.dispose();
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Send data to the main isolate.
    //sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool whatever) async {
    _sendProviderLog("INFO", "Shutting down foreground task");
    // Only remove port mappings that still point to OUR ports. If a new
    // ForegroundService instance started before onDestroy() fires, it already
    // removed our mappings and registered its own. Unconditionally removing
    // here would steal the new instance's ports, making its shutdown port
    // unreachable and causing _shutdownCompleter to wait forever.
    if (IsolateNameServer.lookupPortByName(_kMainServerPortName) ==
        _serverMessageReceivePort.sendPort) {
      IsolateNameServer.removePortNameMapping(_kMainServerPortName);
    }
    if (IsolateNameServer.lookupPortByName(_kMainBackdoorPortName) ==
        _backdoorMessageReceivePort.sendPort) {
      IsolateNameServer.removePortNameMapping(_kMainBackdoorPortName);
    }
    if (IsolateNameServer.lookupPortByName(_kMainShutdownPortName) ==
        _shutdownReceivePort.sendPort) {
      IsolateNameServer.removePortNameMapping(_kMainShutdownPortName);
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == "stopServerButton") {
      FlutterForegroundTask.stopService();
    } else {
      // Called when the notification button on the Android platform is pressed.
      _sendProviderLog("ERROR", "Button id $id not recognized");
    }
  }
}

class ForegroundTaskLibraryEngineProvider implements EngineProvider {
  StreamController<String> _processMessageStream = StreamController();
  ReceivePort? _receivePort;
  SendPort? _serverSendPort;
  SendPort? _backdoorSendPort;
  SendPort? _shutdownSendPort;
  Completer<void>? _shutdownCompleter;
  // Set when stop() is called before the shutdown port is ready. onEngineStart()
  // checks this and sends the shutdown signal as soon as the port becomes available.
  bool _pendingShutdown = false;

  @override
  Future<void> start({required EngineOptionsExternal options}) async {
    await _startForegroundTask();
  }

  @override
  Future<bool> runtimeStarted() async {
    return await rustRuntimeStarted();
  }

  @override
  void cycleStream() {
    _processMessageStream.close();
    _processMessageStream = StreamController();
  }

  @override
  void onEngineStart() {
    _serverSendPort = IsolateNameServer.lookupPortByName(_kMainServerPortName);
    _backdoorSendPort = IsolateNameServer.lookupPortByName(_kMainBackdoorPortName);
    _shutdownSendPort = IsolateNameServer.lookupPortByName(_kMainShutdownPortName);
    logInfo("onEngineStart(): server=${_serverSendPort != null ? 'SET' : 'NULL'}, backdoor=${_backdoorSendPort != null ? 'SET' : 'NULL'}, shutdown=${_shutdownSendPort != null ? 'SET' : 'NULL'}, pendingShutdown=$_pendingShutdown");
    if (_pendingShutdown && _shutdownSendPort != null) {
      // stop() was called before the shutdown port was ready. Now that we have the
      // port, send the graceful shutdown immediately. This ensures stop_engine() is
      // called on the Rust side, which clears RUNTIME/RUN_STATUS. A force-stop via
      // stopService() would skip stop_engine() and leave those globals set, causing
      // the next run_engine() call to fail with "Server already running!".
      logInfo("onEngineStart(): executing pending shutdown request");
      _shutdownSendPort!.send(null);
    }
  }

  @override
  void onEngineStop() {
    logInfo("onEngineStop(): clearing send ports");
    _serverSendPort = null;
    _backdoorSendPort = null;
  }

  @override
  Future<void> stop() async {
    logInfo("ForegroundProvider.stop() called: _shutdownSendPort=${_shutdownSendPort != null ? 'SET' : 'NULL'}, _serverSendPort=${_serverSendPort != null ? 'SET' : 'NULL'}");
    if (_shutdownCompleter != null) {
      // A concurrent stop() is already in progress. Join it rather than
      // creating a second Completer — overwriting the field would orphan the
      // first Completer and leave that caller awaiting a future that never
      // completes (deadlock).
      logInfo("ForegroundProvider.stop(): already stopping, joining existing shutdown");
      await _shutdownCompleter!.future;
      return;
    }
    _shutdownCompleter = Completer<void>();
    if (_shutdownSendPort == null) {
      // Foreground service is still starting — shutdown port not registered yet.
      // Set the pending flag; onEngineStart() will send the signal as soon as the
      // port is available. We then wait on the same completer as normal shutdown.
      logWarning("ForegroundProvider.stop(): shutdown port not ready, queuing graceful shutdown");
      _pendingShutdown = true;
    } else {
      _shutdownSendPort!.send(null);
    }
    logInfo("Engine foreground stop request sent, awaiting completion");
    await _shutdownCompleter!.future;
    _pendingShutdown = false;
    _shutdownCompleter = null;
    _shutdownSendPort = null;
    logInfo("Engine foreground stop completed");
  }

  @override
  void send(String msg) {
    _serverSendPort!.send(msg);
  }

  @override
  void sendBackdoorMessage(String msg) {
    _backdoorSendPort!.send(msg);
  }

  Future<ServiceRequestResult> _startForegroundTask() async {
    var isRunning = await FlutterForegroundTask.isRunningService;
    logInfo("_startForegroundTask: isRunningService=$isRunning");
    if (isRunning) {
      // Do NOT use restartService() — it starts the new instance before the old one's
      // onDestroy runs, causing two concurrent IntifaceEngineTaskHandlers. The new
      // instance's IsolateNameServer.registerPortWithName() calls silently fail (returns
      // false) because the old instance's ports are still registered, leaving the new
      // service completely unreachable. Force a clean stop first.
      logInfo("_startForegroundTask: stopping existing service before fresh start");
      await FlutterForegroundTask.stopService();
      logInfo("_startForegroundTask: existing service stopped");
    }
    // Register the data callback BEFORE starting the service so that messages
    // sent by the FGS during onStart() are received. startService() suspends
    // the Dart event loop, allowing FGS messages to arrive and be dispatched
    // before startService() returns; without pre-registration those messages
    // are silently dropped.
    _registerReceivePort();
    logInfo("_startForegroundTask: calling startService()");
    var reqResult = await FlutterForegroundTask.startService(
      notificationTitle: 'Intiface Engine is running',
      notificationText: 'Tap to return to the app',
      notificationButtons: [
        const NotificationButton(id: 'stopServerButton', text: 'Stop Server'),
      ],
      callback: startCallback,
    );

    return reqResult;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  void _onReceiveTaskData(message) {
    if (message is String) {
      _processMessageStream.add(message);
    } else if (message is bool) {
      logInfo("_onReceiveTaskData: bool received (shutdown complete signal), _shutdownCompleter=${_shutdownCompleter != null ? 'SET' : 'NULL'}");
      logInfo("Shutdown complete message received, stopping foreground task.");
      // Complete the shutdown completer only AFTER the foreground service is fully stopped.
      // This ensures isRunningService returns false before stop() unblocks, so any
      // subsequent _startForegroundTask() sees a clean state and calls startService()
      // rather than trying to stop a still-running service again.
      FlutterForegroundTask.stopService().then((_) {
        logInfo("Foreground task shutdown complete.");
        _shutdownCompleter?.complete();
      });
    }
  }

  void _registerReceivePort() {
    // Remove the task if it already exists, just to make sure to clear things out.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
