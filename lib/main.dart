import 'package:flutter/material.dart';
import 'package:intiface_central/gui_settings_cubit.dart';
import 'package:intiface_central/intiface_central_app.dart';

void main() async {
  var guiSettingsCubit = await GuiSettingsCubit.create();
  runApp(IntifaceCentralApp(guiSettingsCubit: guiSettingsCubit));
}
