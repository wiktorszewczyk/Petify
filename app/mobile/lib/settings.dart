import 'dart:io';

class Settings {
  static String getServerUrl() {
    // Android emulator uses 10.0.2.2 to reach host localhost
    // albo 8000
    if (Platform.isAndroid) return 'http://10.0.2.2:9000';
    // iOS simulator and web can use localhost
    return 'http://localhost:9000';
  }
}