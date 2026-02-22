import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final ThemeProvider themeProvider;
  const AppBackground({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final url = themeProvider.backgroundImageUrl;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final overlayColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.20);

    if (url != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackBackground(context, scaffoldBg),
          ),
          DecoratedBox(decoration: BoxDecoration(color: overlayColor)),
        ],
      );
    }

    return _fallbackBackground(context, scaffoldBg);
  }

  Widget _fallbackBackground(BuildContext context, Color scaffoldBg) {
    if (themeProvider.backgroundTheme == 'gradient') {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [scaffoldBg, const Color(0xFF2D2D2D)]
                : [scaffoldBg, const Color(0xFFE8E8E8)],
          ),
        ),
      );
    }
    return DecoratedBox(decoration: BoxDecoration(color: scaffoldBg));
  }
}
