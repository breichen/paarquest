import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'push.dart';
import 'web_push.dart';

/// Nur im Browser: Hinweis zum Aktivieren der Benachrichtigungen, solange
/// noch nicht danach gefragt wurde. Die Abfrage muss durch einen Tipp
/// ausgelöst werden, darum ein eigener Button.
class WebPushCard extends StatefulWidget {
  const WebPushCard({super.key});

  @override
  State<WebPushCard> createState() => _WebPushCardState();
}

class _WebPushCardState extends State<WebPushCard> {
  bool visible = false, busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _check();
  }

  Future<void> _check() async {
    final ok = await webPushSupported();
    if (mounted) setState(() => visible = ok && webPushPermission() == 'default');
  }

  Future<void> _enable() async {
    setState(() => busy = true);
    String msg;
    try {
      final token = await webPushEnable();
      if (token.isEmpty) {
        msg = 'Benachrichtigungen wurden nicht erlaubt.';
      } else {
        await Push.saveToken(token, platform: 'web');
        msg = 'Benachrichtigungen sind aktiv.';
      }
    } catch (e) {
      msg = 'Aktivieren fehlgeschlagen: $e';
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      visible = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.notifications_active_outlined, color: cs.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Benachrichtigungen aktivieren, damit du neue Aufgaben und Käufe '
                'auch bei geschlossener App mitbekommst.',
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
            ),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 4, children: [
              TextButton(
                onPressed: busy ? null : () => setState(() => visible = false),
                child: const Text('Später'),
              ),
              FilledButton(
                onPressed: busy ? null : _enable,
                child: busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Aktivieren'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
