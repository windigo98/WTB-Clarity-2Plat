import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final free = shopItems.where((item) => !item.premium).toList();
    final premium = shopItems.where((item) => item.premium && !item.realMoney).toList();
    final later = shopItems.where((item) => item.realMoney).toList();
    return ClarityPage(
      title: 'Shop',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${state.data.profile.clarity} Clarity', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Free looks come with every traveler. Premium items cost Clarity. Real-money pouches are reserved and cannot be bought yet.'),
          const SizedBox(height: 8),
          Text('Lives ${state.data.profile.lives}/${LifeClock.maxLives} · Freezes ${state.data.profile.freezes}'),
          const _Header('Free'),
          for (final item in free) _Tile(item: item),
          const _Header('Premium'),
          for (final item in premium) _Tile(item: item),
          const _Header('Real-money later'),
          for (final item in later) _Tile(item: item),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final owned = state.owns(item.id);
    final equipped = switch (item.category) {
      'avatar' => state.data.profile.avatarId == item.id,
      'theme' => state.data.profile.themeId == item.id,
      'card' => state.data.profile.cardBackId == item.id,
      'board' => state.data.profile.boardId == item.id,
      _ => false,
    };
    final count = item.category == 'booster' ? state.boosterCount(item.id) : null;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(item.blurb),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(item.realMoney ? 'SKU ${item.sku}' : item.cost == 0 ? 'Included' : '${item.cost} Clarity'),
              if (count != null) Text('  ·  held $count'),
              const Spacer(),
              if (item.realMoney)
                OutlinedButton(
                  onPressed: () async {
                    final result = await state.startRealMoney(item.sku!);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                  },
                  child: const Text('Not for sale'),
                )
              else if (item.repeatable)
                FilledButton(
                  onPressed: () {
                    final message = state.buyWithPoints(item.id);
                    if (message != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                  child: const Text('Buy'),
                )
              else if (!owned)
                FilledButton(
                  onPressed: () {
                    final message = state.buyWithPoints(item.id);
                    if (message != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                  child: const Text('Unlock'),
                )
              else
                FilledButton(
                  onPressed: equipped ? null : () => state.equip(item.id),
                  child: Text(equipped ? 'Equipped' : 'Equip'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
