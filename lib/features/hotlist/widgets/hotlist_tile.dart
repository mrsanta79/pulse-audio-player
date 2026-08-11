import 'package:flutter/material.dart';

/// A row on the Hotlist page: liked songs, or one playlist.
class HotlistTile extends StatelessWidget {
  const HotlistTile({
    super.key,
    required this.icon,
    required this.background,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.bold = false,
  });

  final IconData icon;
  final Color background;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool bold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
