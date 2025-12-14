import 'package:db/models/user.dart';
import 'package:db/screens/auth_screen.dart';
import 'package:db/services/postgres_service.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User currentUser;

  const ChangePasswordScreen({super.key, required this.currentUser});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Проверка старого пароля — пробуем подключиться под текущим пользователем
  Future<bool> _verifyOldPassword(String oldPassword) async {
    try {
      final testEndpoint = Endpoint(
        host: PostgresService.host,
        port: PostgresService.port,
        database: PostgresService.database,
        username: widget.currentUser.username,
        password: oldPassword,
      );

      final testConn = await Connection.open(
        testEndpoint,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      await testConn.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Смена пароля в PostgreSQL через технического пользователя
  Future<bool> _changePasswordInDb(String newPassword) async {
  try {
    final conn = await PostgresService.getConnection();

    final roleName = widget.currentUser.username;

    // Экранируем апострофы в пароле (заменяем ' на '')
    final escapedPassword = newPassword.replaceAll("'", "''");

    // Простейший запрос: пароль в одинарных кавычках
    final sql = "ALTER ROLE \"$roleName\" WITH PASSWORD '$escapedPassword'";

    // Выполняем без параметров — просто строка
    await conn.execute(sql);

    return true;
  } catch (e) {
    print('Ошибка смены пароля: $e');
    return false;
  }
}

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    // 1. Проверяем старый пароль
    final isOldCorrect = await _verifyOldPassword(oldPass);
    if (!isOldCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Старый пароль введён неверно'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 2. Меняем пароль в БД
    final success = await _changePasswordInDb(newPass);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль успешно изменён! Войдите заново.'),
          backgroundColor: Colors.green,
        ),
      );

      // Закрываем соединение и выходим на экран входа
      await PostgresService.closeConnection();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при смене пароля'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Смена пароля')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Пользователь: ${widget.currentUser.username}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Старый пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Введите старый пароль' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Новый пароль',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите новый пароль';
                  if (v.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Подтвердите новый пароль',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => v != _newPasswordController.text ? 'Пароли не совпадают' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Изменить пароль', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}