import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';

void main() {
  group('NavigationCubit', () {
    test('initial state is NavigationPage.news', () {
      final cubit = NavigationCubit();
      expect(cubit.state, NavigationPage.news);
      cubit.close();
    });

    blocTest<NavigationCubit, NavigationPage>(
      'goAppControl emits appControl',
      build: NavigationCubit.new,
      act: (cubit) => cubit.goAppControl(),
      expect: () => [NavigationPage.appControl],
    );

    blocTest<NavigationCubit, NavigationPage>(
      'goSettings emits settings',
      build: NavigationCubit.new,
      act: (cubit) => cubit.goSettings(),
      expect: () => [NavigationPage.settings],
    );

    blocTest<NavigationCubit, NavigationPage>(
      'goDeviceConfig emits deviceConfig',
      build: NavigationCubit.new,
      act: (cubit) => cubit.goDeviceConfig(),
      expect: () => [NavigationPage.deviceConfig],
    );

    blocTest<NavigationCubit, NavigationPage>(
      'goDeviceControl emits deviceControl',
      build: NavigationCubit.new,
      act: (cubit) => cubit.goDeviceControl(),
      expect: () => [NavigationPage.deviceControl],
    );
  });
}
