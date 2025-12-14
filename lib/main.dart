import 'package:db/localization/app_localizations.dart';
import 'package:db/settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:db/screens/auth_screen.dart';
import 'package:db/themes/app_themes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Если не загружено - базовый app с индикатором
        if (!settings.isLoaded) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Применяем fontFamily в основном theme (не зависит от fontSize)
        final baseLightTheme = lightTheme.copyWith(
          textTheme: lightTheme.textTheme.apply(
            fontFamily: settings.fontFamily,
          ),
        );

        final baseDarkTheme = darkTheme.copyWith(
          textTheme: darkTheme.textTheme.apply(
            fontFamily: settings.fontFamily,
          ),
        );

        return MaterialApp(
          title: 'Система управления конференцией',
          debugShowCheckedModeBanner: false,
          theme: baseLightTheme,
          darkTheme: baseDarkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          // Builder для применения fontSizeFactor ПОСЛЕ локализации и установки theme
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: settings.fontSize / 16.0,
                ),
              ),
              child: child!,
            );
          },
          home: const AuthScreen(),
        );
      },
    );
  }
}