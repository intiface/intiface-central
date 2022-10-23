import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownWidget extends StatelessWidget {
  final String _markdownContent;
  final bool _backToSettings;

  const MarkdownWidget({super.key, required String markdownContent, required bool backToSettings})
      : _markdownContent = markdownContent,
        _backToSettings = backToSettings;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    widgets.add(Expanded(
        child: Markdown(
            selectable: true,
            data: _markdownContent,
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
            ))));
    return Expanded(child: Column(children: widgets));
  }
}
