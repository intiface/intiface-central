import 'package:flutter/material.dart';

class DetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final String backTooltip;

  const DetailHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backTooltip = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: backTooltip,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
