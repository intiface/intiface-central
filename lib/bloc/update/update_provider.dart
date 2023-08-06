import 'package:intiface_central/bloc/update/update_bloc.dart';

abstract class UpdateProvider {
  Future<UpdateState?> update();
}
