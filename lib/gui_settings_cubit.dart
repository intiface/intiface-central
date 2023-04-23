import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const GUI_WINDOW_WIDTH = "gui_window_width";
const GUI_WINDOW_HEIGHT = "gui_window_height";

const GUI_WINDOW_POSX = "gui_window_posx";
const GUI_WINDOW_POSY = "gui_window_posy";

class GuiSettingsState {}

class GuiSettingsStateInitial extends GuiSettingsState {}

class GuiSettingStateUpdate extends GuiSettingsState {
  final String valueName;

  GuiSettingStateUpdate({required this.valueName});
}

class GuiSettingsCubit extends Cubit<GuiSettingsState> {
  final SharedPreferences _prefs;

  GuiSettingsCubit._create(this._prefs) : super(GuiSettingsStateInitial());

  static Future<GuiSettingsCubit> create() async {
    // Use the same shared prefs as the app config, but we'll need to fire different events here.
    final prefs = await SharedPreferences.getInstance();
    return GuiSettingsCubit._create(prefs);
  }

  bool? getExpansionValue(String expansionName) {
    try {
      return _prefs.getBool(expansionName);
    } catch (e) {
      return null;
    }
  }

  void setExpansionValue(String expansionName, bool isExpanded) {
    _prefs.setBool(expansionName, isExpanded);
    emit(GuiSettingStateUpdate(valueName: expansionName));
  }

  Size getWindowSize() {
    try {
      return Size(_prefs.getInt(GUI_WINDOW_WIDTH)!.floorToDouble(), _prefs.getInt(GUI_WINDOW_HEIGHT)!.floorToDouble());
    } catch (e) {
      return const Size(800, 600);
    }
  }

  void setWindowSize(Size windowSize) {
    _prefs.setInt(GUI_WINDOW_WIDTH, windowSize.width.floor());
    _prefs.setInt(GUI_WINDOW_HEIGHT, windowSize.height.floor());
    emit(GuiSettingStateUpdate(valueName: GUI_WINDOW_WIDTH));
  }

  Offset getWindowPosition() {
    try {
      return Offset(_prefs.getInt(GUI_WINDOW_POSX)!.floorToDouble(), _prefs.getInt(GUI_WINDOW_POSY)!.floorToDouble());
    } catch (e) {
      return const Offset(0, 0);
    }
  }

  void setWindowPosition(Offset windowSize) {
    _prefs.setInt(GUI_WINDOW_POSX, windowSize.dx.floor());
    _prefs.setInt(GUI_WINDOW_POSY, windowSize.dy.floor());
    emit(GuiSettingStateUpdate(valueName: GUI_WINDOW_POSX));
  }
}
