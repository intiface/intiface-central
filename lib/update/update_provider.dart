import 'package:intiface_central/update/update_bloc.dart';

abstract class UpdateProvider {
  Future<UpdateState?> update();
}
