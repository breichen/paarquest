import 'package:flutter/material.dart';
import 'config.dart';
import 'models.dart';
import 'task_templates.dart';
import 'widgets.dart';

class SendPage extends StatefulWidget {
  final TemplateStore store;
  final Future<bool> Function(
      String title, String description, String category, int coins, int hours) onSend;
  const SendPage({super.key, required this.store, required this.onSend});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  String category = categories.first;
  final title = TextEditingController();
  final description = TextEditingController();
  final coins = TextEditingController(text: '10');
  int hours = 48;
  bool sending = false;

  void snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> pickTemplate() async {
    final t = await Navigator.push<Tpl>(
      context,
      MaterialPageRoute(builder: (_) => TemplatePicker(store: widget.store)),
    );
    if (t == null) return;
    setState(() {
      category = t.category;
      title.text = t.title;
      description.text = t.description;
      coins.text = '${t.coins}';
      hours = t.hours;
    });
  }

  Future<void> submit() async {
    final c = int.tryParse(coins.text.trim());
    final ti = title.text.trim();
    if (ti.isEmpty || c == null || c < 0) {
      snack('Bitte Titel und Münzen prüfen');
      return;
    }
    final candidate = Tpl(ti, category, c, hours, description.text.trim());

    setState(() => sending = true);
    final ok = await widget.onSend(
        candidate.title, candidate.description, candidate.category, candidate.coins, candidate.hours);
    if (!mounted) return;
    setState(() => sending = false);
    if (!ok) return; // Fehlermeldung zeigt die Home-Seite, Eingaben bleiben erhalten

    title.clear();
    description.clear();

    final existing = widget.store.find(ti);
    if (existing != null && existing.same(candidate)) return;
    final replace = existing != null;

    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aufgabe speichern?'),
        content: Text(replace
            ? 'In deiner Liste gibt es schon „$ti", aber mit anderen Angaben. Soll die gespeicherte Version ersetzt werden?'
            : '„$ti" ist noch nicht in deiner Liste. Auf diesem Gerät speichern?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Nein')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(replace ? 'Ersetzen' : 'Speichern')),
        ],
      ),
    );
    if (save == true) {
      await widget.store.save(candidate);
      if (mounted) snack('In deiner Liste gespeichert');
    }
  }

  @override
  Widget build(BuildContext context) {
    const fill = InputDecoration(filled: true, fillColor: Colors.white);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Aufgabe für $partner', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: pickTemplate,
          icon: const Icon(Icons.list_alt),
          label: const Text('Aus Liste wählen'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: category,
          decoration: fill.copyWith(labelText: 'Kategorie'),
          items: [
            for (final c in categories)
              DropdownMenuItem(
                value: c,
                child: Row(children: [
                  Icon(categoryIcons[c], size: 18),
                  const SizedBox(width: 8),
                  Text(c),
                ]),
              ),
          ],
          onChanged: (v) => setState(() => category = v ?? category),
        ),
        const SizedBox(height: 10),
        TextField(controller: title, decoration: fill.copyWith(labelText: 'Titel')),
        const SizedBox(height: 10),
        TextField(
          controller: description,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: fill.copyWith(labelText: 'Beschreibung (optional)'),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: coins,
              keyboardType: TextInputType.number,
              decoration: fill.copyWith(labelText: 'Münzen'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: HoursDropdown(value: hours, onChanged: (v) => setState(() => hours = v))),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: sending ? null : submit,
          icon: sending
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(sending ? 'Wird gesendet …' : 'An $partner schicken'),
        ),
      ],
    );
  }
}

/// Vollbild-Auswahl mit scrollbarer Liste, nach Münzen aufsteigend sortiert.
class TemplatePicker extends StatefulWidget {
  final TemplateStore store;
  const TemplatePicker({super.key, required this.store});
  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  String? category; // null = alle

  Future<void> manage(Tpl t) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Ändern'),
            onTap: () => Navigator.pop(c, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Löschen'),
            onTap: () => Navigator.pop(c, 'delete'),
          ),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final nu = await showDialog<Tpl>(
        context: context,
        builder: (_) => TemplateEditDialog(tpl: t),
      );
      if (nu != null) await widget.store.update(t, nu);
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Aufgabe löschen?'),
          content: Text('„${t.title}“ verschwindet nur auf diesem Gerät aus deiner Liste.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Löschen')),
          ],
        ),
      );
      if (ok == true) await widget.store.remove(t);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Aufgabe wählen'),
          actions: [
            ListenableBuilder(
              listenable: widget.store,
              builder: (_, __) => widget.store.hasHidden
                  ? IconButton(
                      tooltip: 'Gelöschte Standard-Aufgaben wiederherstellen',
                      icon: const Icon(Icons.restore),
                      onPressed: widget.store.restoreHidden,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final list = widget.store.forCategory(category);
            return Column(children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Alle'),
                        selected: category == null,
                        onSelected: (_) => setState(() => category = null),
                      ),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(categoryIcons[c], size: 16),
                          label: Text(c),
                          selected: category == c,
                          onSelected: (_) => setState(() => category = c),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text('Lange drücken zum Ändern oder Löschen. Gilt nur für dieses Gerät.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final saved = widget.store.isSaved(t);
                    return ListTile(
                      leading: Icon(categoryIcons[t.category] ?? Icons.star),
                      title: Row(children: [
                        Flexible(child: Text(t.title)),
                        if (saved) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.bookmark, size: 14),
                        ],
                      ]),
                      subtitle: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.monetization_on, color: coinGold, size: 16),
                            const SizedBox(width: 2),
                            Text('${t.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                          Text(hoursLabel(t.hours), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, t),
                      onLongPress: () => manage(t),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      );
}

class TemplateEditDialog extends StatefulWidget {
  final Tpl tpl;
  const TemplateEditDialog({super.key, required this.tpl});
  @override
  State<TemplateEditDialog> createState() => _TemplateEditDialogState();
}

class _TemplateEditDialogState extends State<TemplateEditDialog> {
  late String category = widget.tpl.category;
  late final title = TextEditingController(text: widget.tpl.title);
  late final description = TextEditingController(text: widget.tpl.description);
  late final coins = TextEditingController(text: '${widget.tpl.coins}');
  late int hours = widget.tpl.hours;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Aufgabe ändern'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: categories.contains(category) ? category : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => category = v ?? category),
            ),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Titel')),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
            ),
            TextField(
              controller: coins,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Münzen'),
            ),
            const SizedBox(height: 8),
            HoursDropdown(value: hours, onChanged: (v) => setState(() => hours = v)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final c = int.tryParse(coins.text.trim());
              final t = title.text.trim();
              if (t.isEmpty || c == null || c < 0) return;
              Navigator.pop(context, Tpl(t, category, c, hours, description.text.trim()));
            },
            child: const Text('Speichern'),
          ),
        ],
      );
}
