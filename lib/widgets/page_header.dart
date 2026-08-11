import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The big title at the top of a top-level page, with an optional action on the
/// right (settings on Home and Library, "new playlist" on Hotlist).
///
/// [padding] is left to the caller because these pages inset their content
/// differently: some sit inside an already-padded list.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: AppTextStyles.pageTitle),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}
