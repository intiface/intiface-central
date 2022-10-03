import 'package:bloc/bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkInfoState {}

class NetworkUp extends NetworkInfoState {
  String? ip;
  NetworkUp(this.ip);
}

class NetworkInfoCubit extends Cubit<NetworkInfoState> {
  final String? _ip;

  NetworkInfoCubit(this._ip) : super(NetworkUp(_ip));

  static Future<NetworkInfoCubit> create() async {
    final info = NetworkInfo();
    try {
      var wifiIP = await info.getWifiIP();
      return NetworkInfoCubit(wifiIP);
    } catch (e) {
      return NetworkInfoCubit(null);
    }
  }

  String? get ip => _ip;
}
