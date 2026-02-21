import 'dart:ui';

import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../providers/providers.barrel.dart';

class MainScreen extends HookWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(1); // Start on Timer screen
    final themeProvider = Provider.of<ThemeProvider>(context);

    final currentAccent = Theme.of(context).colorScheme.primary;

    final screens = <Widget>[
      const DashboardScreen(),
      const TimerScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: AppBackground(themeProvider: themeProvider)),
          IndexedStack(index: currentIndex.value, children: screens),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).cardColor.withAlpha(100),
            currentIndex: currentIndex.value,
            onTap: (index) => currentIndex.value = index,
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
