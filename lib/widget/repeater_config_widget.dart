//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
//import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';
//import 'package:multicast_dns/multicast_dns.dart';

class RepeaterConfigWidget extends StatelessWidget {
  const RepeaterConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var portController = TextEditingController();
    portController.text = configCubit.repeaterLocalPort.toString();

    var repeaterAddressController = TextEditingController(text: configCubit.repeaterRemoteAddress);
    var repeaterPortController = TextEditingController(text: configCubit.repeaterRemoteAddress);
    return Expanded(
        child: BlocBuilder<EngineControlBloc, EngineControlState>(
            buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
            builder: (context, engineState) {
              return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                  buildWhen: (previousState, currentState) =>
                      currentState is RepeaterLocalPortState || currentState is RepeaterRemoteAddressState,
                  builder: (context, state) {
                    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
                    var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
                    List<AbstractSettingsSection> tiles = [
                      SettingsSection(title: const Text("Repeater Settings"), tiles: [
                        SettingsTile.navigation(
                            enabled: !engineIsRunning,
                            title: const Text("Repeater Port"),
                            value: Text(cubit.repeaterLocalPort.toString()),
                            onPressed: (context) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: const Text('Local Port'),
                                        content: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: repeaterPortController,
                                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          onSubmitted: (value) {
                                            var newPort = int.tryParse(value);
                                            if (newPort != null && newPort > 1024 && newPort < 65536) {
                                              cubit.repeaterLocalPort = newPort;
                                            }
                                            Navigator.pop(context);
                                          },
                                          decoration: const InputDecoration(hintText: "Local Port"),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, 'Cancel'),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              var newPort = int.tryParse(repeaterPortController.text);
                                              if (newPort != null && newPort > 1024 && newPort < 65536) {
                                                cubit.repeaterLocalPort = newPort;
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ));
                            }),
                        SettingsTile.navigation(
                            enabled: !engineIsRunning,
                            title: const Text("Remote Server Address"),
                            value: Text(cubit.repeaterRemoteAddress),
                            onPressed: (context) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: const Text('Remote Server Address'),
                                        content: TextField(
                                          //keyboardType: TextInputType.number,
                                          controller: repeaterAddressController,
                                          //inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          onSubmitted: (value) {
                                            configCubit.repeaterRemoteAddress = value;
                                            Navigator.pop(context);
                                          },
                                          decoration: const InputDecoration(hintText: "Remote Server Address"),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, 'Cancel'),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              configCubit.repeaterRemoteAddress = repeaterAddressController.text;
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ));
                            }),
/*                            
                        CustomSettingsTile(
                            child: TextButton(
                                onPressed: () async {
                                  const name = '_intiface_engine';
                                  //const name = '_intiface_engine._tcp';
                                  //const name = '_nvstream_dbd';
                                  logInfo("Starting mDNS query");
                                  final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
                                      (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int? ttl}) {
                                    return RawDatagramSocket.bind(host, port,
                                        reuseAddress: true, reusePort: false, ttl: ttl!);
                                  });
                                  // Start the client with default options.
                                  await client.start(
                                    interfacesFactory: (type) async {
                                      final interfaces = await NetworkInterface.list(
                                        includeLinkLocal: false,
                                        type: type,
                                        includeLoopback: false,
                                      );
                                      return interfaces;
                                    },
                                  );

                                  await for (final PtrResourceRecord ptr
                                      in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
                                    logInfo('PTR: ${ptr.toString()}');

                                    await for (final SrvResourceRecord srv in client
                                        .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
                                      logInfo('SRV target: ${srv.target} port: ${srv.port}');

                                      await for (final IPAddressResourceRecord ip
                                          in client.lookup<IPAddressResourceRecord>(
                                              ResourceRecordQuery.addressIPv4(srv.target))) {
                                        logInfo('IP: ${ip.address.toString()}');
                                      }
                                    }
                                  }
                                  logInfo("Finishing mDNS query");
                                  client.stop();
                                },
                                child: const Text("Scan for Local Servers")))
                                */
                      ])
                    ];
                    return SettingsList(sections: tiles);
                    // Expanded(child: Column(children: [Expanded(child: SettingsList(sections: tiles))]));
                  });
            }));
  }
}
