import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/update/update_provider.dart';
import 'package:github/github.dart';
import 'package:loggy/loggy.dart';
import 'package:version/version.dart';

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

class IntifaceCentralDesktopUpdater extends GithubUpdater {
  late final Version _appVersion;
  IntifaceCentralDesktopUpdater(String appVersion) : super("intiface", "intiface-central") {
    _appVersion = Version.parse(appVersion);
  }

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

    return IntifaceCentralUpdateAvailable(repoVersion.toString());
  }
}
