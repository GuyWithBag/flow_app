import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/services.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends HookWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final purchaseProvider = context.watch<PurchaseProvider>();
    final showPlannedMessage = useState(false);
    final AdService adService = context.watch<AdService>();

    return MenuScaffold(
      title: 'Account',
      body: ListView(
        children: [
          if (authProvider.isAuthenticated &&
              authProvider.currentUser != null) ...[
            _buildProfileHeader(authProvider.currentUser!),
          ] else ...[
            // TODO: REPLACE WITH REAL BANNER AD - See AD_IMPLEMENTATION.md
            // Ad placeholder for guest users
            BannerAdWidget(),
            const SizedBox(height: 8),
            _buildGuestHeader(themeProvider),
          ],
          const SizedBox(height: 24),
          _buildGoalsCard(),

          const SizedBox(height: 16),
          _buildThemeSelector(context, themeProvider),
          _buildSettingsTile(context, 'Settings', Icons.settings, () {
            if (!purchaseProvider.isNoAds) adService.iAd?.show();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }),
          _buildSettingsTile(context, 'Presets', Icons.bookmark, () {
            if (!purchaseProvider.isNoAds) adService.iAd?.show();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresetsPage()),
            );
          }),
          _buildSettingsTile(context, 'Privacy Policy', Icons.bookmark, () {
            launchUrl(
              Uri.parse(
                'https://doc-hosting.flycricket.io/flow-comfy-pomodoro-app-privacy-policy/0af4297c-6d8c-4f2f-a9b7-a8222962649d/privacy',
              ),
            );
          }),
          _buildSettingsTile(context, 'Terms Of Service', Icons.bookmark, () {
            launchUrl(
              Uri.parse(
                'https://doc-hosting.flycricket.io/flow-comfy-pomodoro-app-privacy-policy/0af4297c-6d8c-4f2f-a9b7-a8222962649d/termsy',
              ),
            );
          }),
          if (purchaseProvider.isNoAds)
            _buildSettingsTile(
              context,
              'Manage Subscription',
              Icons.receipt_long,
              () => RevenueCatUI.presentCustomerCenter(),
            ),
          const SizedBox(height: 24),
          if (authProvider.isAuthenticated) ...[
            ElevatedButton(
              onPressed: () => authProvider.logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                showPlannedMessage.value = !showPlannedMessage.value;
              },
              child: const Text('Log in / Sign up'),
            ),
            if (showPlannedMessage.value)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cloud sync and account features are planned for the future.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (!purchaseProvider.isNoAds) _buildUpgradeCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestHeader(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: themeProvider.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              child: Icon(
                Icons.person_outline,
                size: 32,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Not signed in',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF66BB6A),
              child: Text(
                user.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    // TODO: Hook this up to real progress and the configurable daily goal.
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Goal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.65, // TODO: Calculate from actual sessions
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '78 / 120 minutes',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD54F), // Amber
            Color(0xFFFF9800), // Orange
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              RevenueCatUI.presentPaywall(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Go Premium',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.star, color: Colors.white, size: 18),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Remove ads Forever with One Time Purchase',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    String getThemeLabel() {
      switch (themeProvider.themeBrightness) {
        case 'light':
          return 'Light';
        case 'dark':
          return 'Dark';
        case 'system':
        default:
          return 'System';
      }
    }

    IconData getThemeIcon() {
      switch (themeProvider.themeBrightness) {
        case 'light':
          return Icons.light_mode;
        case 'dark':
          return Icons.dark_mode;
        case 'system':
        default:
          return Icons.brightness_auto;
      }
    }

    return ListTile(
      leading: Icon(getThemeIcon()),
      title: const Text('Theme'),
      subtitle: Text(getThemeLabel()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeBrightnessDialog(context, themeProvider),
    );
  }

  void _showThemeBrightnessDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: RadioGroup<String>(
          groupValue: themeProvider.themeBrightness,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeBrightness(value);
              if (value == 'system') {
                final brightness = MediaQuery.platformBrightnessOf(context);
                themeProvider.updateSystemBrightness(brightness);
              }
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: 'light',
              ),
              RadioListTile<String>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: 'dark',
              ),
              RadioListTile<String>(
                title: const Text('System'),
                subtitle: const Text('Follow system setting'),
                value: 'system',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
