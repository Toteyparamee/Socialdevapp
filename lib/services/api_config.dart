class ApiConfig {
  ApiConfig._();
  static const String gateway = 'https://socialdev.parameedev.online';

  static String get loginUrl => gateway;
  static String get schoolsUrl => '$gateway/schools';
  static String get activityBase => '$gateway/server/activity/api/activities';
  static String get imageBase => '$gateway/server/image/api/images';
  static String get problemBase => '$gateway/server/problem';
  static String get chatBase => '$gateway/server/chat/api/chat';
}
