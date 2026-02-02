import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';

class ExpandableCardWidget extends StatelessWidget {
  final String expansionName;
  final Widget title;
  final Widget? subtitle;
  final Widget body;
  final bool defaultExpanded;

  const ExpandableCardWidget({
    super.key,
    required this.expansionName,
    required this.title,
    this.subtitle,
    required this.body,
    this.defaultExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    var guiSettingsCubit = BlocProvider.of<GuiSettingsCubit>(context);
    return BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
      buildWhen: (previous, current) =>
          current is GuiSettingStateUpdate &&
          current.valueName == expansionName,
      builder: (context, state) {
        final isExpanded =
            guiSettingsCubit.getExpansionValue(expansionName) ??
            defaultExpanded;
        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => guiSettingsCubit.setExpansionValue(
                  expansionName,
                  !isExpanded,
                ),
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
                            title,
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              subtitle!,
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
              if (isExpanded) body,
            ],
          ),
        );
      },
    );
  }
}
