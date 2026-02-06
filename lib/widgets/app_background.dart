import 'package:flow_app/models/timer_models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBackground extends StatelessWidget {
  final ThemeProvider themeProvider;
  const AppBackground({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: true);
    final currentType = timerProvider.currentType;

    final url = themeProvider.getBackgroundImageUrlFor(currentType);
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
                _fallbackBackground(themeProvider, currentType),
          ),
          DecoratedBox(decoration: BoxDecoration(color: overlayColor)),
        ],
      );
    }

    return _fallbackBackground(themeProvider, currentType);
  }

  Widget _fallbackBackground(ThemeProvider themeProvider, TimerType type) {
    if (themeProvider.getBackgroundThemeFor(type) == 'gradient') {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [const Color(0xFFFAFAFA), const Color(0xFFE8E8E8)],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFFAFAFA),
      ),
    );
  }
}
