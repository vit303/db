import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/crud_screen.dart';
import '../screens/documents_screen.dart';

class MenuDrawer extends StatelessWidget {
  final User user;

  const MenuDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == UserRole.admin;
    final bool canViewReferences = isAdmin || user.role != UserRole.guest;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Заголовок drawer
          UserAccountsDrawerHeader(
            accountName: Text(
              user.fullName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Color(0xFF2C3E50)),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
            ),
          ),

          // Роль пользователя
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Chip(
              avatar: const Icon(Icons.person, color: Colors.white, size: 18),
              label: Text(
                user.role.displayName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),

          // === Справочники ===
          if (canViewReferences)
            ExpansionTile(
              leading: const Icon(Icons.library_books, color: Color(0xFF2C3E50)),
              title: const Text('Справочники', style: TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: false,
              children: [
                _buildReferenceItem(context, 'Города', 'City', Icons.location_city),
                _buildReferenceItem(context, 'Учебные заведения', 'Educational_institution', Icons.school),
                _buildReferenceItem(context, 'Места работы', 'Place_of_work', Icons.work),
                _buildReferenceItem(context, 'Должности', 'Post', Icons.badge),
                _buildReferenceItem(context, 'Учёные звания', 'Academic_titles', Icons.star),
                _buildReferenceItem(context, 'Учёные степени', 'Academic_degree', Icons.auto_stories),
                _buildReferenceItem(context, 'Факультеты', 'Faculty', Icons.account_balance),
                _buildReferenceItem(context, 'Специальности', 'Specialization', Icons.engineering),
                // Добавляйте новые справочники здесь
              ],
            ),

          const Divider(height: 20, thickness: 1),

          // === Документы ===
          _buildMenuItem(
            context,
            title: 'Документы',
            target: 'documents',
            icon: Icons.description,
          ),

          // === Справка ===
          ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Справка'),
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Руководство пользователя'),
                onTap: () => _showUserManual(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('О программе'),
                onTap: () => _showAbout(context),
              ),
            ],
          ),

          // === Разное ===
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('Разное'),
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Настройка'),
                onTap: () => _showSettings(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Сменить пароль'),
                onTap: () => _showChangePassword(context),
              ),
            ],
          ),

          const Divider(),

          // === Выход ===
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выход', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Пункт справочника с человекочитаемым названием и иконкой
  ListTile _buildReferenceItem(
    BuildContext context,
    String title,
    String tableName,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2C3E50)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CrudScreen(
              tableName: tableName,
              displayName: title,
            ),
          ),
        );
      },
    );
  }

  // Общий пункт меню
  ListTile _buildMenuItem(
    BuildContext context, {
    required String title,
    required String target,
    IconData? icon,
  }) {
    return ListTile(
      leading: Icon(icon ?? Icons.table_chart, color: const Color(0xFF2C3E50)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (target == 'documents') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentsScreen()),
          );
        }
      },
    );
  }

  // Диалоги справки
  void _showUserManual(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Руководство пользователя'),
        content: const SingleChildScrollView(
          child: Text(
            'Система предназначена для управления данными научно-практической конференции "Мой первый шаг в IT".\n\n'
            '• Справочники — просмотр и редактирование нормативно-справочной информации.\n'
            '• Документы — выполнение произвольных запросов к базе данных.\n'
            '• Роли определяют доступ к функциям системы.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Система управления конференцией',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 60),
      children: const [
        Text('Разработано в рамках лабораторных работ по дисциплине "Базы данных"'),
        Text('Студент: Заозернов В.А.'),
        Text('Группа: АВТ-314'),
        Text('НГТУ, 2025'),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки пока недоступны')),
    );
  }

  void _showChangePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Смена пароля — в разработке')),
    );
  }
}