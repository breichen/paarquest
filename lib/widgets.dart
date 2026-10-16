import 'package:flutter/material.dart';
import 'config.dart';
import 'models.dart';

const hourOptions = [6, 12, 24, 48, 72, 168, 336];
const coinGold = Color(0xFFE0A526);

/// Karte ohne Schatten, mit optionalem Rand. Material, damit ListTiles darin funktionieren.
class PlainCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? border;
  const PlainCard(
      {super.key, required this.child, this.color = Colors.white, this.border});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
          child: child,
        ),
      );
}

/// Schmale Leiste unter der AppBar: eigene Münzen und die des Partners.
class CoinBar extends StatelessWidget implements PreferredSizeWidget {
  final int mine, theirs;
  final VoidCallback onTap;
  const CoinBar(
      {super.key,
      required this.mine,
      required this.theirs,
      required this.onTap});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  Widget _pill(String name, String label, int value) => Expanded(
        child: Material(
          color: personColor(name),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFD45E), size: 18),
                  const SizedBox(width: 6),
                  Text('$label · $value',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(children: [
          _pill(me, 'Du', mine),
          const SizedBox(width: 8),
          _pill(partner, partner, theirs),
        ]),
      );
}

/// Übersicht pro Person (Aufgaben, die die Person bekommen hat).
void showStats(
    BuildContext context, List<Task> tasks, int Function(String) balance) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final n in [me, partner])
          _StatsCard(name: n, tasks: tasks, coins: balance(n)),
      ]),
    ),
  );
}

class _StatsCard extends StatelessWidget {
  final String name;
  final List<Task> tasks;
  final int coins;
  const _StatsCard(
      {required this.name, required this.tasks, required this.coins});

  @override
  Widget build(BuildContext context) {
    final mine = tasks.where((t) => t.assignee == name);
    int count(List<String> s) => mine.where((t) => s.contains(t.status)).length;
    final color = personColor(name);

    Widget stat(String label, int n) => Expanded(
          child: Column(children: [
            Text('$n',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: color)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ]),
        );

    return PlainCard(
      color: personLight(name),
      border: color.withAlpha(110),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text(name == me ? '$name (du)' : name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.monetization_on, color: coinGold, size: 20),
            const SizedBox(width: 4),
            Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            stat('Aktiv', count(['accepted', 'review'])),
            stat('Offen', count(['pending', 'countered'])),
            stat('Erledigt', count(['done'])),
          ]),
        ]),
      ),
    );
  }
}

class HoursDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const HoursDropdown(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        value: hourOptions.contains(value) ? value : null,
        decoration: const InputDecoration(
            labelText: 'Zeit dafür', filled: true, fillColor: Colors.white),
        items: [
          for (final h in hourOptions)
            DropdownMenuItem(value: h, child: Text(hoursLabel(h)))
        ],
        onChanged: (v) => onChanged(v ?? value),
      );
}

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
