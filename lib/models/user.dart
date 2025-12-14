enum UserRole {
  admin('Администратор'),
  moderator('Модератор'),
  jury('Член жюри'),
  participant('Участник'),
  volunteer('Волонтер'),
  guest('Гость');

  final String displayName;
  const UserRole(this.displayName);

  static UserRole fromPgUsername(String username) {
    return switch (username.toLowerCase()) {
      'conference_admin' => UserRole.admin,
      'section_moderator' => UserRole.moderator,
      'jury_member' => UserRole.jury,
      'school_participant' => UserRole.participant,
      'conference_volunteer' => UserRole.volunteer,
      _ => UserRole.guest,
    };
  }
}

class User {
  final String id;
  final String username;
  final String fullName;
  final UserRole role;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email = '',
  });

  factory User.fromPgLogin(String username) {
    final role = UserRole.fromPgUsername(username);
    final fullName = switch (username.toLowerCase()) {
      'conference_admin' => 'Администратор конференции',
      'section_moderator' => 'Модератор секции',
      'jury_member' => 'Член жюри',
      'school_participant' => 'Школьник-участник',
      'conference_volunteer' => 'Волонтёр конференции',
      _ => 'Гость',
    };

    return User(
      id: 'pg_$username',
      username: username,
      fullName: fullName,
      role: role,
      email: '$username@conference.ru',
    );
  }

  factory User.guest() {
    return User(
      id: '0',
      username: 'guest',
      fullName: 'Гостевой пользователь',
      role: UserRole.guest,
      email: 'guest@conference.ru',
    );
  }
}