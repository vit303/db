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
        // Пока настройки не загружены — базовая тема без scaling
        if (!settings.isLoaded) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Базовая тема с fontFamily (без fontSizeFactor — чтобы избежать ассерта на старте)
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
          // Ключевой момент: builder применяется ПОСЛЕ локализации и базовой темы
          // Здесь textTheme уже имеет конкретные fontSize, поэтому apply(fontSizeFactor) безопасен
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: settings.fontSize / 16.0, // Теперь ассерт не сработает
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