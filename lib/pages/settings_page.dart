import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/notification_service.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context);

    final notificationsEnabled = useState<bool?>(null);

    useEffect(() {
      NotificationService.instance.areNotificationsEnabled().then((v) {
        notificationsEnabled.value = v;
      });
      return null;
    }, const []);

    Future<void> requestNotificationPermission() async {
      final granted = await NotificationService.instance.requestPermissions();
      notificationsEnabled.value = granted;
    }

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
              MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
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
            'Notifications & Sound',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(
              notificationsEnabled.value == true
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            title: const Text('Notification Permission'),
            subtitle: Text(
              notificationsEnabled.value == null
                  ? 'Checking…'
                  : notificationsEnabled.value!
                  ? 'Enabled — timer alerts will show'
                  : 'Disabled — tap to enable',
            ),
            trailing: notificationsEnabled.value == true
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : const Icon(Icons.chevron_right),
            onTap: notificationsEnabled.value == true
                ? null
                : requestNotificationPermission,
          ),
          SwitchListTile(
            title: const Text('Play Sound in Silent/Vibrate Mode'),
            subtitle: const Text('Override device silent mode for timer alerts'),
            value: timerProvider.playSoundInSilentMode,
            onChanged: (v) => timerProvider.setPlaySoundInSilentMode(v),
          ),
          const SizedBox(height: 24),
          const Text(
            'Help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Replay Coach Marks'),
            subtitle: const Text('Highlight key timer controls again'),
            onTap: () {
              Navigator.pop(context);
              Hive.box('settings').put('shouldStartShowcase', true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Replay Onboarding'),
            subtitle: const Text('Go through the intro screens again'),
            onTap: () {
              Hive.box('settings').put('hasSeenOnboarding', false);
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const OnboardingPage(),
                  transitionsBuilder: (_, animation, _, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                (_) => false,
              );
            },
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
