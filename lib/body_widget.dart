import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/log_widget.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/news_widget.dart';
import 'package:intiface_central/settings_widget.dart';

class NavigationDestination {
  final bool Function(NavigationState state) stateCheck;
  final void Function(NavigationCubit cubit) navigate;
  final NavigationRailDestination destination;
  final Widget Function() widgetProvider;

  NavigationDestination(this.stateCheck, this.navigate, this.destination, this.widgetProvider);
}

class BodyWidget extends StatelessWidget {
  const BodyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;
    var destinations = [
      NavigationDestination(
          (state) => state is NavigationStateNews,
          (NavigationCubit cubit) => cubit.goNews(),
          const NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('News'),
          ),
          () => const NewsWidget()),
      NavigationDestination(
          (state) => state is NavigationStateDevices,
          (NavigationCubit cubit) => cubit.goDevices(),
          const NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Devices'),
          ),
          () => const NewsWidget()),
      NavigationDestination(
          (state) => state is NavigationStateSettings,
          (NavigationCubit cubit) => cubit.goSettings(),
          const NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
          () => const SettingWidget()),
      NavigationDestination(
          (state) => state is NavigationStateLogs,
          (NavigationCubit cubit) => cubit.goLogs(),
          const NavigationRailDestination(
            icon: Icon(Icons.text_snippet_outlined),
            selectedIcon: Icon(Icons.text_snippet),
            label: Text('Log'),
          ),
          () => const LogWidget()),
      NavigationDestination(
          (state) => state is NavigationStateAbout,
          (NavigationCubit cubit) => cubit.goAbout(),
          const NavigationRailDestination(
            icon: Icon(Icons.help_outlined),
            selectedIcon: Icon(Icons.help),
            label: Text('About'),
          ),
          () => const NewsWidget()),
    ];

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        var navCubit = BlocProvider.of<NavigationCubit>(context);
        var selectedIndex = 0;
        for (var element in destinations) {
          if (element.stateCheck(state)) {
            break;
          }
          selectedIndex += 1;
        }
        if (selectedIndex >= destinations.length) {
          selectedIndex = 0;
        }

        return Expanded(
            child: Row(children: <Widget>[
          NavigationRail(
              selectedIndex: selectedIndex,
              groupAlignment: -1.0,
              onDestinationSelected: (int index) {
                destinations[index].navigate(navCubit);
              },
              labelType: NavigationRailLabelType.all,
              destinations: destinations.map((v) => v.destination).toList()),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [destinations[selectedIndex].widgetProvider()]))
        ]));
      },
    );
  }
}
