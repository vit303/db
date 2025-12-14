import 'package:db/settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _fonts = ['Roboto', 'OpenSans', 'Montserrat'];
  final List<int> _fontSizes = [12, 14, 16, 18, 20, 22, 24];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шрифт (семейство)
          Card(
            child: ListTile(
              title: const Text('Шрифт'),
              subtitle: Text(settings.fontFamily),
              trailing: DropdownButton<String>(
                value: settings.fontFamily,
                items: _fonts.map((font) {
                  return DropdownMenuItem<String>(
                    value: font,
                    child: Text(font),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    settings.setFontFamily(value);
                  }
                },
              ),
            ),
          ),

          // Размер шрифта
          Card(
            child: ListTile(
              title: const Text('Размер шрифта'),
              subtitle: Text('${settings.fontSize.toInt()} pt'),
              trailing: DropdownButton<int>(
                value: settings.fontSize.toInt(),
                items: _fontSizes.map((size) {
                  return DropdownMenuItem<int>(
                    value: size,
                    child: Text('$size pt'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    settings.setFontSize(value.toDouble());
                  }
                },
              ),
            ),
          ),

          // Язык приложения
          Card(
            child: ListTile(
              title: const Text('Язык приложения'),
              subtitle: Text(settings.locale.languageCode == 'ru' ? 'Русский' : 'English'),
              trailing: DropdownButton<Locale>(
                value: settings.locale,
                items: const [
                  DropdownMenuItem(value: Locale('ru', 'RU'), child: Text('Русский')),
                  DropdownMenuItem(value: Locale('en', 'US'), child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setLocale(value);
                  }
                },
              ),
            ),
          ),

          // Тёмная тема
          Card(
            child: SwitchListTile(
              title: const Text('Тёмная тема'),
              value: settings.isDarkMode,
              onChanged: (value) {
                settings.setDarkMode(value);
              },
            ),
          ),

          // Смена пароля (заглушка)
          Card(
            child: ListTile(
              title: const Text('Сменить пароль'),
              trailing: const Icon(Icons.lock),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Смена пароля — в разработке')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}