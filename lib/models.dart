import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

SupabaseClient get db => Supabase.instance.client;

// Status: pending (wartet auf Empfänger), countered (wartet auf Absender),
// accepted, review (Erledigung angefragt), done, declined, discarded, cancelled
class Task {
  final String id, title, description, category, creator, assignee, status;
  final String? cancelledBy;
  final int coins, hours;
  final DateTime? deadline;

  Task.fromMap(Map<String, dynamic> m)
      : id = m['id'],
        title = m['title'],
        description = (m['description'] ?? '') as String,
        category = m['category'],
        creator = m['creator'],
        assignee = m['assignee'],
        status = m['status'],
        cancelledBy = m['cancelled_by'],
        coins = m['coins'],
        hours = m['hours'],
        deadline =
            m['deadline'] == null ? null : DateTime.parse(m['deadline']).toLocal();

  bool get needsMyAction =>
      (status == 'pending' && assignee == me) ||
      (status == 'countered' && creator == me) ||
      (status == 'review' && creator == me);

  bool get overdue =>
      status == 'accepted' && deadline != null && deadline!.isBefore(DateTime.now());
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

String hoursLabel(int h) => h % 24 == 0 ? '${h ~/ 24} Tag${h == 24 ? '' : 'e'}' : '$h Std';

String _span(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} T ${d.inHours % 24} Std';
  if (d.inHours >= 1) return '${d.inHours} Std ${d.inMinutes % 60} Min';
  return '${d.inMinutes} Min';
}

String timeLeft(DateTime deadline) {
  final d = deadline.difference(DateTime.now());
  return d.isNegative ? 'Überfällig seit ${_span(-d)}' : 'Noch ${_span(d)}';
}

/// Meldung für eine Änderung an einer Aufgabe: (Empfänger, Titel, Text).
/// Spiegelt die Logik der Edge Function (nur auf iOS ohne Push genutzt).
(String, String, String)? taskMessage(Task? o, Task r) {
  if (o == null) {
    return (r.assignee, 'Neue Aufgabe von ${r.creator}',
        '${r.title} (${r.coins} Münzen, ${hoursLabel(r.hours)})');
  }
  if (o.status == r.status) return null;
  switch (r.status) {
    case 'countered':
      return (r.creator, '${r.assignee} macht einen Vorschlag',
          '${r.title}: ${r.coins} Münzen, ${hoursLabel(r.hours)}');
    case 'accepted':
      if (o.status == 'review') {
        return (r.assignee, '${r.creator} hat die Erledigung noch nicht bestätigt', r.title);
      }
      return o.status == 'pending'
          ? (r.creator, '${r.assignee} hat angenommen', r.title)
          : (r.assignee, '${r.creator} akzeptiert deinen Vorschlag', r.title);
    case 'review':
      return (r.creator, '${r.assignee} meldet Erledigung', r.title);
    case 'declined':
      return (r.creator, '${r.assignee} hat abgelehnt', r.title);
    case 'discarded':
      return (r.assignee, '${r.creator} hat den Vorschlag verworfen', r.title);
    case 'done':
      return (r.assignee, '${r.creator} hat bestätigt', '${r.title} (+${r.coins} Münzen)');
    case 'cancelled':
      final by = r.cancelledBy ?? r.assignee;
      return (otherPerson(by), '$by hat abgebrochen', r.title);
  }
  return null;
}

(String, String, String)? purchaseMessage(Purchase? o, Purchase r) {
  if (o == null) {
    return (otherPerson(r.buyer), '${r.buyer} hat etwas eingelöst',
        '${r.reward} (${r.cost} Münzen)');
  }
  if (o.status != r.status && r.status == 'fulfilled') {
    return (r.buyer, '${otherPerson(r.buyer)} hat erfüllt', r.reward);
  }
  return null;
}
