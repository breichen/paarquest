import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart'; // wird von `flutterfire configure` erzeugt

/// Android: echte Pushes über Firebase (auch bei geschlossener App).
/// iOS: kein Firebase. Die App zeigt Benachrichtigungen selbst an, solange sie
/// läuft (siehe `inApp` und die Auswertung der Live-Daten in main.dart).
class Push {
  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'paarquest',
    'Aufgaben und Münzen',
    importance: Importance.high,
  );

  /// true, wenn die App Änderungen selbst melden muss (kein FCM).
  static bool get inApp => !Platform.isAndroid;

  static Future<void> init(String userName) async {
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

    if (!Platform.isAndroid) return; // iOS: ohne Firebase weiter

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

  static Future<void> show(String title, String body) async {
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
