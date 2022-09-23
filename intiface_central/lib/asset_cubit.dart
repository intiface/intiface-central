import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    var newsAsset = await rootBundle.loadString('assets/news.md');
    var aboutAsset = await rootBundle.loadString('assets/about.md');
    var helpAsset = await rootBundle.loadString('assets/help.md');
    return AssetCubit(newsAsset, aboutAsset, helpAsset);
  }

  String get newsAsset => _newsAsset;
  String get aboutAsset => _aboutAsset;
  String get helpAsset => _helpAsset;
}
