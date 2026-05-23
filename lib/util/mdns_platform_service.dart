import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

class MdnsPlatformService {
  MdnsPlatformService._();

  static final MdnsPlatformService instance = MdnsPlatformService._();
  static const MethodChannel _channel = MethodChannel(
    'com.nonpolynomial.intiface_central/mdns_platform_service',
  );

  Future<bool> acquireMdnsMulticastLock() async {
    return _invokeWithoutThrowing('acquireMdnsMulticastLock');
  }

  Future<bool> releaseMdnsMulticastLock() async {
    return _invokeWithoutThrowing('releaseMdnsMulticastLock');
  }

  Future<bool> startMdnsPublisher({
    required String serviceType,
    required String instanceName,
    required int port,
    required List<String> txtRecords,
  }) async {
    return _invokeWithoutThrowing('startMdnsPublisher', {
      'serviceType': serviceType,
      'instanceName': instanceName,
      'port': port,
      'txtRecords': txtRecords,
    });
  }

  Future<bool> stopMdnsPublisher() async {
    return _invokeWithoutThrowing('stopMdnsPublisher');
  }

  Future<bool> _invokeWithoutThrowing(
    String method, [
    Object? arguments,
  ]) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>(method, arguments);
      if (result != true) {
        logError('mDNS platform method $method reported failure.');
        return false;
      }
      return true;
    } on PlatformException catch (e, st) {
      logError('mDNS platform method $method failed.', e, st);
    } catch (e, st) {
      logError(
        'mDNS platform method $method threw an unexpected error.',
        e,
        st,
      );
    }
    return false;
  }
}
