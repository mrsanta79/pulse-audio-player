import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/routes.dart';
import '../core/theme/app_theme.dart';

/// One artist as a list row, on the Artists page and in artist search results.
class ArtistListTile extends StatelessWidget {
  const ArtistListTile({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.of(context).surfaceHighlight,
        child: const Icon(Icons.person_rounded),
      ),
      title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => context.push(artistRoute(artist)),
    );
  }
}
