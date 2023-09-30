import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/widget/markdown_widget.dart';
import 'package:sentry/sentry_io.dart';

class AboutHelpPage extends StatelessWidget {
  const AboutHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    var assets = BlocProvider.of<AssetCubit>(context);
    return Expanded(
        child: Column(children: [
      MarkdownWidget(markdownContent: assets.aboutAsset, backToSettings: true),
      Row(children: [
        const Text(
          "Need Help?",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        TextButton(
            onPressed: () {
              final logAttachment = IoSentryAttachment.fromFile(IntifacePaths.logFile);
              final userConfigAttachment = IoSentryAttachment.fromFile(IntifacePaths.userDeviceConfigFile);

              Sentry.captureMessage("User submitted logs", withScope: (scope) {
                scope.addAttachment(logAttachment);
                scope.addAttachment(userConfigAttachment);
              });
            },
            child: const Text("Send logs to devs for support."))
      ]),
    ]));
  }
}
