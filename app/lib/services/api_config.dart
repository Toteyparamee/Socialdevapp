import 'dart:io' show Platform;

class ApiConfig {
  ApiConfig._();

  static final String _host =
      Platform.isAndroid ? '10.0.2.2' : 'localhost';

  /// Kong gateway port (NodePort 30000)
  static const int _kongPort = 30000;

  static String get gateway => 'http://$_host:$_kongPort';

  static String get loginUrl => gateway;
  static String get imageUrl => gateway;
  static String get problemUrl => gateway;
  static String get activityUrl => gateway;
  static String get chatUrl => gateway;
}
