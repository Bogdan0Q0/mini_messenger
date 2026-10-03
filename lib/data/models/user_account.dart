class UserAccount {
  /// Постоянный идентификатор: по нему хранятся аватар, чаты и контакты
  /// пользователя. В отличие от email и username он не меняется.
  final String id;
  final String name;
  final String username;
  final String email;
  final String password;

  const UserAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  /// Новый аккаунт с уникальным id.
  factory UserAccount.create({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    return UserAccount(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      username: username,
      email: email,
      password: password,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      };

  /// Аккаунты, сохранённые старыми версиями, не имеют id — для них он
  /// выводится из email, так что у одного аккаунта всегда один и тот же id.
  factory UserAccount.fromJson(Map<String, dynamic> j) {
    final email = j['email'] as String;
    return UserAccount(
      id: (j['id'] as String?) ?? _legacyId(email),
      name: j['name'] as String,
      username: j['username'] as String,
      email: email,
      password: j['password'] as String,
    );
  }

  UserAccount copyWith({String? name, String? username, String? email}) {
    return UserAccount(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password,
    );
  }

  static String _legacyId(String email) =>
      'legacy_${email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
}
