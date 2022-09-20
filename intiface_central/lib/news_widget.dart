import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:markdown/markdown.dart' as md;

class NewsWidget extends StatefulWidget {
  @override
  NewsWidgetState createState() => NewsWidgetState();
}

class NewsWidgetState extends State<NewsWidget> {
  NewsWidgetState();

  @override
  void initState() {
    super.initState();
  }

  Future<String> _getNewsContent() async {
    logInfo("Loading news file from ${IntifacePaths.newsFile}");
    if (await IntifacePaths.newsFile.exists()) {
      return await IntifacePaths.newsFile.readAsString();
    }
    return "No news file available.";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getNewsContent(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return Expanded(
              child: Markdown(
            selectable: true,
            data: snapshot.hasData ? snapshot.data! : "News being fetched.",
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
            ),
          ));
        });
  }
}
