import 'dart:io';

class Settings {
  static const _host = '192.168.1.11';
  static const _port = '8222';

  static String getServerUrl() {
    return 'http://$_host:$_port';
  }
}