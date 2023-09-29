import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/page/log_page.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/widget/markdown_widget.dart';
import 'package:intiface_central/page/device_page.dart';
import 'package:intiface_central/page/settings_page.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';

class NavigationDestination {
  final bool Function(NavigationState state) stateCheck;
  final void Function(NavigationCubit cubit) navigate;
  final Icon icon;
  final Icon selectedIcon;
  final String title;
  final Widget Function() widgetProvider;
  final bool showInMobileRail;

  NavigationDestination(this.stateCheck, this.navigate, this.icon, this.selectedIcon, this.title, this.widgetProvider,
      this.showInMobileRail);
}

class BodyWidget extends StatelessWidget {
  const BodyWidget({super.key});

  Widget _buildMenu(BuildContext context, NavigationState state) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var errorNotifierCubit = BlocProvider.of<ErrorNotifierCubit>(context);
    var assets = BlocProvider.of<AssetCubit>(context);

    var destinations = [
      NavigationDestination(
          (state) => state is NavigationStateNews,
          (NavigationCubit cubit) => cubit.goNews(),
          const Icon(Icons.newspaper_outlined),
          const Icon(Icons.newspaper),
          'News',
          () => BlocBuilder<UpdateBloc, UpdateState>(
              buildWhen: (previous, current) => current is NewsUpdateRetrieved,
              builder: (context, state) => MarkdownWidget(markdownContent: assets.newsAsset, backToSettings: false)),
          true),
      NavigationDestination(
          (state) => state is NavigationStateDeviceControl,
          (NavigationCubit cubit) => cubit.goDeviceControl(),
          const Icon(Icons.vibration_outlined),
          const Icon(Icons.vibration),
          'Devices',
          () => const DevicePage(),
          true),
      NavigationDestination(
          (state) => state is NavigationStateLogs,
          (NavigationCubit cubit) => cubit.goLogs(),
          Icon(Icons.text_snippet_outlined,
              color: errorNotifierCubit.state is ErrorNotifierTriggerState ? Colors.red : IconTheme.of(context).color),
          const Icon(Icons.text_snippet),
          'Log',
          () => const LogPage(),
          true),
      NavigationDestination(
          (state) => state is NavigationStateSettings,
          (NavigationCubit cubit) => cubit.goSettings(),
          Icon(Icons.settings_outlined,
              color: isDesktop() && configCubit.currentAppVersion != configCubit.latestAppVersion
                  ? Colors.green
                  : IconTheme.of(context).color),
          Icon(Icons.settings,
              color: isDesktop() && configCubit.currentAppVersion != configCubit.latestAppVersion
                  ? Colors.green
                  : IconTheme.of(context).color),
          'Settings',
          () => const SettingPage(),
          true),

      // We have Navigation Destinations for which we may not want to show bottom bar nav. For instance, we'll want to
      // hide our About/Help in the Settings widget on mobile.
      NavigationDestination(
          (state) => state is NavigationStateAbout,
          (NavigationCubit cubit) => cubit.goAbout(),
          const Icon(Icons.help_outlined),
          const Icon(Icons.help),
          'Help / About',
          () => MarkdownWidget(markdownContent: assets.aboutAsset, backToSettings: true),
          false),
    ];

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

    if (configCubit.useSideNavigationBar) {
      return Row(children: <Widget>[
        NavigationRail(
            selectedIndex: selectedIndex,
            groupAlignment: -1.0,
            onDestinationSelected: (int index) {
              destinations[index].navigate(navCubit);
            },
            labelType: NavigationRailLabelType.all,
            destinations:
                destinations.map((v) => NavigationRailDestination(icon: v.icon, label: Text(v.title))).toList()),
        Expanded(child: Column(children: [destinations[selectedIndex].widgetProvider()]))
      ]);
    }
    // Weird special case time! If we're showing the bottom bar nav, and we're in one of the widgets that
    // isn't shown there, assume we're actually in the settings widget.
    var visualSelectedIndex = selectedIndex;

    if (!destinations[selectedIndex].showInMobileRail) {
      visualSelectedIndex = destinations.where((element) => element.showInMobileRail).length - 1;
    }

    return Column(children: <Widget>[
      Expanded(child: Column(children: [destinations[selectedIndex].widgetProvider()])),
      BottomNavigationBar(
          currentIndex: visualSelectedIndex,
          onTap: (int index) {
            destinations[index].navigate(navCubit);
          },
          type: BottomNavigationBarType.fixed,
          items: destinations
              .where((element) => element.showInMobileRail)
              .map((dest) => BottomNavigationBarItem(icon: dest.icon, activeIcon: dest.selectedIcon, label: dest.title))
              .toList())
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // This is so gross and should be handled as a stream. :c
    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        buildWhen: (previous, current) => current is UseSideNavigationBar,
        builder: (context, configState) =>
            BlocBuilder<NavigationCubit, NavigationState>(builder: (context, navigationState) {
              return BlocBuilder<ErrorNotifierCubit, ErrorNotifierState>(builder: (context, errorState) {
                return _buildMenu(context, navigationState);
              });
            }));
  }
}
