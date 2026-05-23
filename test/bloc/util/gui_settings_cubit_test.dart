import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuiSettingsCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ignores updates after close', () async {
      final cubit = await GuiSettingsCubit.create();
      await cubit.close();

      expect(
        () => cubit.setWindowPosition(const Offset(10, 20)),
        returnsNormally,
      );
      expect(() => cubit.setWindowSize(const Size(640, 480)), returnsNormally);
      expect(
        () => cubit.setExpansionValue('test-panel', true),
        returnsNormally,
      );
    });
  });
}
