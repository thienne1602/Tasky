class User {
  User({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.avatar,
    this.role = 'member',
  });

  final int id;
  final String userId;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        userId: json['user_id'] as String? ??
            json['userId'] as String? ??
            (json['id'] as int).toString(),
        name: json['name'] as String? ?? 'Unknown',
        email: json['email'] as String? ?? '',
        avatar: json['avatar'] as String?,
        role: json['role'] as String? ?? 'member',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'user_id': userId,
        'name': name,
        'email': email,
        'avatar': avatar,
        'role': role,
      };

  User copyWith({String? name, String? avatar}) => User(
        id: id,
        userId: userId,
        name: name ?? this.name,
        email: email,
        avatar: avatar ?? this.avatar,
        role: role,
      );
}
