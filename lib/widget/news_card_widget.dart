import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher_string.dart';

class _NewsPost {
  final String title;
  final String? date;
  final String body;

  _NewsPost({required this.title, this.date, required this.body});
}

List<_NewsPost> _parseNewsPosts(String markdown) {
  final posts = <_NewsPost>[];
  // Split on lines that start with "# " (H1 headers).
  final sections = markdown.split(RegExp(r'^(?=# )', multiLine: true));

  for (final section in sections) {
    final trimmed = section.trim();
    if (trimmed.isEmpty) continue;

    final lines = trimmed.split('\n');
    if (lines.isEmpty) continue;

    // First line should be "# Title"
    final firstLine = lines[0].trim();
    if (!firstLine.startsWith('# ')) {
      // Not a headed post — treat whole section as a single body-only post.
      posts.add(_NewsPost(title: '', body: trimmed));
      continue;
    }

    final title = firstLine.substring(2).trim();
    String? date;
    var bodyStart = 1;

    // Check if second non-empty line is an italic date like _2024/01/15 12:00_
    if (lines.length > 1) {
      final dateLine = lines[1].trim();
      if (RegExp(r'^_.*_$').hasMatch(dateLine)) {
        date = dateLine.substring(1, dateLine.length - 1).trim();
        bodyStart = 2;
      }
    }

    final body = lines.sublist(bodyStart).join('\n').trim();
    posts.add(_NewsPost(title: title, date: date, body: body));
  }

  return posts;
}

class NewsCardWidget extends StatefulWidget {
  final String markdownContent;

  const NewsCardWidget({super.key, required this.markdownContent});

  @override
  State<NewsCardWidget> createState() => _NewsCardWidgetState();
}

class _NewsCardWidgetState extends State<NewsCardWidget> {
  static const _pageSize = 5;
  final Set<int> _expandedIndices = {};
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    // Expand the first post by default.
    _expandedIndices.add(0);
  }

  @override
  Widget build(BuildContext context) {
    final posts = _parseNewsPosts(widget.markdownContent);

    if (posts.isEmpty) {
      return const Expanded(child: Center(child: Text('No news available.')));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final visiblePosts = posts.length <= _visibleCount
        ? posts.length
        : _visibleCount;
    final hasMore = visiblePosts < posts.length;
    // Extra item for the "Show more" button when there are hidden posts.
    final itemCount = visiblePosts + (hasMore ? 1 : 0);

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // "Show more" button as the last item.
          if (hasMore && index == visiblePosts) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _visibleCount += _pageSize;
                    });
                  },
                  child: const Text('Show more posts'),
                ),
              ),
            );
          }

          final post = posts[index];
          final isExpanded = _expandedIndices.contains(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tappable header with tinted background.
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                  child: Container(
                    color: colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (post.title.isNotEmpty)
                                Text(
                                  post.title,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              if (post.date != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  post.date!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Collapsible body.
                if (isExpanded && post.body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: MarkdownBody(
                      selectable: true,
                      data: post.body,
                      onTapLink: (text, url, title) async {
                        if (url != null && await canLaunchUrlString(url)) {
                          launchUrlString(url);
                        }
                      },
                      extensionSet: md.ExtensionSet(
                        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                        [
                          md.EmojiSyntax(),
                          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
