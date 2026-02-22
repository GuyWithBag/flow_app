import 'dart:ui';

import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../providers/providers.barrel.dart';

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(1); // Start on Timer screen
    final pageController = usePageController(initialPage: 1);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final currentAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: AppBackground(themeProvider: themeProvider)),
          PageView.builder(
            controller: pageController,
            onPageChanged: (index) => currentIndex.value = index,
            itemCount: 3,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return const DashboardPage();
                case 1:
                  return const TimerPage();
                case 2:
                  return const AccountPage();
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).cardColor.withAlpha(100),
            currentIndex: currentIndex.value,
            onTap: (index) {
              currentIndex.value = index;
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            selectedItemColor: currentAccent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timer_outlined),
                label: 'Timer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
