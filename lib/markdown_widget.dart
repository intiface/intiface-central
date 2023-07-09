import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher_string.dart';

class MarkdownWidget extends StatelessWidget {
  final String _markdownContent;

  const MarkdownWidget({super.key, required String markdownContent, required bool backToSettings})
      : _markdownContent = markdownContent;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    widgets.add(Expanded(
        child: Markdown(
            selectable: true,
            data: _markdownContent,
            onTapLink: (text, url, title) async {
              if (url != null && await canLaunchUrlString(url)) {
                launchUrlString(url);
              }
            },
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
            ))));
    return Expanded(child: Column(children: widgets));
  }
}
