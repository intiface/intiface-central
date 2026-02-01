import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/update/update_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

abstract class HttpUpdateProvider implements UpdateProvider {
  final File _localFile;
  final String _updateUrl;
  String _expectedVersion;

  // Timeout for network operations to prevent hanging on slow/unresponsive servers
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _responseTimeout = Duration(seconds: 15);

  HttpUpdateProvider(this._localFile, this._updateUrl, this._expectedVersion);

  Future<String?> internalUpdate() async {
    // Insert our currently expected verison as the etag header
    logDebug(
      "Running HTTP Update for $_updateUrl with expected version $_expectedVersion",
    );
    HttpClient client = HttpClient();
    client.connectionTimeout = _connectionTimeout;

    try {
      HttpClientRequest req = await client
          .getUrl(Uri.parse(_updateUrl))
          .timeout(_connectionTimeout);
      // If we don't have a copy of the file locally, skip our version check and always download it.
      if (await _localFile.exists()) {
        req.headers.add(HttpHeaders.ifNoneMatchHeader, _expectedVersion);
      }
      HttpClientResponse response = await req.close().timeout(_responseTimeout);
      if (response.statusCode == 200) {
        final etag = response.headers.value(HttpHeaders.etagHeader);
        final stringData = await response
            .transform(utf8.decoder)
            .join()
            .timeout(_responseTimeout);
        await _localFile.writeAsString(stringData);
        _expectedVersion = etag!;
        logInfo(
          "HTTP Update for $_updateUrl found new version $_expectedVersion",
        );
        return etag;
      }
      logDebug("No new version for $_updateUrl found");
      return null;
    } on SocketException catch (e) {
      // Network errors (connection refused, reset, etc.) - non-fatal for updates
      logWarning("Network error checking for updates at $_updateUrl: $e");
      return null;
    } on TimeoutException catch (e) {
      // Request timed out - non-fatal for updates
      logWarning("Timeout checking for updates at $_updateUrl: $e");
      return null;
    } on HttpException catch (e) {
      // HTTP protocol errors - non-fatal for updates
      logWarning("HTTP error checking for updates at $_updateUrl: $e");
      return null;
    } finally {
      client.close();
    }
  }
}

class NewsUpdateProvider extends HttpUpdateProvider {
  NewsUpdateProvider(String expectedVersion)
    : super(
        IntifacePaths.newsFile,
        "https://intiface-central-news.intiface.com/news.md",
        expectedVersion,
      );

  @override
  Future<UpdateState?> update() async {
    var etag = await internalUpdate();
    if (etag != null) {
      return NewsUpdateRetrieved(etag);
    }
    return null;
  }
}

class DeviceConfigUpdateProvider extends HttpUpdateProvider {
  DeviceConfigUpdateProvider(String expectedVersion)
    : super(
        IntifacePaths.deviceConfigFile,
        "https://intiface-engine-device-config.intiface.com/buttplug-device-config-v4.json",
        expectedVersion,
      );

  @override
  Future<UpdateState?> update() async {
    var etag = await internalUpdate();
    if (etag != null) {
      return DeviceConfigUpdateRetrieved(etag);
    }
    return null;
  }
}
