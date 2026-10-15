import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'push.dart';

// ───────────────────────── Konfiguration ─────────────────────────
// Flag vor dem Kompilieren:
//   Benjamin: flutter build apk --dart-define=IS_BENJAMIN=true
//   Theresa:  flutter build apk --dart-define=IS_BENJAMIN=false
const bool isBenjamin = bool.fromEnvironment('IS_BENJAMIN', defaultValue: true);

const supabaseUrl = 'https://dcmyhjbhcifevisbhjav.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjbXloamJoY2lmZXZpc2JoamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwODExMTAsImV4cCI6MjEwNzY1NzExMH0.hud9OcwF2iCa6C8dKmSDenNrkOcg4NvYWoi4VXTPymA';

const String me = isBenjamin ? 'Benjamin' : 'Theresa';
const String partner = isBenjamin ? 'Theresa' : 'Benjamin';

// ───────────────────────── Kataloge ─────────────────────────
const categories = ['Romantik', 'Essen', 'Sex', 'Überraschung', 'Alltag'];
const categoryIcons = <String, IconData>{
  'Romantik': Icons.favorite,
  'Essen': Icons.restaurant,
  'Sex': Icons.local_fire_department,
  'Überraschung': Icons.card_giftcard,
  'Alltag': Icons.home,
};
const hourOptions = [6, 12, 24, 48, 72, 168, 336];

class Tpl {
  final String title, category;
  final int coins, hours;
  const Tpl(this.title, this.category, this.coins, this.hours);
}

const templates = <Tpl>[
  Tpl('Liebesbrief schreiben', 'Romantik', 15, 72),
  Tpl('Eine Stunde Kuscheln ohne Handy', 'Romantik', 10, 24),
  Tpl('Date-Abend planen', 'Romantik', 25, 168),
  Tpl('Spaziergang bei Sonnenuntergang', 'Romantik', 10, 72),
  Tpl('Fußmassage', 'Romantik', 10, 24),
  Tpl('Frühstück ans Bett bringen', 'Essen', 15, 48),
  Tpl('Dein Leibgericht kochen', 'Essen', 20, 72),
  Tpl('Neues Rezept ausprobieren', 'Essen', 15, 168),
  Tpl('Picknick vorbereiten', 'Essen', 20, 168),
  Tpl('Massage mit Öl', 'Sex', 20, 48),
  Tpl('Eine Fantasie erzählen', 'Sex', 15, 72),
  Tpl('Überraschung im Schlafzimmer', 'Sex', 30, 168),
  Tpl('Verführerisches Outfit', 'Sex', 25, 72),
  Tpl('Kleines Geschenk besorgen', 'Überraschung', 15, 72),
  Tpl('Versteckte Liebesnotiz', 'Überraschung', 5, 24),
  Tpl('Überraschungsausflug', 'Überraschung', 40, 336),
  Tpl('Abwasch übernehmen', 'Alltag', 5, 24),
  Tpl('Wohnung aufräumen', 'Alltag', 15, 48),
  Tpl('Wäsche komplett erledigen', 'Alltag', 10, 48),
];

class Reward {
  final String title;
  final int cost;
  final IconData icon;
  const Reward(this.title, this.cost, this.icon);
}

const rewards = <Reward>[
  Reward('Essen gehen (du wählst)', 60, Icons.restaurant_menu),
  Reward('Er/Sie kocht für dich', 40, Icons.soup_kitchen),
  Reward('Entscheidungsabend', 80, Icons.nightlife),
  Reward('Entscheidungstag', 150, Icons.wb_sunny),
  Reward('Massage (30 Min)', 50, Icons.spa),
  Reward('Frühstück ans Bett', 35, Icons.free_breakfast),
  Reward('Einmal Abwasch erlassen', 20, Icons.clean_hands),
  Reward('Filmabend – du suchst aus', 25, Icons.movie),
];

// ───────────────────────── Modelle ─────────────────────────
class Task {
  final String id, title, category, creator, assignee, status;
  final String? cancelledBy;
  final int coins, hours;
  final DateTime? deadline;
  Task.fromMap(Map<String, dynamic> m)
      : id = m['id'],
        cancelledBy = m['cancelled_by'],
        title = m['title'],
        category = m['category'],
        creator = m['creator'],
        assignee = m['assignee'],
        status = m['status'],
        coins = m['coins'],
        hours = m['hours'],
        deadline = m['deadline'] == null
            ? null
            : DateTime.parse(m['deadline']).toLocal();

