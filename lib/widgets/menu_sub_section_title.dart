import 'package:flutter/material.dart';

class MenuSubsectionTitle extends StatelessWidget {
  final String title;

  const MenuSubsectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBold = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(title, style: titleBold),
    );
  }
}
