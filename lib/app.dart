import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'pages/pages.barrel.dart';
import 'providers/providers.barrel.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.themeProvider,
    required this.presetProvider,
    required this.sessionProvider,
    required this.timerProvider,
  });

  final ThemeProvider themeProvider;
  final PresetProvider presetProvider;
  final SessionProvider sessionProvider;
  final TimerProvider timerProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => timerProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => sessionProvider),
        ChangeNotifierProvider(create: (_) => presetProvider),
      ],
      // This is to update the Theme
      child: Consumer2<ThemeProvider, TimerProvider>(
        builder: (context, themeProvider2, timerProvider2, _) {
          return MaterialApp(
            title: 'Flow',
            debugShowCheckedModeBanner: false,
            theme: themeProvider2.currentTheme,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