  bool get needsMyAction =>
      (status == 'pending' && assignee == me) ||
      (status == 'countered' && creator == me);
}

class Purchase {
  final String id, buyer, reward, status;
  final int cost;
  Purchase.fromMap(Map<String, dynamic> m)
      : id = m['id'],
        buyer = m['buyer'],
        reward = m['reward'],
        status = m['status'],
        cost = m['cost'];
}

// ───────────────────────── Helfer ─────────────────────────
String hoursLabel(int h) =>
    h % 24 == 0 ? '${h ~/ 24} Tag${h == 24 ? '' : 'e'}' : '$h Std';

String _span(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} T ${d.inHours % 24} Std';
  if (d.inHours >= 1) return '${d.inHours} Std ${d.inMinutes % 60} Min';
  return '${d.inMinutes} Min';
}

String timeLeft(DateTime deadline) {
  final d = deadline.difference(DateTime.now());
  return d.isNegative ? 'Überfällig seit ${_span(-d)}' : 'Noch ${_span(d)}';
}

String _other(String n) => n == 'Benjamin' ? 'Theresa' : 'Benjamin';

/// Meldung für eine Änderung an einer Aufgabe: (Empfänger, Titel, Text).
(String, String, String)? taskMessage(Task? o, Task r) {
  if (o == null) {
    return (
      r.assignee,
      'Neue Aufgabe von ${r.creator}',
      '${r.title} (${r.coins} Münzen, ${hoursLabel(r.hours)})'
    );
  }
  if (o.status == r.status) return null;
  switch (r.status) {
    case 'countered':
      return (
        r.creator,
        '${r.assignee} macht einen Vorschlag',
        '${r.title}: ${r.coins} Münzen, ${hoursLabel(r.hours)}'
      );
    case 'accepted':
      return o.status == 'pending'
          ? (r.creator, '${r.assignee} hat angenommen', r.title)
          : (r.assignee, '${r.creator} akzeptiert deinen Vorschlag', r.title);
    case 'declined':
      return (r.creator, '${r.assignee} hat abgelehnt', r.title);
    case 'discarded':
      return (r.assignee, '${r.creator} hat den Vorschlag verworfen', r.title);
    case 'done':
      return (
        r.creator,
        '${r.assignee} hat erledigt',
        '${r.title} (+${r.coins} Münzen)'
      );
    case 'cancelled':
      final by = r.cancelledBy ?? r.assignee;
      return (_other(by), '$by hat abgebrochen', r.title);
  }
  return null;
}

(String, String, String)? purchaseMessage(Purchase? o, Purchase r) {
  if (o == null) {
    return (
      _other(r.buyer),
      '${r.buyer} hat etwas eingelöst',
      '${r.reward} (${r.cost} Münzen)'
    );
  }
  if (o.status != r.status && r.status == 'fulfilled') {
    return (r.buyer, '${_other(r.buyer)} hat erfüllt', r.reward);
  }
  return null;
}

SupabaseClient get db => Supabase.instance.client;

// ───────────────────────── App ─────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Push.init(me);
  runApp(const PaarQuestApp());
}

