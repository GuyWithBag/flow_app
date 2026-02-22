import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class ThemeSettingsPage extends HookWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MenuScaffold(
      title: 'Theme & Appearance',
      body: ListView(
        children: [
          const Text(
            'General',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Show Background on All Screens'),
            subtitle: const Text(
              'Enable background images on Dashboard and Account screens',
            ),
            value: themeProvider.showBackgroundOnMenuScreens,
            onChanged: (value) =>
                themeProvider.setShowBackgroundOnMenuScreens(value),
            activeTrackColor: Theme.of(context).colorScheme.primary,
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
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
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
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
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
        content: RadioGroup<String>(
          groupValue: provider.getBackgroundThemeFor(type),
          onChanged: (v) {
            if (v != null) {
              provider.setModeBackgroundTheme(type, v);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Default'),
                value: 'default',
              ),
              RadioListTile<String>(
                title: const Text('Gradient'),
                value: 'gradient',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackgroundImageUrlDialog(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) {
    final currentValue = provider.getBackgroundImageUrlFor(type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display current selection
            if (currentValue != null) ...[
              const Text(
                'Current:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _getDisplayPath(currentValue),
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // File existence check for local files
              if (!_isRemoteUrl(currentValue))
                FutureBuilder<bool>(
                  future: File(currentValue).exists(),
                  builder: (context, snapshot) {
                    if (snapshot.data == false) {
                      return const Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'File not found',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Pick from Device'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _pickImageFile(context, provider, type);
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Enter URL'),
                onPressed: () {
                  Navigator.pop(context);
                  _showUrlInputDialog(context, provider, type);
                },
              ),
            ),
          ],
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
        ],
      ),
    );
  }

  Future<void> _pickImageFile(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        provider.setModeBackgroundImageUrl(type, path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background image updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUrlInputDialog(
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
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            labelText: 'Image URL',
          ),
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                provider.setModeBackgroundImageUrl(type, url);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _getDisplayPath(String path) {
    if (_isRemoteUrl(path)) {
      return path;
    }
    // Show just filename for local files
    return path.split('/').last;
  }

  void _showColorPicker(
    BuildContext context,
    ThemeProvider provider,
    TimerType type,
  ) {
    // Initialize temporary color with the current saved color
    Color pickerColor = provider.getAccentColorFor(type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (Color color) {
              pickerColor = color;
            },
            // UI Customization to fit the dialog better
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false, // Usually disabled for theme accents
            displayThumbColor: true,
            labelTypes:
                const [], // Empty list disables label (replaces showLabel: true)
            paletteType: PaletteType.hsvWithHue,
            pickerAreaBorderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2.0),
              topRight: Radius.circular(2.0),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Select'),
            onPressed: () {
              provider.setModeAccentColor(type, pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
