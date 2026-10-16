import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Aufgaben, die auf diesem Gerät aus der Liste gelöscht wurden.
/// In Supabase bleibt alles unverändert, der Partner sieht die Aufgabe weiter,
/// und Münzstand und Übersicht zählen sie weiter mit.
class HiddenTasks extends ChangeNotifier {
  static const _key = 'hidden_tasks';
  Set<String> ids = {};

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      ids = (p.getStringList(_key) ?? []).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> add(String id) async {
    ids.add(id);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ids.toList());
  }
}