class PaarQuestApp extends StatelessWidget {
  const PaarQuestApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PaarQuest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B2A4E),
            secondary: const Color(0xFFE0A526),
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F2F7),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Task> tasks = [];
  List<Purchase> purchases = [];
  int tab = 0;
  String? error;
  bool tasksLoaded = false, purchasesLoaded = false;
  Timer? ticker;
  StreamSubscription? s1, s2;

  @override
  void initState() {
    super.initState();
    s1 = db.from('tasks').stream(primaryKey: ['id']).order('created_at').listen(
          (rows) {
            final next = rows.map(Task.fromMap).toList();
            if (Push.inApp && tasksLoaded) {
              final old = {for (final t in tasks) t.id: t};
              for (final t in next) {
                final m = taskMessage(old[t.id], t);
                if (m != null && m.$1 == me) Push.show(m.$2, m.$3);
              }
            }
            tasksLoaded = true;
            setState(() => tasks = next);
          },
          onError: (e) => setState(() => error = '$e'),
        );
    s2 = db
        .from('purchases')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen(
          (rows) {
            final next = rows.map(Purchase.fromMap).toList();
            if (Push.inApp && purchasesLoaded) {
              final old = {for (final p in purchases) p.id: p};
              for (final p in next) {
                final m = purchaseMessage(old[p.id], p);
                if (m != null && m.$1 == me) Push.show(m.$2, m.$3);
              }
            }
            purchasesLoaded = true;
            setState(() => purchases = next);
          },
          onError: (e) => setState(() => error = '$e'),
        );
    ticker =
        Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    ticker?.cancel();
    s1?.cancel();
    s2?.cancel();
    super.dispose();
  }

  int balance(String who) =>
      tasks
          .where((t) => t.status == 'done' && t.assignee == who)
          .fold(0, (a, t) => a + t.coins) -
      purchases.where((p) => p.buyer == who).fold(0, (a, p) => a + p.cost);

  void toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> run(Future<dynamic> Function() action, [String? ok]) async {
    try {
      await action();
      if (ok != null && mounted) toast(ok);
    } catch (e) {
      if (mounted) toast('Fehler: $e');
    }
  }

  // ── Aktionen ──
  Future<void> _update(String id, Map<String, dynamic> v) =>
      db.from('tasks').update(v).eq('id', id);

  void accept(Task t) => run(
      () => _update(t.id, {
            'status': 'accepted',
            'deadline': DateTime.now()
                .add(Duration(hours: t.hours))
                .toUtc()
                .toIso8601String(),
          }),
      'Angenommen');

  void decline(Task t) =>
      run(() => _update(t.id, {'status': 'declined'}), 'Abgelehnt');
  void discard(Task t) =>
      run(() => _update(t.id, {'status': 'discarded'}), 'Verworfen');

  void complete(Task t) => run(
      () => _update(t.id, {
            'status': 'done',
            'done_at': DateTime.now().toUtc().toIso8601String(),
          }),
      '+${t.coins} Münzen!');

  Future<void> cancel(Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aufgabe abbrechen?'),
        content: Text(t.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Zurück')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Abbrechen')),
        ],
      ),
    );
    if (ok != true) return;
    run(() => _update(t.id, {'status': 'cancelled', 'cancelled_by': me}),
        'Abgebrochen');
  }

  Future<void> counter(Task t) async {
    final r = await showDialog<(int, int)>(
      context: context,
      builder: (_) => ProposalDialog(coins: t.coins, hours: t.hours),
    );
    if (r == null) return;
    run(
        () => _update(
            t.id, {'coins': r.$1, 'hours': r.$2, 'status': 'countered'}),
        'Vorschlag an $partner geschickt');
  }

  Future<void> send(String title, String category, int coins, int hours) => run(
        () => db.from('tasks').insert({
          'title': title,
          'category': category,
          'creator': me,
          'assignee': partner,
          'coins': coins,
          'hours': hours,
        }),
        'An $partner geschickt',
      );

  Future<void> buy(Reward r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(r.title),
        content: Text(
            'Für ${r.cost} Münzen einlösen? $partner wird benachrichtigt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Einlösen')),
        ],
      ),
    );
    if (ok != true) return;
    run(
        () => db
            .from('purchases')
            .insert({'buyer': me, 'reward': r.title, 'cost': r.cost}),
        'Eingelöst');
  }

  void fulfill(Purchase p) => run(() =>
      db.from('purchases').update({'status': 'fulfilled'}).eq('id', p.id));

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    final pages = [
      TasksPage(
          tasks: tasks,
          onAccept: accept,
          onDecline: decline,
          onCounter: counter,
          onDiscard: discard,
          onDone: complete,
          onCancel: cancel),
      SendPage(onSend: send),
      ShopPage(
          coins: balance(me),
          purchases: purchases,
          onBuy: buy,
          onFulfill: fulfill),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo $me'),
        actions: [
          CoinChip(label: 'Du', value: balance(me)),
          CoinChip(label: partner, value: balance(partner)),
          const SizedBox(width: 8),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Verbindung zu Supabase fehlgeschlagen:\n$error\n\n'
                    'Prüfe URL, Key und ob das SQL-Schema ausgeführt wurde.'),
              ),
            )
          : pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Aufgaben'),
          NavigationDestination(icon: Icon(Icons.send), label: 'Senden'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
        ],
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  final String label;
  final int value;
  const CoinChip({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.monetization_on,
              color: Color(0xFFE0A526), size: 20),
          label: Text('$label: $value'),
        ),
      );
}

