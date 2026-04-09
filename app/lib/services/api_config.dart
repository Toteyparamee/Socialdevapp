import 'dart:io' show Platform;

class ApiConfig {
  ApiConfig._();

  static final String _host =
      Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static String get loginUrl => 'http://$_host:8080';
  static String get imageUrl => 'http://$_host:8081';
  static String get problemUrl => 'http://$_host:8083';
  static String get activityUrl => 'http://$_host:8084';
  static String get chatUrl => 'http://$_host:8085';
}
