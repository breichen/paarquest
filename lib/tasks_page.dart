import 'package:flutter/material.dart';
import 'config.dart';
import 'models.dart';
import 'task_templates.dart';
import 'widgets.dart';

class TaskActions {
  final void Function(Task) accept,
      decline,
      counter,
      discard,
      requestDone,
      confirmDone,
      rejectDone,
      cancel,
      delete;
  TaskActions({
    required this.accept,
    required this.decline,
    required this.counter,
    required this.discard,
    required this.requestDone,
    required this.confirmDone,
    required this.rejectDone,
    required this.cancel,
    required this.delete,
  });
}

/// Zeigt alle Aufgaben beider Personen. Die Kartenfarbe zeigt, für wen sie ist.
class TasksPage extends StatelessWidget {
  final List<Task> tasks;
  final Set<String> hidden; // auf diesem Gerät gelöscht
  final TaskActions actions;
  const TasksPage({super.key, required this.tasks, required this.hidden, required this.actions});

  @override
  Widget build(BuildContext context) {
    final far = DateTime(2100);
    final active = tasks.where((t) => t.status == 'accepted' || t.status == 'review').toList()
      ..sort((a, b) => (a.deadline ?? far).compareTo(b.deadline ?? far));
    final open = tasks.where((t) => t.status == 'pending' || t.status == 'countered').toList()
      ..sort((a, b) => (b.needsMyAction ? 1 : 0).compareTo(a.needsMyAction ? 1 : 0));
    final finished = tasks
        .where((t) =>
            ['done', 'declined', 'discarded', 'cancelled'].contains(t.status) &&
            !hidden.contains(t.id))
        .toList()
        .reversed
        .toList();

    Widget list(List<Task> l, String empty) => l.isEmpty
        ? Center(child: Text(empty, style: Theme.of(context).textTheme.bodyLarge))
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final t in l) TaskCard(task: t, a: actions)],
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
  final TaskActions a;
  const TaskCard({super.key, required this.task, required this.a});

  @override
  Widget build(BuildContext context) {
    final t = task;
    final scheme = Theme.of(context).colorScheme;
    final color = personColor(t.assignee);
    final from = t.creator == me ? 'dir' : t.creator;

    String? info;
    Color infoColor = scheme.onSurfaceVariant;
    switch (t.status) {
      case 'accepted':
        info = timeLeft(t.deadline!);
        if (t.overdue) infoColor = scheme.error;
        break;
      case 'review':
        info = t.creator == me
            ? '${t.assignee} meldet: erledigt. Bitte prüfen.'
            : 'Wartet auf Bestätigung von ${t.creator}';
        break;
      case 'pending':
        info = t.assignee == me ? null : 'Wartet auf ${t.assignee}';
        break;
      case 'countered':
        info = t.creator == me
            ? '${t.assignee} schlägt vor: ${t.coins} Münzen, ${hoursLabel(t.hours)}'
            : 'Dein Vorschlag wartet auf ${t.creator}';
        break;
      case 'done':
        info = 'Erledigt und bestätigt';
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

    final buttons = <Widget>[];
    if (t.status == 'pending' && t.assignee == me) {
      buttons.addAll([
        FilledButton(onPressed: () => a.accept(t), child: const Text('Annehmen')),
        OutlinedButton(onPressed: () => a.counter(t), child: const Text('Vorschlagen')),
        TextButton(onPressed: () => a.decline(t), child: const Text('Ablehnen')),
      ]);
    } else if (t.status == 'countered' && t.creator == me) {
      buttons.addAll([
        FilledButton(onPressed: () => a.accept(t), child: const Text('Akzeptieren')),
        TextButton(onPressed: () => a.discard(t), child: const Text('Verwerfen')),
      ]);
    } else if (t.status == 'accepted') {
      if (t.assignee == me) {
        buttons.add(FilledButton.icon(
          onPressed: () => a.requestDone(t),
          icon: const Icon(Icons.check),
          label: const Text('Erledigung anfragen'),
        ));
      }
      // Empfänger jederzeit, Absender nur bei abgelaufener Frist
      if (t.assignee == me || t.overdue) {
        buttons.add(TextButton(onPressed: () => a.cancel(t), child: const Text('Abbrechen')));
      }
    } else if (t.status == 'review' && t.creator == me) {
      buttons.addAll([
        FilledButton.icon(
          onPressed: () => a.confirmDone(t),
          icon: const Icon(Icons.verified),
          label: Text('Bestätigen (+${t.coins})'),
        ),
        TextButton(onPressed: () => a.rejectDone(t), child: const Text('Noch nicht')),
      ]);
    } else if (['done', 'declined', 'discarded', 'cancelled'].contains(t.status)) {
      buttons.add(TextButton.icon(
        onPressed: () => a.delete(t),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Löschen'),
      ));
    }

    return PlainCard(
      color: personLight(t.assignee),
      border: color.withAlpha(110),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration:
                    BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  t.assignee == me ? 'Für dich' : 'Für ${t.assignee}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Icon(categoryIcons[t.category] ?? Icons.star, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${t.category} · von $from',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.monetization_on, color: coinGold, size: 18),
              const SizedBox(width: 2),
              Text('${t.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            Text(t.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (t.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.description, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text(info ?? 'Zeit: ${hoursLabel(t.hours)}', style: TextStyle(color: infoColor)),
            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: buttons),
            ],
          ],
        ),
      ),
    );
  }
}
