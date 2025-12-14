import 'package:postgres/postgres.dart';
import '../models/user.dart';

class PostgresService {
  static Connection? _connection;

  // Публичные константы для доступа из других файлов (например, ChangePasswordScreen)
  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'postgres';        // твоя основная база
  static const String techUsername = 'postgres';    // технический пользователь
  static const String techPassword = 'postgres';    // пароль технического пользователя

  /// Аутентификация: проверяем, существует ли пользователь PostgreSQL с таким логином/паролем
  static Future<User?> authenticate(String username, String password) async {
    try {
      final testEndpoint = Endpoint(
        host: host,
        port: port,
        database: database,
        username: username.trim(),
        password: password,
      );

      final testConn = await Connection.open(
        testEndpoint,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      await testConn.close();

      return User.fromPgLogin(username.trim());
    } catch (e) {
      print('Ошибка аутентификации: $e');
      return null;
    }
  }

  /// Основное подключение — всегда под техническим пользователем
  static Future<Connection> getConnection() async {
    // Убрали проверку на isClosed — её нет в текущей версии пакета
    if (_connection != null) {
      return _connection!;
    }

    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: techUsername,
      password: techPassword,
    );

    _connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Подключено к БД под пользователем $techUsername');
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