import 'package:postgres/postgres.dart';
import '../models/user.dart';

class PostgresService {
  static Connection? _connection;

  // Фиксированные данные для подключения к БД
  static const String _host = 'localhost';
  static const int _port = 5432;
  static const String _database = 'postgres';        // ← твоя основная база
  static const String _username = 'postgres';   // ← технический пользователь
  static const String _password = 'postgres';   // ← твой пароль

  /// Аутентификация: проверяем, существует ли пользователь PostgreSQL с таким логином/паролем
  static Future<User?> authenticate(String username, String password) async {
    try {
      // Пробуем подключиться под введёнными данными
      final testEndpoint = Endpoint(
        host: _host,
        port: _port,
        database: _database,
        username: username.trim(),
        password: password,
      );

      final testConn = await Connection.open(
        testEndpoint,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      await testConn.close(); // Если дошли сюда — логин/пароль верные

      // Возвращаем объект User на основе имени пользователя
      return User.fromPgLogin(username.trim());
    } catch (e) {
      print('Ошибка аутентификации: $e');
      return null;
    }
  }

  /// Основное подключение — всегда под техническим пользователем postgres
  /// (чтобы приложение могло читать/писать данные независимо от роли пользователя)
  static Future<Connection> getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    final endpoint = Endpoint(
      host: _host,
      port: _port,
      database: _database,
      username: _username,
      password: _password,
    );

    _connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Подключено к БД под пользователем $_username');
    return _connection!;
  }

  static Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }

  static Future<List<Map<String, dynamic>>> executeQuery(String sql) async {
    try {
      final conn = await getConnection();
      final result = await conn.execute(Sql(sql));
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      return [];
    }
  }

  static Future<bool> executeUpdate(String sql, Map<String, dynamic> parameters) async {
    try {
      final conn = await getConnection();
      await conn.execute(Sql.named(sql), parameters: parameters);
      return true;
    } catch (e) {
      print('Ошибка выполнения обновления: $e');
      return false;
    }
  }
}