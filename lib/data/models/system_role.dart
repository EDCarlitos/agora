class SystemRole {
  final int id;
  final String nombre;

  const SystemRole({
    required this.id,
    required this.nombre,
  });

  factory SystemRole.fromJson(Map<String, dynamic> json) {
    return SystemRole(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
  };
}
