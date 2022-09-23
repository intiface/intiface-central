import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownWidget extends StatelessWidget {
  final String _markdownContent;
  final bool _backToSettings;

  MarkdownWidget({super.key, required String markdownContent, required bool backToSettings})
      : _markdownContent = markdownContent,
        _backToSettings = backToSettings;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Markdown(
      selectable: true,
      data: _markdownContent,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
    ));
  }
}
