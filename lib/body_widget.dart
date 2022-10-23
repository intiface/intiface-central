import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/device_widget.dart';
import 'package:intiface_central/log_widget.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/markdown_widget.dart';
import 'package:intiface_central/settings_widget.dart';
import 'package:intiface_central/update/update_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
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
          (state) => state is NavigationStateDevices,
          (NavigationCubit cubit) => cubit.goDevices(),
          const Icon(Icons.vibration_outlined),
          const Icon(Icons.vibration),
          'Devices',
          () => const DeviceWidget(),
          true),
      NavigationDestination(
          (state) => state is NavigationStateLogs,
          (NavigationCubit cubit) => cubit.goLogs(),
          const Icon(Icons.text_snippet_outlined),
          const Icon(Icons.text_snippet),
          'Log',
          () => const LogWidget(),
          true),
      NavigationDestination(
          (state) => state is NavigationStateSettings,
          (NavigationCubit cubit) => cubit.goSettings(),
          Icon(Icons.settings_outlined,
              color: configCubit.currentAppVersion != configCubit.latestAppVersion
                  ? Colors.green
                  : IconTheme.of(context).color),
          Icon(Icons.settings,
              color: configCubit.currentAppVersion != configCubit.latestAppVersion
                  ? Colors.green
                  : IconTheme.of(context).color),
          'Settings',
          () => const SettingWidget(),
          true),

      // We have Navigation Destinations for which we may not want to show bottom bar nav. For instance, we'll want to
      // hide our About/Help in the Settings widget on mobile.
      NavigationDestination(
          (state) => state is NavigationStateHelp,
          (NavigationCubit cubit) => cubit.goHelp(),
          const Icon(Icons.tips_and_updates_outlined),
          const Icon(Icons.tips_and_updates),
          'Help',
          () => MarkdownWidget(markdownContent: assets.helpAsset, backToSettings: true),
          false),
      NavigationDestination(
          (state) => state is NavigationStateAbout,
          (NavigationCubit cubit) => cubit.goAbout(),
          const Icon(Icons.help_outlined),
          const Icon(Icons.help),
          'About',
          () => MarkdownWidget(markdownContent: assets.aboutAsset, backToSettings: true),
          false),
    ];

    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        buildWhen: (previous, current) => current is UseSideNavigationBar,
        builder: (context, state) => BlocBuilder<NavigationCubit, NavigationState>(builder: (context, state) {
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
                return Expanded(
                    child: Row(children: <Widget>[
                  NavigationRail(
                      selectedIndex: selectedIndex,
                      groupAlignment: -1.0,
                      onDestinationSelected: (int index) {
                        destinations[index].navigate(navCubit);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: destinations
                          .map((v) => NavigationRailDestination(icon: v.icon, label: Text(v.title)))
                          .toList()),
                  Expanded(child: Column(children: [destinations[selectedIndex].widgetProvider()]))
                ]));
              }
              // Weird special case time! If we're showing the bottom bar nav, and we're in one of the widgets that
              // isn't shown there, assume we're actually in the settings widget.
              var visualSelectedIndex = selectedIndex;

              if (!destinations[selectedIndex].showInMobileRail) {
                visualSelectedIndex = destinations.where((element) => element.showInMobileRail).length - 1;
              }

              return Expanded(
                  child: Column(children: <Widget>[
                Expanded(child: Column(children: [destinations[selectedIndex].widgetProvider()])),
                BottomNavigationBar(
                    currentIndex: visualSelectedIndex,
                    onTap: (int index) {
                      destinations[index].navigate(navCubit);
                    },
                    type: BottomNavigationBarType.fixed,
                    items: destinations
                        .where((element) => element.showInMobileRail)
                        .map((dest) =>
                            BottomNavigationBarItem(icon: dest.icon, activeIcon: dest.selectedIcon, label: dest.title))
                        .toList())
              ]));
            }));
  }
}
