import 'package:flow_app/services/services.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';

import 'pages/pages.barrel.dart';
import 'providers/providers.barrel.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.themeProvider,
    required this.presetProvider,
    required this.sessionProvider,
    required this.timerProvider,
    required this.purchaseProvider,
  });

  final ThemeProvider themeProvider;
  final PresetProvider presetProvider;
  final SessionProvider sessionProvider;
  final TimerProvider timerProvider;
  final PurchaseProvider purchaseProvider;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Only update if theme is set to 'system'
    if (widget.themeProvider.themeBrightness == 'system') {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      widget.themeProvider.updateSystemBrightness(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => widget.timerProvider),
        ChangeNotifierProvider(create: (_) => widget.themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdService()),
        ChangeNotifierProvider(create: (_) => widget.sessionProvider),
        ChangeNotifierProvider(create: (_) => widget.presetProvider),
        ChangeNotifierProvider(create: (_) => widget.purchaseProvider),
      ],
      // Only watch ThemeProvider - not TimerProvider
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final hasSeenOnboarding =
              Hive.box('settings').get('hasSeenOnboarding', defaultValue: false)
                  as bool;
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) => MaterialApp(
              title: 'Flow',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.currentTheme,
              home: hasSeenOnboarding
                  ? const MainPage()
                  : const OnboardingPage(),
            ),
          );
        },
      ),
    );
  }
}
