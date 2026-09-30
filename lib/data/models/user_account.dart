class UserAccount {
  final String name;
  final String username;
  final String email;
  final String password;

  const UserAccount({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        name: j['name'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
        password: j['password'] as String,
      );
}
