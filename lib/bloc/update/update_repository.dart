import 'package:intiface_central/bloc/update/http_update_provider.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/update/update_provider.dart';
import 'package:loggy/loggy.dart';

class UpdateRepository {
  final List<UpdateProvider> _providers = [];

  UpdateRepository(String newsVersion, String deviceConfigVersion) {
    _providers.add(NewsUpdateProvider(newsVersion));
    _providers.add(DeviceConfigUpdateProvider(deviceConfigVersion));
  }

  void addProvider(UpdateProvider provider) {
    _providers.add(provider);
  }

  Future<List<UpdateState>> update() async {
    List<UpdateState> events = [];
    for (var provider in _providers) {
      try {
        var state = await provider.update();
        if (state != null) {
          events.add(state);
        }
      } catch (e, stack) {
        logError("Error updating: $e");
        logInfo(stack);
      }
    }
    return events;
  }
}
