// Android/iOS: Web-Push gibt es dort nicht (siehe push.dart).
Future<bool> webPushSupported() async => false;
String webPushPermission() => 'unsupported';
Future<String> webPushEnable() async => '';
Future<String> webPushToken() async => '';