// ───────────────────────── Aufgabenliste ─────────────────────────
class TasksPage extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onAccept,
      onDecline,
      onCounter,
      onDiscard,
      onDone,
      onCancel;
  const TasksPage({
    super.key,
    required this.onCancel,
    required this.tasks,
    required this.onAccept,
    required this.onDecline,
    required this.onCounter,
    required this.onDiscard,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final active = tasks.where((t) => t.status == 'accepted').toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    final open = tasks
        .where((t) => t.status == 'pending' || t.status == 'countered')
        .toList()
      ..sort((a, b) =>
          (b.needsMyAction ? 1 : 0).compareTo(a.needsMyAction ? 1 : 0));
    final finished = tasks
        .where((t) =>
            ['done', 'declined', 'discarded', 'cancelled'].contains(t.status))
        .toList()
        .reversed
        .toList();

    Widget list(List<Task> l, String empty) => l.isEmpty
        ? Center(
            child: Text(empty, style: Theme.of(context).textTheme.bodyLarge))
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final t in l)
                TaskCard(
                  task: t,
                  onAccept: () => onAccept(t),
                  onDecline: () => onDecline(t),
                  onCounter: () => onCounter(t),
                  onDiscard: () => onDiscard(t),
                  onDone: () => onDone(t),
                  onCancel: () => onCancel(t),
                ),
            ],
          );

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(text: 'Aktiv (${active.length})'),
            Tab(text: 'Offen (${open.length})'),
            const Tab(text: 'Erledigt'),
          ]),
          Expanded(
            child: TabBarView(children: [
              list(active, 'Keine angenommenen Aufgaben.'),
              list(open, 'Nichts wartet auf eine Antwort.'),
              list(finished, 'Noch nichts erledigt.'),
            ]),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onAccept,
      onDecline,
      onCounter,
      onDiscard,
      onDone,
      onCancel;
  const TaskCard({
    super.key,
    required this.onCancel,
    required this.task,
    required this.onAccept,
    required this.onDecline,
    required this.onCounter,
    required this.onDiscard,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final t = task;
    final scheme = Theme.of(context).colorScheme;
    final who = t.creator == me
        ? 'von dir an ${t.assignee}'
        : 'von ${t.creator} an dich';

    String? info;
    Color infoColor = scheme.onSurfaceVariant;
    switch (t.status) {
      case 'accepted':
        info = timeLeft(t.deadline!);
        if (t.deadline!.isBefore(DateTime.now())) infoColor = scheme.error;
        break;
      case 'pending':
        info = t.needsMyAction ? null : 'Wartet auf ${t.assignee}';
        break;
      case 'countered':
        info = t.needsMyAction
            ? '${t.assignee} schlägt vor: ${t.coins} Münzen, ${hoursLabel(t.hours)}'
            : 'Dein Vorschlag wartet auf ${t.creator}';
        break;
      case 'done':
        info = 'Erledigt';
        break;
      case 'declined':
        info = 'Abgelehnt';
        break;
      case 'discarded':
        info = 'Verworfen';
        break;
      case 'cancelled':
        info = 'Abgebrochen';
        break;
    }

    final actions = <Widget>[];
    if (t.status == 'pending' && t.assignee == me) {
      actions.addAll([
        FilledButton(onPressed: onAccept, child: const Text('Annehmen')),
        OutlinedButton(onPressed: onCounter, child: const Text('Vorschlagen')),
        TextButton(onPressed: onDecline, child: const Text('Ablehnen')),
      ]);
    } else if (t.status == 'countered' && t.creator == me) {
      actions.addAll([
        FilledButton(onPressed: onAccept, child: const Text('Akzeptieren')),
        TextButton(onPressed: onDiscard, child: const Text('Verwerfen')),
      ]);
    } else if (t.status == 'accepted') {
      final overdue = t.deadline!.isBefore(DateTime.now());
      if (t.assignee == me) {
        actions.add(FilledButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check),
            label: Text('Erledigt (+${t.coins})')));
      }
      // Empfänger jederzeit, Absender nur bei abgelaufener Frist
      if (t.assignee == me || overdue) {
        actions.add(
            TextButton(onPressed: onCancel, child: const Text('Abbrechen')));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(categoryIcons[t.category] ?? Icons.star,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${t.category} · $who',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const Icon(Icons.monetization_on,
                  color: Color(0xFFE0A526), size: 18),
              const SizedBox(width: 2),
              Text('${t.coins}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(t.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              info == null ? 'Zeit: ${hoursLabel(t.hours)}' : info,
              style: TextStyle(color: infoColor),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Dialog: Gegenvorschlag ─────────────────────────
class ProposalDialog extends StatefulWidget {
  final int coins, hours;
  const ProposalDialog({super.key, required this.coins, required this.hours});
  @override
  State<ProposalDialog> createState() => _ProposalDialogState();
}

class _ProposalDialogState extends State<ProposalDialog> {
  late final TextEditingController coins =
      TextEditingController(text: '${widget.coins}');
  late int hours = hourOptions.contains(widget.hours) ? widget.hours : 24;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Gegenvorschlag'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: coins,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Münzen'),
          ),
          const SizedBox(height: 12),
          HoursDropdown(
              value: hours, onChanged: (v) => setState(() => hours = v)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final c = int.tryParse(coins.text);
              if (c == null || c < 0) return;
              Navigator.pop(context, (c, hours));
            },
            child: const Text('Senden'),
          ),
        ],
      );
}

class HoursDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const HoursDropdown(
      {super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(labelText: 'Zeit dafür'),
        items: [
          for (final h in hourOptions)
            DropdownMenuItem(value: h, child: Text(hoursLabel(h)))
        ],
        onChanged: (v) => onChanged(v ?? value),
      );
}

// ───────────────────────── Aufgabe senden ─────────────────────────
class SendPage extends StatefulWidget {
  final Future<void> Function(String, String, int, int) onSend;
  const SendPage({super.key, required this.onSend});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  String category = categories.first;
  final title = TextEditingController();
  final coins = TextEditingController(text: '10');
  int hours = 48;

  void pick(Tpl t) => setState(() {
        title.text = t.title;
        coins.text = '${t.coins}';
        hours = t.hours;
      });

  Future<void> submit() async {
    final c = int.tryParse(coins.text);
    if (title.text.trim().isEmpty || c == null || c < 0) return;
    await widget.onSend(title.text.trim(), category, c, hours);
    title.clear();
  }

  @override
  Widget build(BuildContext context) {
    final list = templates.where((t) => t.category == category).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Aufgabe für $partner',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final c in categories)
            ChoiceChip(
              avatar: Icon(categoryIcons[c], size: 16),
              label: Text(c),
              selected: c == category,
              onSelected: (_) => setState(() => category = c),
            ),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            for (final t in list)
              ListTile(
                dense: true,
                title: Text(t.title),
                trailing: Text('${t.coins} 🪙 · ${hoursLabel(t.hours)}'),
                onTap: () => pick(t),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Text('Oder selbst eingeben',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: title,
          decoration: const InputDecoration(
              labelText: 'Aufgabe', filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: coins,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Münzen', filled: true, fillColor: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: HoursDropdown(
                  value: hours, onChanged: (v) => setState(() => hours = v))),
        ]),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.send),
          label: Text('An $partner schicken'),
        ),
      ],
    );
  }
}

// ───────────────────────── Shop ─────────────────────────
class ShopPage extends StatelessWidget {
  final int coins;
  final List<Purchase> purchases;
  final void Function(Reward) onBuy;
  final void Function(Purchase) onFulfill;
  const ShopPage({
    super.key,
    required this.coins,
    required this.purchases,
    required this.onBuy,
    required this.onFulfill,
  });

  @override
  Widget build(BuildContext context) {
    final toDeliver = purchases
        .where((p) => p.buyer == partner && p.status == 'open')
        .toList();
    final mine = purchases
        .where((p) => p.buyer == me)
        .toList()
        .reversed
        .take(8)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Du hast $coins Münzen',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (toDeliver.isNotEmpty) ...[
          Text('$partner wartet auf dich',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final p in toDeliver)
            Card(
              child: ListTile(
                title: Text(p.reward),
                subtitle: Text('${p.cost} Münzen eingelöst'),
                trailing: FilledButton(
                    onPressed: () => onFulfill(p),
                    child: const Text('Erfüllt')),
              ),
            ),
          const SizedBox(height: 10),
        ],
        for (final r in rewards)
          Card(
            child: ListTile(
              leading:
                  Icon(r.icon, color: Theme.of(context).colorScheme.primary),
              title: Text(r.title),
              trailing: FilledButton(
                onPressed: coins >= r.cost ? () => onBuy(r) : null,
                child: Text('${r.cost} 🪙'),
              ),
            ),
          ),
        if (mine.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Deine Einlösungen',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final p in mine)
            ListTile(
              dense: true,
              title: Text(p.reward),
              trailing: Text(p.status == 'fulfilled' ? 'Erfüllt' : 'Offen'),
            ),
        ],
      ],
    );
  }
}
