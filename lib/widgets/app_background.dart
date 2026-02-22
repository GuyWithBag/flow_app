import 'dart:io';

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
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.20);

    if (url != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildImageWidget(url, context, scaffoldBg),
          DecoratedBox(decoration: BoxDecoration(color: overlayColor)),
        ],
      );
    }

    return _fallbackBackground(context, scaffoldBg);
  }

  bool _isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildImageWidget(
    String path,
    BuildContext context,
    Color scaffoldBg,
  ) {
    if (_isRemoteUrl(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackBackground(context, scaffoldBg),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackBackground(context, scaffoldBg),
      );
    }
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
