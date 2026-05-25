import 'package:flutter/widgets.dart';

class DocsScreenshotKeys {
  static const engineControlPanel = ValueKey<String>('docs.engineControlPanel');
  static const engineControlButton = ValueKey<String>(
    'docs.engineControlButton',
  );
  static const engineControlInfo = ValueKey<String>('docs.engineControlInfo');
  static const engineConnectionIcon = ValueKey<String>(
    'docs.engineConnectionIcon',
  );
  static const engineAppStatus = ValueKey<String>('docs.engineAppStatus');
  static const sideNavigation = ValueKey<String>('docs.sideNavigation');
  static const mobileNavigation = ValueKey<String>('docs.mobileNavigation');
  static const mainBody = ValueKey<String>('docs.mainBody');
  static const appModeSelector = ValueKey<String>('docs.appModeSelector');
  static const appModeSettingsBody = ValueKey<String>(
    'docs.appModeSettingsBody',
  );

  static ValueKey<String> deviceCardStatus(int index) =>
      ValueKey<String>('docs.deviceCard.$index.status');

  static ValueKey<String> deviceCardInfo(int index) =>
      ValueKey<String>('docs.deviceCard.$index.info');

  static ValueKey<String> deviceCardConnectionInfo(int index) =>
      ValueKey<String>('docs.deviceCard.$index.connectionInfo');

  static ValueKey<String> deviceCardObservability(int index) =>
      ValueKey<String>('docs.deviceCard.$index.observability');

  static const manageAdvancedDevicesCard = ValueKey<String>(
    'docs.manageAdvancedDevicesCard',
  );
  static const advancedDeviceTypeSimulated = ValueKey<String>(
    'docs.advancedDeviceType.simulated',
  );
  static const advancedDeviceTypeWebsocket = ValueKey<String>(
    'docs.advancedDeviceType.websocket',
  );
  static const advancedDeviceTypeSerial = ValueKey<String>(
    'docs.advancedDeviceType.serial',
  );
  static const advancedDeviceExistingDevices = ValueKey<String>(
    'docs.advancedDevice.existingDevices',
  );
  static const advancedDeviceAddDevice = ValueKey<String>(
    'docs.advancedDevice.addDevice',
  );

  static const deviceDetailInfo = ValueKey<String>('docs.deviceDetail.info');
  static const deviceDetailConfiguration = ValueKey<String>(
    'docs.deviceDetail.configuration',
  );

  static ValueKey<String> deviceDetailFeatureConfiguration(int index) =>
      ValueKey<String>('docs.deviceDetail.featureConfiguration.$index');

  static const logOptions = ValueKey<String>('docs.log.options');
  static const logMessages = ValueKey<String>('docs.log.messages');
}
