import 'package:db/models/user.dart';
import 'package:db/screens/main_screen.dart';
import 'package:db/services/postgres_service.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _connectionError = false;

  // Тестирование подключения к базе данных
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionError = false;
    });

    try {
      final connection = await PostgresService.getConnection();
      if (connection.isOpen) {
        print('Подключение успешно!');
        setState(() {
          _connectionError = false;
        });
      }
    } catch (e) {
      print('Ошибка подключения: $e');
      setState(() {
        _connectionError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final username = _usernameController.text.trim();
  final password = _passwordController.text;

  final user = await PostgresService.authenticate(username, password);

  if (user != null) {
    _navigateToMain(user);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Неверный логин или пароль'), backgroundColor: Colors.red),
    );
    // Гостевой режим
    _navigateToMain(User.guest());
  }

  setState(() => _isLoading = false);
}



  void _navigateToMain(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(user: user),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Тестируем подключение при запуске
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF3498DB),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Логотип
                      Image.asset(
                        'assets/logo.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school,
                            size: 80,
                            color: Color(0xFF2C3E50),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Заголовок
                      const Text(
                        'Конференция "Мой первый шаг в IT"',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      
                      const Text(
                        'Система управления научной конференцией',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Статус подключения
                      if (_connectionError)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Не удалось подключиться к базе данных. Используется демо-режим.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Поле логина
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Имя пользователя или email',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите имя пользователя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Поле пароля
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль (любой для демо)',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      
                      // Кнопка входа
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'ВОЙТИ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      // Дополнительная информация
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Для демо-режима используйте:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: const [
                          Chip(
                            label: Text('Любое имя пользователя'),
                            backgroundColor: Colors.blueGrey,
                          ),
                          Chip(
                            label: Text('Любой пароль'),
                            backgroundColor: Colors.blueGrey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _testConnection,
                        child: const Text('Проверить подключение к БД'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    PostgresService.closeConnection();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}