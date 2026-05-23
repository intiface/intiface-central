import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const guiWindowWidth = "gui_window_width";
const guiWindowHeight = "gui_window_height";

const guiWindowPosX = "gui_window_posx";
const guiWindowPosY = "gui_window_posy";

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
    _emitUpdate(expansionName);
  }

  Size getWindowSize() {
    try {
      return Size(
        _prefs.getInt(guiWindowWidth)!.floorToDouble(),
        _prefs.getInt(guiWindowHeight)!.floorToDouble(),
      );
    } catch (e) {
      return const Size(800, 600);
    }
  }

  void setWindowSize(Size windowSize) {
    _prefs.setInt(guiWindowWidth, windowSize.width.floor());
    _prefs.setInt(guiWindowHeight, windowSize.height.floor());
    _emitUpdate(guiWindowWidth);
  }

  Offset getWindowPosition() {
    try {
      return Offset(
        _prefs.getInt(guiWindowPosX)!.floorToDouble(),
        _prefs.getInt(guiWindowPosY)!.floorToDouble(),
      );
    } catch (e) {
      return const Offset(0, 0);
    }
  }

  void setWindowPosition(Offset windowSize) {
    _prefs.setInt(guiWindowPosX, windowSize.dx.floor());
    _prefs.setInt(guiWindowPosY, windowSize.dy.floor());
    _emitUpdate(guiWindowPosX);
  }

  void _emitUpdate(String valueName) {
    if (isClosed) {
      return;
    }
    emit(GuiSettingStateUpdate(valueName: valueName));
  }
}
