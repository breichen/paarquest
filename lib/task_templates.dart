import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const categories = [
  'Romantik',
  'Essen',
  'Abenteuer',
  'Spaß & Spiel',
  'Wellness',
  'Intimität',
  'Verführung',
  'Alltag',
  'Sex',
];

const categoryIcons = <String, IconData>{
  'Romantik': Icons.favorite,
  'Essen': Icons.restaurant,
  'Abenteuer': Icons.explore,
  'Spaß & Spiel': Icons.sports_esports,
  'Wellness': Icons.spa,
  'Intimität': Icons.favorite_border,
  'Verführung': Icons.whatshot,
  'Alltag': Icons.home,
  'Sex': Icons.local_fire_department,
};

class Tpl {
  final String title, category, description;
  final int coins, hours;
  const Tpl(this.title, this.category, this.coins, this.hours, this.description);

  bool same(Tpl o) =>
      title == o.title &&
      category == o.category &&
      coins == o.coins &&
      hours == o.hours &&
      description == o.description;

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'coins': coins,
        'hours': hours,
        'description': description,
      };

  factory Tpl.fromJson(Map<String, dynamic> j) =>
      Tpl(j['title'], j['category'], j['coins'], j['hours'], j['description'] ?? '');
}

// Beschreibungen sind an den Empfänger gerichtet ("du"), "mich/uns" ist der Absender.
const builtInTemplates = <Tpl>[
  // Romantik
  Tpl('Versteckte Liebesnotiz', 'Romantik', 5, 24,
      'Versteck irgendwo eine kleine Nachricht für mich, die ich heute finde.'),
  Tpl('Kuscheln ohne Handy', 'Romantik', 10, 24,
      'Eine Stunde nur wir zwei, ohne Handy und ohne Ablenkung.'),
  Tpl('Liebesbrief schreiben', 'Romantik', 15, 72,
      'Schreib mir einen handgeschriebenen Brief, in dem du sagst, was du an mir liebst.'),
  Tpl('Kleines Geschenk besorgen', 'Romantik', 15, 72,
      'Bring mir eine Kleinigkeit mit, bei der du an mich gedacht hast.'),
  Tpl('Date-Abend planen', 'Romantik', 25, 168,
      'Plane einen Abend nur für uns. Ort, Essen und Programm sind deine Überraschung.'),
  // Essen
  Tpl('Frühstück ans Bett bringen', 'Essen', 15, 48,
      'Weck mich mit einem liebevoll gemachten Frühstück.'),
  Tpl('Neues Rezept ausprobieren', 'Essen', 15, 168,
      'Such ein Rezept aus, das wir noch nie hatten, und koch es für uns.'),
  Tpl('Mein Leibgericht kochen', 'Essen', 20, 72,
      'Koch mein Lieblingsessen, so gut du kannst.'),
  Tpl('Picknick vorbereiten', 'Essen', 20, 168,
      'Pack einen Korb mit Leckereien und such einen schönen Platz für uns aus.'),
  // Abenteuer
  Tpl('Neuen Ort entdecken', 'Abenteuer', 20, 168,
      'Finde einen Ort in der Nähe, an dem wir noch nie waren, und nimm mich mit.'),
  Tpl('Etwas Neues ausprobieren', 'Abenteuer', 25, 336,
      'Such eine Aktivität aus, die wir beide noch nie gemacht haben.'),
  Tpl('Spontaner Ausflug', 'Abenteuer', 30, 168,
      'Plane einen spontanen Ausflug.'),
  Tpl('Überraschungsausflug', 'Abenteuer', 40, 336,
      'Organisiere einen Ausflug und verrate mir vorher nur, was ich einpacken soll.'),
  // Spaß & Spiel
  Tpl('Bring mich zum Lachen', 'Spaß & Spiel', 5, 24,
      'Bring mich heute zum Lachen.'),
  Tpl('Lustige Challenge erfinden', 'Spaß & Spiel', 10, 72,
      'Erfinde eine lustige Challenge für uns.'),
  Tpl('Spieleabend organisieren', 'Spaß & Spiel', 15, 168,
      'Such Spiele aus und sorg für Snacks. Wer verliert, bekommt eine kleine Strafe.'),
  // Wellness
  Tpl('Fußmassage', 'Wellness', 10, 24,
      'Massiere mir die Füße, ganz in Ruhe.'),
  Tpl('Gemeinsamer Spaziergang', 'Wellness', 10, 72,
      'Lass uns gemeinsam einen Spaziergang machen, ohne Eile und ohne Handy.'),
  Tpl('Massage', 'Wellness', 20, 48,
      'Gib mir eine Massage, gern mit Öl und ohne Zeitdruck.'),
  Tpl('Entspannter Abend', 'Wellness', 20, 72,
      'Bereite mir einen entspannten Abend vor.'),
  // Intimität
  Tpl('Die lange aufgesparte Frage', 'Intimität', 10, 72,
      'Stelle mir eine Frage, die du mir schon lange stellen wolltest.'),
  Tpl('Glücklicher Moment', 'Intimität', 10, 72,
      'Erzähl mir von einem Moment, in dem du besonders glücklich mit mir warst.'),
  Tpl('Gemeinsam träumen', 'Intimität', 10, 72,
      'Erzähl mir von einem Wunsch für unsere Zukunft und frag mich nach meinem.'),
  // Verführung
  Tpl('Heiße Nachricht', 'Verführung', 10, 24,
      'Schick mir eine heiße Nachricht.'),
  Tpl('Flirten wie am Anfang', 'Verführung', 15, 48,
      'Flirte heute mit mir, als würden wir uns gerade erst kennenlernen.'),
  Tpl('Verführerisches Outfit', 'Verführung', 25, 72,
      'Überrasch mich mit einem Outfit, das mich sprachlos macht.'),
  // Alltag
  Tpl('Abwasch übernehmen', 'Alltag', 5, 24,
      'Übernimm heute den Abwasch.'),
  Tpl('Wäsche komplett erledigen', 'Alltag', 10, 48,
      'Wasch, trockne und leg die Wäsche zusammen.'),
  Tpl('Wohnung aufräumen', 'Alltag', 15, 48,
      'Bring die Wohnung in einen Zustand, in dem wir uns beide wohlfühlen.'),
  // Sex
  Tpl('Eine Fantasie erzählen', 'Sex', 15, 72,
      'Erzähl mir von einer Fantasie, die du schon länger hast.'),
  Tpl('Sinnliche Massage', 'Sex', 20, 48,
      'Verwöhn mich mit einer langen, sinnlichen Massage.'),
  Tpl('Überraschung im Schlafzimmer', 'Sex', 30, 168,
      'Überrasch mich im Schlafzimmer mit etwas, das ich nicht erwarte.'),
];

