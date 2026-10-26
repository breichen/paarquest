import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart'; // wird von `flutterfire configure` erzeugt
import 'web_push.dart';

/// Android: echte Pushes über Firebase (auch bei geschlossener App).
/// iOS: kein Firebase. Die App zeigt Benachrichtigungen selbst an, solange sie
/// läuft (siehe `inApp` und die Auswertung der Live-Daten in main.dart).
/// Web: Bei offener App erscheinen Meldungen als Banner (Live-Daten), bei
/// geschlossener App kommen Web-Pushes über Firebase (web/push.js).
class Push {
  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'paarquest',
    'Aufgaben und Münzen',
    importance: Importance.high,
  );

  /// true, wenn die App Änderungen selbst melden muss (kein FCM).
  static bool get inApp => !_android;

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Für Banner-Meldungen im Browser (in MaterialApp eingetragen).
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static Future<void> init(String userName) async {
    _user = userName;
    if (kIsWeb) {
      _refreshWebToken(); // nicht abwarten, der Start soll nicht hängen
      return;
    }
    try {
      await _local.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    } catch (e) {
      debugPrint('Lokale Benachrichtigungen fehlgeschlagen: $e');
    }

    if (!_android) return; // iOS: ohne Firebase weiter

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();

      // Bei geöffneter App selbst anzeigen
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) show(n.title ?? '', n.body ?? '');
      });

      Future<void> save(String? token) async {
        if (token == null) return;
        await Supabase.instance.client
            .from('device_tokens')
            .upsert({'user_name': userName, 'token': token});
      }

      await save(await fm.getToken());
      fm.onTokenRefresh.listen(save);
    } catch (e) {
      // Die App soll auch ohne funktionierende Pushes starten.
      debugPrint('Push-Initialisierung fehlgeschlagen: $e');
    }
  }

  static String _user = '';

  /// Browser: Token beim Start auffrischen, falls Benachrichtigungen erlaubt sind.
  static Future<void> _refreshWebToken() async {
    try {
      final token = await webPushToken();
      if (token.isNotEmpty) await saveToken(token, platform: 'web');
    } catch (e) {
      debugPrint('Web-Push-Token speichern fehlgeschlagen: $e');
    }
  }

  /// Speichert ein Gerät (Token) für diese Person; pro Person sind mehrere möglich.
  static Future<void> saveToken(String token, {required String platform}) async {
    await Supabase.instance.client.from('device_tokens').upsert({
      'user_name': _user,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  static Future<void> show(String title, String body) async {
    if (kIsWeb) {
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(body.isEmpty ? title : '$title\n$body'),
        ));
      return;
    }
    try {
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Anzeige fehlgeschlagen: $e');
    }
  }
}
