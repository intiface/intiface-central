import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/update/update_provider.dart';

abstract class GithubUpdater implements UpdateProvider {
  String _githubUsername;
  String _githubRepo;

  GithubUpdater(this._githubUsername, this._githubRepo);

  Future<bool> checkForUpdate() async {
    return false;
  }

  Future<void> downloadAndInstallUpdates() async {}
}

class IntifaceEngineUpdater extends GithubUpdater {
  IntifaceEngineUpdater() : super("intiface", "intiface-engine");

  @override
  Future<UpdateState?> update() async {
    return null;
  }
}

class IntifaceCentralDesktopUpdater extends GithubUpdater {
  IntifaceCentralDesktopUpdater() : super("intiface", "intiface-central");

  @override
  Future<UpdateState?> update() async {
    return null;
  }
}
