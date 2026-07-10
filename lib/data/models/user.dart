enum UserRole {
  estudiante,
  limpieza,
  mantenimiento,
  sistemas,
  administrador;

  String get displayName {
    switch (this) {
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.limpieza:
        return 'Personal de Limpieza';
      case UserRole.mantenimiento:
        return 'Personal de Mantenimiento';
      case UserRole.sistemas:
        return 'Personal de Sistemas';
      case UserRole.administrador:
        return 'Administrador';
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.estudiante,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
    };
  }
}
