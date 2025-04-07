class User {
  final String? id;
  final String username;
  String? accessToken;

  User({
    this.id,
    required this.username,
    this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      username: json['username'],
      accessToken: null,
    );
  }

  @override
  String toString() => 'User: $id / $username / $accessToken';
}