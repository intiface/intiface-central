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

  HttpUpdateProvider(this._localFile, this._updateUrl, this._expectedVersion);

  Future<String?> internalUpdate() async {
    // Insert our currently expected verison as the etag header
    logDebug("Running HTTP Update for $_updateUrl with expected version $_expectedVersion");
    HttpClient client = HttpClient();

    HttpClientRequest req = await client.getUrl(Uri.parse(_updateUrl));
    // If we don't have a copy of the file locally, skip our version check and always download it.
    if (await _localFile.exists()) {
      req.headers.add(HttpHeaders.ifNoneMatchHeader, _expectedVersion);
    }
    HttpClientResponse response = await req.close();
    if (response.statusCode == 200) {
      final etag = response.headers.value(HttpHeaders.etagHeader);
      final stringData = await response.transform(utf8.decoder).join();
      await _localFile.writeAsString(stringData);
      _expectedVersion = etag!;
      logInfo("HTTP Update for $_updateUrl found new version $_expectedVersion");
      return etag;
    }
    logDebug("No new version for $_updateUrl found");
    return null;
  }
}

class NewsUpdateProvider extends HttpUpdateProvider {
  NewsUpdateProvider(String expectedVersion)
      : super(IntifacePaths.newsFile, "https://intiface-central-news.intiface.com/news.md", expectedVersion);

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
      : super(IntifacePaths.deviceConfigFile,
            "https://intiface-engine-device-config.intiface.com/buttplug-device-config-v3.json", expectedVersion);

  @override
  Future<UpdateState?> update() async {
    var etag = await internalUpdate();
    if (etag != null) {
      return DeviceConfigUpdateRetrieved(etag);
    }
    return null;
  }
}
