import 'dart:developer';

import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/services/services.barrel.dart';
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

    final timerProvider = Provider.of<TimerProvider>(context);
    final currentAccent = Theme.of(context).colorScheme.primary;
    final adService = context.read<AdService>();

    // Hide navbar when on the timer tab and controls are hidden
    final showNavBar =
        currentIndex.value != 1 || timerProvider.uiControlsVisible;

    useEffect(() {
      adService.loadInterstitial();
      adService.loadBannerAd(context);

      return null;
    }, []);

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
      bottomNavigationBar: IgnorePointer(
        ignoring: !showNavBar,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          opacity: showNavBar ? 1.0 : 0.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            scale: showNavBar ? 1.0 : 0.85,
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              offset: showNavBar ? Offset.zero : const Offset(0, 0.3),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
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
                    icon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.timer_rounded),
                    label: 'Timer',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Account',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
