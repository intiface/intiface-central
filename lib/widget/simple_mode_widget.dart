import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:loggy/loggy.dart';

enum SimpleModeStep { startServer, startScanning, connectingDevices }

class SimpleModeWidget extends StatefulWidget {
  const SimpleModeWidget({super.key});

  @override
  State<SimpleModeWidget> createState() => _SimpleModeWidgetState();
}

class _SimpleModeWidgetState extends State<SimpleModeWidget> with UiLoggy {
  bool _hasTriggeredAutoStart = false;
  Timer? _scanRetryTimer;
  Timer? _engineCheckTimer;

  @override
  void initState() {
    super.initState();
    // Wait for app initialization to complete before starting auto-start sequence
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _autoStartSequence();
      }
    });
  }

  @override
  void dispose() {
    _scanRetryTimer?.cancel();
    _engineCheckTimer?.cancel();
    super.dispose();
  }

  void _autoStartSequence() async {
    if (_hasTriggeredAutoStart) return;
    _hasTriggeredAutoStart = true;

    final engineBloc = BlocProvider.of<EngineControlBloc>(context);
    final configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);

    loggy.debug("SimpleModeWidget: Starting auto-start sequence");
    loggy.debug("SimpleModeWidget: Engine isRunning = ${engineBloc.isRunning}");

    // Start server if not running
    if (!engineBloc.isRunning) {
      loggy.debug("SimpleModeWidget: Starting engine...");
      engineBloc.add(
        EngineControlEventStart(options: await configCubit.getEngineOptions()),
      );
    }

    // Start polling to check when we can start scanning
    _startEngineCheckTimer();
  }

  void _startEngineCheckTimer() {
    _engineCheckTimer?.cancel();

    // Wait 1 second before starting to check, to give the engine time to fully initialize
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      _engineCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final engineBloc = BlocProvider.of<EngineControlBloc>(context);
        final deviceManagerBloc = BlocProvider.of<DeviceManagerBloc>(context);

        loggy.debug("SimpleModeWidget: Check - isRunning=${engineBloc.isRunning}, scanning=${deviceManagerBloc.scanning}, devices=${deviceManagerBloc.devices.length}");

        // If engine is running and we're not scanning yet, try to start scanning
        if (engineBloc.isRunning && !deviceManagerBloc.scanning) {
          loggy.debug("SimpleModeWidget: Engine running, attempting to start scanning...");
          deviceManagerBloc.add(DeviceManagerStartScanningEvent());
        }

        // If scanning has started, stop the timer
        if (deviceManagerBloc.scanning) {
          loggy.debug("SimpleModeWidget: Scanning started successfully!");
          timer.cancel();
          // Force UI rebuild
          if (mounted) {
            setState(() {});
          }
          return;
        }

        // Give up after 30 seconds (60 retries at 500ms)
        if (timer.tick > 60) {
          loggy.warning("SimpleModeWidget: Gave up trying to start scanning after 30 seconds");
          timer.cancel();
        }
      });
    });
  }

  SimpleModeStep _getCurrentStep(bool engineRunning, bool isScanning, List devices) {
    if (!engineRunning) {
      return SimpleModeStep.startServer;
    }

    if (!isScanning && devices.isEmpty) {
      return SimpleModeStep.startScanning;
    }

    return SimpleModeStep.connectingDevices;
  }

  String _getStatusMessage(SimpleModeStep step, List devices) {
    switch (step) {
      case SimpleModeStep.startServer:
        return 'Starting server...';
      case SimpleModeStep.startScanning:
        return 'Starting device scanning...';
      case SimpleModeStep.connectingDevices:
        if (devices.isEmpty) {
          return 'Turn on the device and wait for the device to connect!';
        } else {
          return 'Device connected!';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (previous, current) =>
          current is EngineStartingState ||
          current is EngineStartedState ||
          current is EngineStoppedState ||
          current is EngineServerCreatedState ||
          current is ClientConnectedState ||
          current is ClientDisconnectedState ||
          current is DeviceConnectedState ||
          current is DeviceDisconnectedState,
      builder: (context, engineState) {
        return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
          buildWhen: (previous, current) =>
              current is DeviceManagerDeviceOnlineState ||
              current is DeviceManagerDeviceOfflineState ||
              current is DeviceManagerStartScanningState ||
              current is DeviceManagerStopScanningState,
          builder: (context, deviceState) {
            final engineBloc = BlocProvider.of<EngineControlBloc>(context);
            final deviceManagerBloc = BlocProvider.of<DeviceManagerBloc>(context);
            final devices = deviceManagerBloc.devices;
            final isScanning = deviceManagerBloc.scanning;
            final engineRunning = engineBloc.isRunning;
            final currentStep = _getCurrentStep(engineRunning, isScanning, devices);

            loggy.debug("SimpleModeWidget: Build - devices=${devices.length}, deviceState=$deviceState, engineState=$engineState");

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildStepper(currentStep, devices.isNotEmpty),
                  const SizedBox(height: 20),
                  _buildStatusMessage(currentStep, devices),
                  const SizedBox(height: 20),
                  if (devices.isNotEmpty) _buildDeviceList(devices),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepper(SimpleModeStep currentStep, bool hasDevices) {
    final isStep1Complete =
        currentStep == SimpleModeStep.startScanning || currentStep == SimpleModeStep.connectingDevices;
    final isStep2Complete = currentStep == SimpleModeStep.connectingDevices;
    final isStep3Complete = hasDevices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle('1', 'Start Server', isStep1Complete, currentStep == SimpleModeStep.startServer),
          _buildStepLine(isStep1Complete),
          _buildStepCircle('2', 'Start Scanning', isStep2Complete, currentStep == SimpleModeStep.startScanning),
          _buildStepLine(isStep2Complete),
          _buildStepCircle('3', 'Connecting Devices', isStep3Complete, currentStep == SimpleModeStep.connectingDevices),
        ],
      ),
    );
  }

  Widget _buildStepCircle(String stepNumber, String label, bool isComplete, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? Colors.green : (isActive ? colorScheme.primary.withOpacity(0.3) : Colors.grey.shade300),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 40)
                : (isActive
                    ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : Text(
                        '...',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 20),
                      )),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$stepNumber. $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isComplete ? Colors.green : (isActive ? colorScheme.primary : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isComplete) {
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.only(bottom: 28),
        color: isComplete ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStatusMessage(SimpleModeStep step, List devices) {
    final message = _getStatusMessage(step, devices);
    final isSuccess = devices.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.info,
            color: isSuccess ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isSuccess ? Colors.green.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Connected Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        ...devices.map((deviceCubit) {
          final device = deviceCubit.device;
          if (device == null) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Index: ${device.index} - Base Name: ${device.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  DeviceControlWidget(deviceCubit: deviceCubit),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
