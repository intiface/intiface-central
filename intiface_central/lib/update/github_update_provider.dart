import 'dart:io';

import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/update/update_provider.dart';
import 'package:github/github.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:version/version.dart';
import 'package:archive/archive_io.dart' as archive;
import 'package:http/http.dart';

const maxEngineVersion = 1;

abstract class GithubUpdater implements UpdateProvider {
  final String _githubUsername;
  final String _githubRepo;

  GithubUpdater(this._githubUsername, this._githubRepo);

  Future<String?> checkForUpdate() async {
    GitHub github = GitHub(auth: findAuthenticationFromEnvironment());
    var release = await github.repositories.getLatestRelease(RepositorySlug(_githubUsername, _githubRepo));
    return release.tagName;
  }
}

class IntifaceEngineUpdater extends GithubUpdater {
  late Version _engineVersion;
  late final String _engineFilename;

  IntifaceEngineUpdater(String engineVersion) : super("intiface", "intiface-engine") {
    _engineVersion = Version.parse(engineVersion);
    var platform = "win-x64";
    if (Platform.isMacOS) {
      platform = "macos-x64";
    } else if (Platform.isLinux) {
      platform = "linux-x64";
    }
    _engineFilename = "intiface-engine-$platform-Release.zip";
  }

  @override
  Future<UpdateState?> update() async {
    logInfo("Checking for engine update");
    var latestVersion = await checkForUpdate();
    if (latestVersion == null) {
      logError("Cannot retreive latest engine version");
      return null;
    }
    // Strip the "v" off the front.
    var strippedVersion = latestVersion.substring(1);
    var repoVersion = Version.parse(strippedVersion);
    if (_engineVersion.major == 0 || (repoVersion.major == maxEngineVersion && repoVersion > _engineVersion)) {
      logInfo("Engine update required.");
      // Pull the file to a temp dir
      GitHub github = GitHub(auth: findAuthenticationFromEnvironment());
      var release = await github.repositories.getLatestRelease(RepositorySlug(_githubUsername, _githubRepo));
      String? assetUrl;
      for (var asset in release.assets!) {
        if (asset.name == _engineFilename) {
          assetUrl = asset.browserDownloadUrl!;
          break;
        }
      }
      if (assetUrl == null) {
        return null;
      }
      // Download it
      final List<int> downloadData = [];
      final client = Client();
      final request = Request('GET', Uri.parse(assetUrl));
      final response = await client.send(request);
      final stream = response.stream;
      await for (var data in stream) {
        downloadData.addAll(data);
      }
      client.close();
      // Unzip it
      final zipArchive = archive.ZipDecoder().decodeBytes(downloadData);
      archive.extractArchiveToDisk(zipArchive, IntifacePaths.enginePath.path);
      _engineVersion = repoVersion;
      logInfo("Engine downloaded");
      return IntifaceEngineUpdateRetrieved(strippedVersion);
    } else if (repoVersion.major > maxEngineVersion) {
      logError(
          "Intiface Engine has a major version update ($strippedVersion) and requires a new version of Intiface Central. Please update Intiface Central.");
      return IncompatibleIntifaceEngineUpdate(strippedVersion);
    }
    logInfo("Current engine is up to date.");
    return null;
  }
}

class IntifaceCentralDesktopUpdater extends GithubUpdater {
  late final Version _appVersion;
  IntifaceCentralDesktopUpdater(String appVersion) : super("intiface", "intiface-central") {
    _appVersion = Version.parse(appVersion);
  }

  @override
  Future<UpdateState?> update() async {
    logInfo("Checking for engine update");
    var latestVersion = await checkForUpdate();
    if (latestVersion == null) {
      logError("Cannot retreive latest engine version");
      return null;
    }
    // Strip the "v" off the front.
    var strippedVersion = latestVersion.substring(1);
    var repoVersion = Version.parse(strippedVersion);

    if (repoVersion != _appVersion) {
      return IntifaceCentralUpdateAvailable(repoVersion.toString());
    }
    return null;
  }
}
