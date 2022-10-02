import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intiface_central/util/intiface_util.dart';

class AssetEvent {}

class AssetLoadingEvent extends AssetEvent {}

class AssetLoadedEvent extends AssetEvent {}

class AssetUpdatedEvent extends AssetEvent {}

class AssetCubit extends Cubit<AssetEvent> {
  String _newsAsset;
  final String _aboutAsset;
  final String _helpAsset;

  AssetCubit(this._newsAsset, this._aboutAsset, this._helpAsset) : super(AssetLoadingEvent());

  static Future<AssetCubit> create() async {
    var newsAsset = await IntifacePaths.newsFile.exists()
        ? await IntifacePaths.newsFile.readAsString()
        : await rootBundle.loadString('assets/news.md');
    var aboutAsset = await rootBundle.loadString('assets/about.md');
    var helpAsset = await rootBundle.loadString('assets/help.md');
    return AssetCubit(newsAsset, aboutAsset, helpAsset);
  }

  Future<void> update() async {
    _newsAsset = await IntifacePaths.newsFile.exists()
        ? await IntifacePaths.newsFile.readAsString()
        : await rootBundle.loadString('assets/news.md');
  }

  String get newsAsset => _newsAsset;
  String get aboutAsset => _aboutAsset;
  String get helpAsset => _helpAsset;
}
