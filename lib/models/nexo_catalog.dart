import 'package:flutter/material.dart';

enum NexoRarity { common, rare, epic, legendary, exclusive }

extension NexoRarityX on NexoRarity {
  String get label {
    switch (this) {
      case NexoRarity.common: return 'Common';
      case NexoRarity.rare: return 'Rare';
      case NexoRarity.epic: return 'Epic';
      case NexoRarity.legendary: return 'Legendary';
      case NexoRarity.exclusive: return 'NEXO Exclusive';
    }
  }

  Color get color {
    switch (this) {
      case NexoRarity.common: return Colors.blueGrey;
      case NexoRarity.rare: return Colors.lightBlueAccent;
      case NexoRarity.epic: return Colors.deepPurpleAccent;
      case NexoRarity.legendary: return Colors.orangeAccent;
      case NexoRarity.exclusive: return Colors.pinkAccent;
    }
  }
}

class NexoGift {
  final String id;
  final String name;
  final NexoRarity rarity;
  final int gems;
  final String image;
  final String tagline;
  final bool tradeable;

  const NexoGift({
    required this.id,
    required this.name,
    required this.rarity,
    required this.gems,
    required this.image,
    required this.tagline,
    this.tradeable = true,
  });
}

const nexoGifts = <NexoGift>[
  NexoGift(id: 'neon-heart', name: 'Neon Heart', rarity: NexoRarity.common, gems: 15, image: 'neon_heart.png', tagline: 'نبضة نيون لطيفة للشات'),
  NexoGift(id: 'shadow-flame', name: 'Shadow Flame', rarity: NexoRarity.rare, gems: 80, image: 'shadow_flame.png', tagline: 'لهب مظلم للغرف الليلية'),
  NexoGift(id: 'name-glow', name: 'Name Glow', rarity: NexoRarity.rare, gems: 120, image: 'name_glow_ticket.png', tagline: 'وهج مميز للاسم'),
  NexoGift(id: 'diamond-glow', name: 'Diamond Glow', rarity: NexoRarity.epic, gems: 220, image: 'diamond_glow.png', tagline: 'لمعة ماسية عند الإرسال'),
  NexoGift(id: 'galaxy-aura', name: 'Galaxy Aura', rarity: NexoRarity.epic, gems: 280, image: 'galaxy_aura.png', tagline: 'هالة مجرية حول الرسالة'),
  NexoGift(id: 'rainbow-aura', name: 'Rainbow Aura', rarity: NexoRarity.epic, gems: 350, image: 'rainbow_ticket.png', tagline: 'أثر طيفي مميز'),
  NexoGift(id: 'fire-wings', name: 'Fire Wings', rarity: NexoRarity.legendary, gems: 650, image: 'fire_wings.png', tagline: 'دخول ناري قوي'),
  NexoGift(id: 'crown-shine', name: 'Crown Shine', rarity: NexoRarity.legendary, gems: 900, image: 'crown_shine.png', tagline: 'تاج لامع للغرف'),
  NexoGift(id: 'vip-emblem', name: 'VIP Emblem', rarity: NexoRarity.exclusive, gems: 1800, image: 'vip_emblem.png', tagline: 'شارة NEXO حصرية', tradeable: false),
];

const nexoFrames = <Map<String, dynamic>>[
  {'id': 'frame-cyan', 'name': 'Cyan Orbit', 'rarity': NexoRarity.rare, 'icon': Icons.blur_circular_rounded},
  {'id': 'frame-violet', 'name': 'Violet Pulse', 'rarity': NexoRarity.epic, 'icon': Icons.auto_awesome_rounded},
  {'id': 'frame-gold', 'name': 'Royal Gold', 'rarity': NexoRarity.legendary, 'icon': Icons.workspace_premium_rounded},
  {'id': 'frame-neon', 'name': 'Neon Ring', 'rarity': NexoRarity.exclusive, 'icon': Icons.ring_volume_rounded},
];

const nexoAssets = <Map<String, dynamic>>[
  {'id': 'asset-galaxy', 'name': 'Galaxy Aura Asset', 'image': 'galaxy_aura.png', 'rarity': NexoRarity.epic},
  {'id': 'asset-fire', 'name': 'Fire Wings Asset', 'image': 'fire_wings.png', 'rarity': NexoRarity.legendary},
  {'id': 'asset-diamond', 'name': 'Diamond Glow Asset', 'image': 'diamond_glow.png', 'rarity': NexoRarity.epic},
  {'id': 'asset-crown', 'name': 'Crown Shine Asset', 'image': 'crown_shine.png', 'rarity': NexoRarity.legendary},
];

NexoGift? giftById(String id) {
  for (final gift in nexoGifts) {
    if (gift.id == id) return gift;
  }
  return null;
}