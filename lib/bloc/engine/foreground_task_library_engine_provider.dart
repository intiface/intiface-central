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
  // Completed by _onReceiveTaskData when engineStarted is detected. start()
  // awaits this before returning, guaranteeing _shutdownSendPort is set when
  // stop() is called. stop() also awaits this if ports aren't ready yet (i.e.
  // stop() races with start() during the FGS boot window).
  Completer<void>? _portsReadyCompleter;

  @override
  Future<void> start({required EngineOptionsExternal options}) async {
    _processMessageStream.close();
    _processMessageStream = StreamController();
    _portsReadyCompleter = Completer<void>();
    await _startForegroundTask();
    await _portsReadyCompleter!.future;
    _portsReadyCompleter = null;
  }

  @override
  Future<bool> runtimeStarted() async {
    return await rustRuntimeStarted();
  }

  @override
  Future<void> stop() async {
    logInfo("ForegroundProvider.stop() called: _shutdownSendPort=${_shutdownSendPort != null ? 'SET' : 'NULL'}");
    if (_portsReadyCompleter != null) {
      // start() is still in the FGS boot window — await ports before sending shutdown.
      // This replaces the _pendingShutdown flag: same guarantee, no extra state.
      logWarning("ForegroundProvider.stop(): ports not ready yet, awaiting start completion");
      await _portsReadyCompleter!.future;
    }
    if (_shutdownCompleter != null) {
      // A shutdown is already in flight — join it instead of sending a second signal.
      logInfo("ForegroundProvider.stop(): shutdown already in flight, awaiting existing completer");
      await _shutdownCompleter!.future;
      return;
    }
    _shutdownCompleter = Completer<void>();
    _shutdownSendPort!.send(null);
    logInfo("Engine foreground stop request sent, awaiting completion");
    await _shutdownCompleter!.future;
    _shutdownCompleter = null;
    _shutdownSendPort = null;
    _serverSendPort = null;
    _backdoorSendPort = null;
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
    // Register BEFORE the isRunning check so we can receive the shutdown-complete
    // bool sent by the old FGS over _onReceiveTaskData.
    _registerReceivePort();

    var isRunning = await FlutterForegroundTask.isRunningService;
    logInfo("_startForegroundTask: isRunningService=$isRunning");
    if (isRunning) {
      final oldShutdownPort = IsolateNameServer.lookupPortByName(_kMainShutdownPortName);
      if (oldShutdownPort != null) {
        if (_shutdownCompleter != null) {
          // stop() already sent the shutdown signal to the old FGS — just wait for it.
          // Sending a second signal would cause the handler to call stopEngine() again
          // after RustLib.dispose(), potentially hitting the new runtime.
          logInfo("_startForegroundTask: stop() already in flight, awaiting its completion");
          await _shutdownCompleter!.future;
          logInfo("_startForegroundTask: in-flight stop completed");
        } else {
          // Truly stale FGS from a previous app session — no stop() in flight.
          // Use the graceful shutdown protocol: the handler calls stopEngine(),
          // awaits engineStopped, sends `false` back, we call stopService() and
          // complete _shutdownCompleter.
          logInfo("_startForegroundTask: found stale FGS shutdown port, requesting graceful stop");
          _shutdownCompleter = Completer<void>();
          oldShutdownPort.send(null);
          await _shutdownCompleter!.future;
          _shutdownCompleter = null;
          logInfo("_startForegroundTask: stale FGS stopped gracefully");
        }
      } else {
        // Edge case: service is running but its ports are gone (e.g. crashed).
        // Force-stop the service, then stop the Rust runtime directly if still up.
        logWarning("_startForegroundTask: stale FGS has no shutdown port, forcing stop");
        await FlutterForegroundTask.stopService();
        if (await rustRuntimeStarted()) {
          await stopEngine();
          const timeout = Duration(seconds: 5);
          final deadline = DateTime.now().add(timeout);
          while (await rustRuntimeStarted() && DateTime.now().isBefore(deadline)) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (await rustRuntimeStarted()) {
            logWarning("_startForegroundTask: Rust runtime still active after 5s timeout");
          }
        }
        logInfo("_startForegroundTask: forced stop complete");
      }
    }
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
      // Detect engineStarted directly here rather than relying on the repository
      // listener — this runs before the listener is attached, so it completes
      // _portsReadyCompleter independently of the repository message pipeline.
      if (_portsReadyCompleter != null && !_portsReadyCompleter!.isCompleted) {
        try {
          var engineMessage = EngineMessage.fromJson(jsonDecode(message));
          if (engineMessage.engineStarted != null) {
            _serverSendPort = IsolateNameServer.lookupPortByName(_kMainServerPortName);
            _backdoorSendPort = IsolateNameServer.lookupPortByName(_kMainBackdoorPortName);
            _shutdownSendPort = IsolateNameServer.lookupPortByName(_kMainShutdownPortName);
            logInfo("_onReceiveTaskData: engineStarted, ports: server=${_serverSendPort != null ? 'SET' : 'NULL'}, shutdown=${_shutdownSendPort != null ? 'SET' : 'NULL'}");
            _portsReadyCompleter!.complete();
          }
        } catch (_) {}
      }
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
