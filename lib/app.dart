import 'package:flutter/material.dart';
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
      child: Consumer2<ThemeProvider, TimerProvider>(
        builder: (context, themeProvider, timerProvider, _) {
          themeProvider.updateTimerType(timerProvider.currentType);
          return MaterialApp(
            title: 'Flow',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
