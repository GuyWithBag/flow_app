import 'package:flow_app/models/timer_models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends HookWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF121212)
          : Colors.white,
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          const Text(
            'General',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleDarkMode(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Focus Theme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Background Theme'),
            subtitle: Text(
              themeProvider.getBackgroundThemeFor(TimerType.focus),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundThemeDialog(
              context,
              themeProvider,
              TimerType.focus,
            ),
          ),
          ListTile(
            title: const Text('Background Image URL'),
            subtitle: Text(
              themeProvider.getBackgroundImageUrlFor(TimerType.focus) ?? 'None',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundImageUrlDialog(
              context,
              themeProvider,
              TimerType.focus,
            ),
          ),
          ListTile(
            title: const Text('Accent Color'),
            trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: themeProvider.getAccentColorFor(TimerType.focus),
                shape: BoxShape.circle,
              ),
            ),
            onTap: () =>
                _showColorPicker(context, themeProvider, TimerType.focus),
          ),
          const SizedBox(height: 24),
          const Text(
            'Break Theme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Background Theme'),
            subtitle: Text(
              themeProvider.getBackgroundThemeFor(TimerType.breakTime),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundThemeDialog(
              context,
              themeProvider,
              TimerType.breakTime,
            ),
          ),
          ListTile(
            title: const Text('Background Image URL'),
            subtitle: Text(
              themeProvider.getBackgroundImageUrlFor(TimerType.breakTime) ??
                  'None',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundImageUrlDialog(
              context,
              themeProvider,
              TimerType.breakTime,
            ),
          ),
          ListTile(
            title: const Text('Accent Color'),
            trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: themeProvider.getAccentColorFor(TimerType.breakTime),
                shape: BoxShape.circle,
              ),
            ),
            onTap: () =>
                _showColorPicker(context, themeProvider, TimerType.breakTime),
          ),
        ],
      ),
    );
  }

  void _showBackgroundThemeDialog(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Default'),
              value: 'default',
              groupValue: provider.getBackgroundThemeFor(type),
              onChanged: (v) {
                provider.setModeBackgroundTheme(type, v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Gradient'),
              value: 'gradient',
              groupValue: provider.getBackgroundThemeFor(type),
              onChanged: (v) {
                provider.setModeBackgroundTheme(type, v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundImageUrlDialog(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) {
    final controller = TextEditingController(
      text: provider.getBackgroundImageUrlFor(type),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://.../image.jpg',
            labelText: 'Image URL',
          ),
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.setModeBackgroundImageUrl(type, null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setModeBackgroundImageUrl(type, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) {
    final colors = [
      const Color(0xFF66BB6A),
      const Color(0xFF42A5F5),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB74D),
      const Color(0xFF9C27B0),
      const Color(0xFF26A69A),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                provider.setModeAccentColor(type, color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == provider.getAccentColorFor(type)
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
