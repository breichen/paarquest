import 'package:flutter/material.dart';
import 'config.dart';
import 'models.dart';
import 'widgets.dart';

class Reward {
  final String title;
  final int cost;
  final IconData icon;
  const Reward(this.title, this.cost, this.icon);
}

// Aus Sicht des Käufers formuliert ("mich" = Käufer, "du" = Partner).

const rewards = <Reward>[
  // 10 Münzen
  Reward('Du übernimmst den Abwasch', 10, Icons.clean_hands),
  Reward('Zwei Kugeln Eis für mich', 10, Icons.icecream),
  Reward('Ich wähle den Film für unseren Filmabend', 10, Icons.movie),

  // 20 Münzen
  Reward('Ein Cocktail für mich', 20, Icons.local_bar),
  Reward('Frühstück ans Bett für mich', 20, Icons.free_breakfast),
  Reward('Ich wähle den ganzen Tag die Musik', 10, Icons.movie),

  // 30 Münzen
  Reward('30 Minuten Massage für mich', 30, Icons.spa),
  Reward('Ich wähle eine Sexstellung', 30, Icons.favorite),

  // 40 Münzen
  Reward('Du kochst für mich', 40, Icons.soup_kitchen),
  Reward('Oralsex für mich', 40, Icons.local_fire_department),

  // 50 Münzen
  Reward('Ein Kinobesuch für uns', 50, Icons.theaters),

  // 80 Münzen
  Reward('Wir gehen essen – ich wähle das Lokal', 80, Icons.restaurant_menu),
  Reward('Ich bestimme unseren Abend', 80, Icons.nightlife),
  Reward('Du erfüllst mir einen Sexwunsch', 80, Icons.whatshot),

  // 150 Münzen
  Reward('Ich bestimme unseren Tag', 150, Icons.wb_sunny),
];

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
