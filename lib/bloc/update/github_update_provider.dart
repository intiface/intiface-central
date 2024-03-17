import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/update/update_provider.dart';
import 'package:github/github.dart';
import 'package:loggy/loggy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:version/version.dart';
import 'package:path/path.dart' as Path;

const maxEngineVersion = 1;

abstract class GithubUpdater implements UpdateProvider {
  final String _githubUsername;
  final String _githubRepo;
  bool _shouldExit = true;

  GithubUpdater(this._githubUsername, this._githubRepo);

  Future<String?> checkForUpdate() async {
    GitHub github = GitHub(auth: findAuthenticationFromEnvironment());
    var release = await github.repositories.getLatestRelease(RepositorySlug(_githubUsername, _githubRepo));
    return release.tagName;
  }

  void stopExit() {
    _shouldExit = false;
  }

  Future<void> downloadUpdate() async {
    // This should only ever run on windows. Everyone else is either updating via a mobile app or can download manually
    // because this absolutely will not work on their platforms.
    if (Platform.isWindows) {
      GitHub github = GitHub(auth: findAuthenticationFromEnvironment());
      logInfo("Running application update. Getting file from Github.");
      var release = await github.repositories.getLatestRelease(RepositorySlug(_githubUsername, _githubRepo));
      if (release.assets != null) {
        for (var asset in release.assets!) {
          // This is a horrible way to find the windows binary, but it works for now.
          if (asset.name != null && asset.name!.contains("-win-") && asset.browserDownloadUrl != null) {
            HttpClient client = HttpClient();
            try {
              var request = await client.getUrl(Uri.parse(asset.browserDownloadUrl!));
              var response = await request.close();
              var bytes = await consolidateHttpClientResponseBytes(response);
              final dir = await getTemporaryDirectory();
              {
                File file = File(Path.join(dir.path, asset.name!));
                await file.writeAsBytes(bytes);
                logInfo("Updated IC Installer Path: ${file.path}");
                if (_shouldExit) {
                  Process.run(file.path, []);
                  // Wait a sec for the installer to come up.
                  await Future.delayed(const Duration(seconds: 1));
                  // Check twice for shouldExit, since we have a delay after the process launch.
                  if (_shouldExit) {
                    exit(0);
                  }
                }
              }
            } catch (error) {
              logError('Error downloading update: $error');
            }
          }
        }
      }
    }
  }
}

class IntifaceCentralDesktopUpdater extends GithubUpdater {
  IntifaceCentralDesktopUpdater() : super("intiface", "intiface-central");

  @override
  Future<UpdateState?> update() async {
    logInfo("Checking for application update");
    var latestVersion = await checkForUpdate();
    if (latestVersion == null) {
      logError("Cannot retreive latest application version");
      return null;
    }
    // Strip the "v" off the front.
    var strippedVersion = latestVersion.substring(1);
    var repoVersion = Version.parse(strippedVersion);
    logInfo("Current application version for remote download: ${repoVersion.toString()}");
    return IntifaceCentralUpdateAvailable(repoVersion.toString());
  }
}
