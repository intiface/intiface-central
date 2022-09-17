import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intiface_engine_flutter/intiface_engine_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  // You can request multiple permissions at once.
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
  //final init = api.setLibrarySink();
  //init.listen((s) => logger.i(s));

  var args = EngineOptionsExternal(
      serverName: "Flutter Server",
      crashReporting: false,
      websocketUseAllInterfaces: true,
      websocketPort: 12345,
      frontendInProcessChannel: false,
      maxPingTime: 0,
      allowRawMessages: false,
      logLevel: "INFO".toString(),
      useBluetoothLe: true,
      useSerialPort: false,
      useHid: false,
      useLovenseDongleSerial: false,
      useLovenseDongleHid: false,
      useXinput: false,
      useLovenseConnect: false,
      useDeviceWebsocketServer: false,
      crashMainThread: false,
      crashTaskThread: false);
  //var sink = api.setLibrarySink();
  //var init2 = api.init();
  //init2.listen((s) => logger.i(s));
  //sleep(const Duration(seconds: 2));
  var sink = api.runEngine(args: args);
  sink.listen((s) => logger.i(s));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  //final _btleplugtestPlugin = Btleplugtest();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    /*
    try {
      platformVersion = await _btleplugtestPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      */
    platformVersion = 'Failed to get platform version.';
    //}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
