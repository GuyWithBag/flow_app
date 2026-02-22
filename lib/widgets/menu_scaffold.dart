import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuScaffold extends StatelessWidget {
  const MenuScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.showBackgroundOnMenuScreens
        ? Colors.transparent
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(title), elevation: 1, actions: actions),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: body,
        ),
      ),
    );
  }
}
