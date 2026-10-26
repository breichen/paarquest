// Belohnungen für PaarQuest. Diese Datei wird auch von der App "Fantasien"
// verwendet (dort per tool/sync_rewards.ps1 hineinkopiert). Hier ändern, nicht dort.
import 'package:flutter/material.dart';

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
