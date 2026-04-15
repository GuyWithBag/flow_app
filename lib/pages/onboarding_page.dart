import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../services/notification_service.dart';
import 'main_page.dart';

class OnboardingPage extends HookWidget {
  const OnboardingPage({super.key});

  // Permissions step is rendered separately (index 2); content steps are 0, 1, 3.
  static const _contentSteps = [
    _OnboardingStep(
      icon: Icons.water_outlined,
      title: 'Welcome to Flow',
      description:
          'A beautiful Pomodoro timer built to help you stay focused and track your progress.',
    ),
    _OnboardingStep(
      icon: Icons.repeat_rounded,
      title: 'Focus. Rest. Repeat.',
      description:
          'Work in timed focus sessions, take short breaks, and build a sustainable rhythm that actually lasts.',
    ),
    _OnboardingStep(
      icon: Icons.explore_outlined,
      title: "Let's Get Started",
      description:
          "We'll walk you through the key features so you can hit the ground running.",
    ),
  ];

  // Total pages = content steps + 1 permissions step inserted at index 2
  static const int _totalPages = 4;
  static const int _permissionsPageIndex = 2;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final color = Theme.of(context).colorScheme.primary;
    final isLast = currentPage.value == _totalPages - 1;
    final isPermissionsPage = currentPage.value == _permissionsPageIndex;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (i) => currentPage.value = i,
                itemCount: _totalPages,
                itemBuilder: (context, i) {
                  if (i == _permissionsPageIndex) {
                    return const _PermissionsStepView();
                  }
                  // Map page index to content step index
                  final contentIndex = i < _permissionsPageIndex ? i : i - 1;
                  return _StepView(step: _contentSteps[contentIndex]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentPage.value == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage.value == i
                              ? color
                              : color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        if (isLast) {
                          _finish(context);
                        } else {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(isLast ? 'Get Started' : 'Next'),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _finish(context),
                      child: Text(
                        isPermissionsPage ? 'Skip for now' : 'Skip',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finish(BuildContext context) {
    final box = Hive.box('settings');
    box.put('hasSeenOnboarding', true);
    box.put('shouldStartShowcase', true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _PermissionsStepView extends HookWidget {
  const _PermissionsStepView();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final granted = useState<bool?>(null);

    useEffect(() {
      NotificationService.instance.areNotificationsEnabled().then((v) {
        granted.value = v;
      });
      return null;
    }, const []);

    Future<void> requestPermission() async {
      final result = await NotificationService.instance.requestPermissions();
      granted.value = result;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_outlined, size: 48, color: color),
          ),
          const SizedBox(height: 36),
          Text(
            'Enable Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Flow needs notification permission to alert you when focus or break sessions complete — even when the app is in the background.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (granted.value == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: color),
                const SizedBox(width: 8),
                Text(
                  'Notifications enabled',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: requestPermission,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Allow Notifications'),
            ),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 48, color: color),
          ),
          const SizedBox(height: 36),
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
