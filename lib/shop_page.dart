import 'package:flutter/material.dart';
import 'config.dart';
import 'models.dart';
import 'rewards.dart';
import 'widgets.dart';

export 'rewards.dart';

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
    final sorted = [...rewards]..sort((a, b) => a.cost.compareTo(b.cost));
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
            PlainCard(
              color: personLight(partner),
              border: personColor(partner).withAlpha(110),
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
        for (final r in sorted)
          PlainCard(
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
