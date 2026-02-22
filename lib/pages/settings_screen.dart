import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MenuScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          const Text(
            'General',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Theme & Appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Daily Goal'),
            subtitle: Text('${themeProvider.dailyGoalMinutes} minutes per day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDailyGoalDialog(context, themeProvider),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get notified when timer ends'),
            value: true, // TODO: Implement
            onChanged: (v) {}, // TODO: Implement
          ),
          SwitchListTile(
            title: const Text('Sound Alerts'),
            subtitle: const Text('Play sound on timer completion'),
            value: true, // TODO: Implement
            onChanged: (v) {}, // TODO: Implement
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, ThemeProvider provider) {
    final controller = TextEditingController(
      text: provider.dailyGoalMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Goal (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes per day',
            hintText: 'e.g. 120',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                provider.setDailyGoalMinutes(value);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
