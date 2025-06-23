import 'dart:io';

class Settings {
  static const _host = 'backend.petify.x5z1fu.com';
  static const _port = '8222';

  static String getServerUrl() {
    return 'http://$_host:$_port';
  }
}