import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'hidden_tasks.dart';
import 'models.dart';
import 'push.dart';
import 'send_page.dart';
import 'shop_page.dart';
import 'task_templates.dart';
import 'tasks_page.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Push.init(me);
  runApp(const PaarQuestApp());
}

class PaarQuestApp extends StatelessWidget {
  const PaarQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5B2A4E),
        secondary: coinGold,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F2F7),
    );
    return MaterialApp(
      title: 'PaarQuest',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(textTheme: GoogleFonts.latoTextTheme(base.textTheme)),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Task> tasks = [];
  List<Purchase> purchases = [];
  final store = TemplateStore();
  final hidden = HiddenTasks();
  int tab = 0;
  String? error;
  bool tasksLoaded = false, purchasesLoaded = false;
  Timer? ticker;
  StreamSubscription? s1, s2;

  late final actions = TaskActions(
    accept: accept,
    decline: decline,
    counter: counter,
    discard: discard,
    requestDone: requestDone,
    confirmDone: confirmDone,
    rejectDone: rejectDone,
    cancel: cancel,
    delete: delete,
  );

  @override
  void initState() {
    super.initState();
    store.load();
    hidden.addListener(() {
      if (mounted) setState(() {});
    });
    hidden.load();
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
    s2 = db.from('purchases').stream(primaryKey: ['id']).order('created_at').listen(
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
    ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    ticker?.cancel();
    s1?.cancel();
    s2?.cancel();
    super.dispose();
  }

  int balance(String who) =>
      tasks.where((t) => t.status == 'done' && t.assignee == who).fold(0, (a, t) => a + t.coins) -
      purchases.where((p) => p.buyer == who).fold(0, (a, p) => a + p.cost);

  void toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> run(Future<dynamic> Function() action, [String? ok]) async {
    try {
      await action();
      if (ok != null && mounted) toast(ok);
    } catch (e) {
      if (mounted) toast('Fehler: $e');
    }
  }

  Future<void> _update(String id, Map<String, dynamic> v) =>
      db.from('tasks').update(v).eq('id', id);

  // ── Aufgaben-Aktionen ──
  void accept(Task t) => run(() => _update(t.id, {
        'status': 'accepted',
        'deadline': DateTime.now().add(Duration(hours: t.hours)).toUtc().toIso8601String(),
      }), 'Angenommen');

  void decline(Task t) => run(() => _update(t.id, {'status': 'declined'}), 'Abgelehnt');
  void discard(Task t) => run(() => _update(t.id, {'status': 'discarded'}), 'Verworfen');

  void requestDone(Task t) => run(() => _update(t.id, {'status': 'review'}),
      'Erledigung an ${t.creator} gemeldet');

  void confirmDone(Task t) => run(() => _update(t.id, {
        'status': 'done',
        'done_at': DateTime.now().toUtc().toIso8601String(),
      }), '${t.assignee} bekommt ${t.coins} Münzen');

  void rejectDone(Task t) =>
      run(() => _update(t.id, {'status': 'accepted'}), 'Zurück an ${t.assignee}');

  Future<void> cancel(Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aufgabe abbrechen?'),
        content: Text(t.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Zurück')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abbrechen')),
        ],
      ),
    );
    if (ok != true) return;
    run(() => _update(t.id, {'status': 'cancelled', 'cancelled_by': me}), 'Abgebrochen');
  }

  /// Entfernt die Aufgabe nur aus der Liste dieses Geräts.
  Future<void> delete(Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aufgabe löschen?'),
        content: Text('„${t.title}“ verschwindet nur auf diesem Gerät. '
            '$partner sieht sie weiterhin, und die Münzen bleiben unverändert.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await hidden.add(t.id);
  }

  Future<void> counter(Task t) async {
    final r = await showDialog<(int, int)>(
      context: context,
      builder: (_) => ProposalDialog(coins: t.coins, hours: t.hours),
    );
    if (r == null) return;
    run(() => _update(t.id, {'coins': r.$1, 'hours': r.$2, 'status': 'countered'}),
        'Vorschlag an $partner geschickt');
  }

  /// Gibt true zurück, wenn die Aufgabe wirklich in der Datenbank gelandet ist.
  Future<bool> send(String title, String description, String category, int coins, int hours) async {
    try {
      await db.from('tasks').insert({
        'title': title,
        'description': description,
        'category': category,
        'creator': me,
        'assignee': partner,
        'coins': coins,
        'hours': hours,
      });
      if (mounted) toast('✓ Aufgabe an $partner geschickt');
      return true;
    } catch (e) {
      if (mounted) toast('Senden fehlgeschlagen: $e');
      return false;
    }
  }

  Future<void> buy(Reward r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(r.title),
        content: Text('Für ${r.cost} Münzen einlösen? $partner wird benachrichtigt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Einlösen')),
        ],
      ),
    );
    if (ok != true) return;
    run(() => db.from('purchases').insert({'buyer': me, 'reward': r.title, 'cost': r.cost}),
        'Eingelöst');
  }

  void fulfill(Purchase p) =>
      run(() => db.from('purchases').update({'status': 'fulfilled'}).eq('id', p.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo $me'),
        bottom: CoinBar(
          mine: balance(me),
          theirs: balance(partner),
          onTap: () => showStats(context, tasks, balance),
        ),
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Verbindung zu Supabase fehlgeschlagen:\n$error\n\n'
                    'Prüfe URL, Key und ob das SQL-Schema ausgeführt wurde.'),
              ),
            )
          // IndexedStack erhält z. B. halb ausgefüllte Eingaben beim Tab-Wechsel
          : IndexedStack(index: tab, children: [
              TasksPage(tasks: tasks, hidden: hidden.ids, actions: actions),
              SendPage(store: store, onSend: send),
              ShopPage(coins: balance(me), purchases: purchases, onBuy: buy, onFulfill: fulfill),
            ]),
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
