class ApiConfig {
  // Si usas emulador Android usa '10.0.2.2'
  // Si usas dispositivo físico conectado por Wi-Fi, pon la IP local de tu compu (ej. '192.168.1.75')
  static const String host = '192.168.1.13';
  static const String port = '3000';

  static String get baseUrl => 'http://$host:$port';
}