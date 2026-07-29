class Edificio {
  final int id;
  final String nombre;

  Edificio({
    required this.id,
    required this.nombre,
  });

  factory Edificio.fromJson(Map<String, dynamic> json) {
    return Edificio(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
  };
}

class Aula {
  final int id;
  final String nombre;
  final int idEdificio;
  final Edificio? edificio;

  Aula({
    required this.id,
    required this.nombre,
    required this.idEdificio,
    this.edificio,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    final edifJson = json['edificio'];
    return Aula(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      idEdificio: json['idEdificio'] as int? ?? (edifJson != null ? edifJson['id'] as int? ?? 0 : 0),
      edificio: edifJson != null ? Edificio.fromJson(edifJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'idEdificio': idEdificio,
    if (edificio != null) 'edificio': edificio!.toJson(),
  };
}