int compareTpl(Tpl a, Tpl b) {
  final c = categories.indexOf(a.category).compareTo(categories.indexOf(b.category));
  if (c != 0) return c;
  final k = a.coins.compareTo(b.coins);
  return k != 0 ? k : a.title.compareTo(b.title);
}

/// Eingebaute Aufgaben plus die auf diesem Gerät gespeicherten.
/// Ändern, Löschen und Speichern wirken nur auf dieses Gerät.
/// Eine gespeicherte Aufgabe mit gleichem Titel ersetzt die eingebaute,
/// gelöschte eingebaute Aufgaben werden ausgeblendet.
class TemplateStore extends ChangeNotifier {
  static const _key = 'saved_templates';
  static const _hiddenKey = 'hidden_templates';
  List<Tpl> saved = [];
  Set<String> hidden = {};

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        saved = (jsonDecode(raw) as List)
            .map((e) => Tpl.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      hidden = (p.getStringList(_hiddenKey) ?? []).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(saved.map((t) => t.toJson()).toList()));
    await p.setStringList(_hiddenKey, hidden.toList());
  }

  bool _isBuiltIn(String title) => builtInTemplates.any((b) => b.title == title);

  List<Tpl> get all {
    final titles = saved.map((t) => t.title).toSet();
    return [
      ...builtInTemplates.where((t) => !titles.contains(t.title) && !hidden.contains(t.title)),
      ...saved,
    ];
  }

  List<Tpl> forCategory(String? category) {
    final l = all.where((t) => category == null || t.category == category).toList();
    l.sort(compareTpl);
    return l;
  }

  Tpl? find(String title) {
    for (final t in all) {
      if (t.title == title) return t;
    }
    return null;
  }

  bool isSaved(Tpl t) => saved.any((s) => s.title == t.title);

  bool get hasHidden => hidden.isNotEmpty;

  Future<void> save(Tpl t) async {
    saved.removeWhere((s) => s.title == t.title);
    saved.add(t);
    hidden.remove(t.title);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(Tpl t) async {
    saved.removeWhere((s) => s.title == t.title);
    if (_isBuiltIn(t.title)) hidden.add(t.title);
    notifyListeners();
    await _persist();
  }

  Future<void> update(Tpl old, Tpl updated) async {
    saved.removeWhere((s) => s.title == old.title);
    if (_isBuiltIn(old.title) && old.title != updated.title) hidden.add(old.title);
    saved.removeWhere((s) => s.title == updated.title);
    saved.add(updated);
    hidden.remove(updated.title);
    notifyListeners();
    await _persist();
  }

  /// Blendet gelöschte eingebaute Aufgaben wieder ein.
  Future<void> restoreHidden() async {
    hidden.clear();
    notifyListeners();
    await _persist();
  }
}
