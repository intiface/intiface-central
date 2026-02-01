import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/util/debouncer.dart';
import 'package:loggy/loggy.dart';

class FeatureOutputConfigWidget extends StatelessWidget {
  final ExposedUserDeviceIdentifier _deviceIdentifier;
  final ExposedServerDeviceDefinition _deviceDefinition;

  const FeatureOutputConfigWidget({
    super.key,
    required deviceIdentifier,
    required deviceDefinition,
  }) : _deviceDefinition = deviceDefinition,
       _deviceIdentifier = deviceIdentifier;

  void buildOutputValueTile(
    bool engineIsRunning,
    List<Widget> outputList,
    String type,
    ExposedServerDeviceFeatureOutputProperties props,
    Function(ExposedServerDeviceFeatureOutputProperties) updateFunc,
  ) {
    Debouncer d = Debouncer(delay: const Duration(milliseconds: 30));
    if (props.value == null) {
      logWarning("Null prop value, cannot render.");
      return;
    }
    outputList.addAll([
      ListTile(
        subtitle: Text(
          "$type - Step Range - Min: ${props.value!.base.$1} Max: ${props.value!.base.$2} Step Limit - Min: ${props.value!.user.$1} Max: ${props.value!.user.$2}",
        ),
      ),
      BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
        builder: (context, state) => MultiSlider(
          max: props.value!.base.$2.toDouble(),
          values: [
            props.value!.user.$1.floorToDouble(),
            props.value!.user.$2.floorToDouble(),
          ],
          divisions: props.value!.base.$2,
          onChanged: engineIsRunning
              ? null
              : ((value) async {
                  if (value[0].toInt() == value[1].toInt()) {
                    return;
                  }
                  var v = props.value!;
                  v.user = (value[0].floor(), value[1].ceil());
                  props.value = v;
                  d.run(() async {
                    await updateFunc(props);
                  });
                }),
        ),
      ),
    ]);
  }

  void buildOutputPositionTile(
    bool engineIsRunning,
    List<Widget> outputList,
    String type,
    ExposedServerDeviceFeatureOutputProperties props,
    Function(ExposedServerDeviceFeatureOutputProperties) updateFunc,
  ) {
    Debouncer d = Debouncer(delay: const Duration(milliseconds: 30));
    if (props.position == null) {
      logWarning("Null prop position, cannot render.");
      return;
    }
    outputList.addAll([
      ListTile(
        subtitle: Text(
          "$type - Step Range - Min: ${props.position!.base.$1} Max: ${props.position!.base.$2} Step Limit - Min: ${props.position!.user.$1} Max: ${props.position!.user.$2}",
        ),
      ),
      BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
        builder: (context, state) => MultiSlider(
          max: props.position!.base.$2.toDouble(),
          values: [
            props.position!.user.$1.floorToDouble(),
            props.position!.user.$2.floorToDouble(),
          ],
          divisions: props.position!.base.$2,
          onChanged: engineIsRunning
              ? null
              : ((value) async {
                  if (value[0].toInt() == value[1].toInt()) {
                    return;
                  }
                  var v = props.position!;
                  v.user = (value[0].floor(), value[1].ceil());
                  props.position = v;
                  d.run(() async {
                    await updateFunc(props);
                  });
                }),
        ),
      ),
    ]);
  }

  void buildOutputPositionWithDurationTile(
    bool engineIsRunning,
    List<Widget> outputList,
    String type,
    ExposedServerDeviceFeatureOutputProperties props,
    Function(ExposedServerDeviceFeatureOutputProperties) updateFunc,
  ) {
    Debouncer d = Debouncer(delay: const Duration(milliseconds: 30));
    outputList.addAll([
      ListTile(
        subtitle: Text(
          "$type - Step Range - Min: ${props.value!.base.$1} Max: ${props.value!.base.$2} Step Limit - Min: ${props.value!.user.$1} Max: ${props.value!.user.$2}",
        ),
      ),
      BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
        builder: (context, state) => MultiSlider(
          max: props.value!.base.$2.toDouble(),
          values: [
            props.value!.user.$1.floorToDouble(),
            props.value!.user.$2.floorToDouble(),
          ],
          divisions: props.value!.base.$2,
          onChanged: engineIsRunning
              ? null
              : ((value) async {
                  if (value[0].toInt() == value[1].toInt()) {
                    return;
                  }
                  var v = props.position!;
                  v.user = (value[0].floor(), value[1].ceil());
                  props.position = v;
                  d.run(() async {
                    await updateFunc(props);
                  });
                }),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (EngineControlState previous, EngineControlState current) =>
          current is EngineStartingState ||
          current is EngineStartedState ||
          current is EngineStoppedState ||
          current is ClientConnectedState ||
          current is ClientDisconnectedState,
      builder: (context, EngineControlState state) {
        var engineIsRunning = BlocProvider.of<EngineControlBloc>(
          context,
        ).isRunning;
        List<Widget> outputList = [];
        for (var feature in _deviceDefinition.features) {
          outputList.addAll([
            ListTile(
              title: Text("Feature: ${feature.description} - ${feature.id}"),
            ),
          ]);
          var userConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(
            context,
          );
          void rangeUpdate(newOutputProps) async {
            _deviceDefinition.updateFeatureOutputProperties(
              props: newOutputProps,
            );
            await userConfigCubit.updateDefinition(
              _deviceIdentifier,
              _deviceDefinition,
            );
          }

          if (feature.output?.vibrate != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Vibrate",
              feature.output!.vibrate!,
              rangeUpdate,
            );
          }
          if (feature.output?.spray != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Rotate",
              feature.output!.rotate!,
              rangeUpdate,
            );
          }
          if (feature.output?.oscillate != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Oscillate",
              feature.output!.oscillate!,
              rangeUpdate,
            );
          }
          if (feature.output?.constrict != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Constrict",
              feature.output!.constrict!,
              rangeUpdate,
            );
          }
          if (feature.output?.temperature != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Temperature",
              feature.output!.temperature!,
              rangeUpdate,
            );
          }
          if (feature.output?.led != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "LED",
              feature.output!.led!,
              rangeUpdate,
            );
          }
          if (feature.output?.spray != null) {
            buildOutputValueTile(
              engineIsRunning,
              outputList,
              "Spray",
              feature.output!.spray!,
              rangeUpdate,
            );
          }
          if (feature.output?.position != null) {
            buildOutputPositionTile(
              engineIsRunning,
              outputList,
              "Position",
              feature.output!.position!,
              rangeUpdate,
            );
          }
          if (feature.output?.positionWithDuration != null) {
            buildOutputPositionWithDurationTile(
              engineIsRunning,
              outputList,
              "PositionWithDuration",
              feature.output!.positionWithDuration!,
              rangeUpdate,
            );
          }
          if (feature.input != null) {}
        }
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: outputList,
        );
      },
    );
  }
}
