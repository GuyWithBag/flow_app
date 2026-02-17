import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/pages.barrel.dart';
import 'providers/providers.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.themeProvider,
    required this.presetProvider,
    required this.sessionProvider,
  });

  final ThemeProvider themeProvider;
  final PresetProvider presetProvider;
  final SessionProvider sessionProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => sessionProvider),
        ChangeNotifierProvider(create: (_) => presetProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
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
