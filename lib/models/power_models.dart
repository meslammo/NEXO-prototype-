/// NEXO Power Engine models (data-driven category/rarity ids).
/// Server is authority; these are client models for UI.

class PowerStateId {
  static const owned = 'owned';
  static const active = 'active';
  static const inactive = 'inactive';
  static const equipped = 'equipped';
  static const locked = 'locked';
  static const expired = 'expired';
  static const archived = 'archived';
}

class PowerRarityId {
  static const common = 'common';
  static const uncommon = 'uncommon';
  static const rare = 'rare';
  static const epic = 'epic';
  static const legendary = 'legendary';
  static const mythic = 'mythic';
  static const limited = 'limited';
}

class PowerCategoryId {
  static const social = 'social';
  static const chat = 'chat';
  static const profile = 'profile';
  static const avatar = 'avatar';
  static const room = 'room';
  static const animation = 'animation';
  static const emoji = 'emoji';
  static const vip = 'vip';
  static const event = 'event';
  static const utility = 'utility';
  static const collector = 'collector';
  static const seasonal = 'seasonal';
}

class RarityConfig {
  final String rarityId;
  final double dropRate;
  final int? maxSupply;
  final int collectorScore;

  const RarityConfig({
    required this.rarityId,
    required this.dropRate,
    this.maxSupply,
    required this.collectorScore,
  });
}

const List<RarityConfig> defaultRarityTable = [
  RarityConfig(rarityId: PowerRarityId.common, dropRate: 0.50, collectorScore: 5),
  RarityConfig(rarityId: PowerRarityId.uncommon, dropRate: 0.25, collectorScore: 15),
  RarityConfig(rarityId: PowerRarityId.rare, dropRate: 0.12, maxSupply: 5000, collectorScore: 40),
  RarityConfig(rarityId: PowerRarityId.epic, dropRate: 0.07, maxSupply: 1000, collectorScore: 100),
  RarityConfig(rarityId: PowerRarityId.legendary, dropRate: 0.04, maxSupply: 250, collectorScore: 250),
  RarityConfig(rarityId: PowerRarityId.mythic, dropRate: 0.015, maxSupply: 50, collectorScore: 600),
  RarityConfig(rarityId: PowerRarityId.limited, dropRate: 0.005, collectorScore: 300),
];

/// Catalog template (admin-created).
class PowerDefinition {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String previewUrl;
  final String categoryId;
  final String rarityId;
  final int version;
  final bool isTradeable;
  final bool isPermanent;
  final int? maxSupply;
  final int? globalSupply;

  const PowerDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl = '',
    this.previewUrl = '',
    required this.categoryId,
    required this.rarityId,
    this.version = 1,
    this.isTradeable = true,
    this.isPermanent = true,
    this.maxSupply,
    this.globalSupply,
  });
}

/// Owned instance — trade transfers this; never mints supply.
class PowerInstance {
  final String instanceId;
  final String definitionId;
  final String ownerId;
  final int quantity;
  final String state;
  final bool isTradeable;
  final int? remainingDurationMs;
  final DateTime createdAt;
  final DateTime? activatedAt;

  const PowerInstance({
    required this.instanceId,
    required this.definitionId,
    required this.ownerId,
    this.quantity = 1,
    this.state = PowerStateId.owned,
    this.isTradeable = true,
    this.remainingDurationMs,
    required this.createdAt,
    this.activatedAt,
  });

  bool get isActive =>
      state == PowerStateId.active || state == PowerStateId.equipped;

  bool get canActivate =>
      state != PowerStateId.locked &&
      state != PowerStateId.expired &&
      state != PowerStateId.archived;

  PowerInstance copyWith({
    String? state,
    int? remainingDurationMs,
    DateTime? activatedAt,
    String? ownerId,
  }) {
    return PowerInstance(
      instanceId: instanceId,
      definitionId: definitionId,
      ownerId: ownerId ?? this.ownerId,
      quantity: quantity,
      state: state ?? this.state,
      isTradeable: isTradeable,
      remainingDurationMs: remainingDurationMs ?? this.remainingDurationMs,
      createdAt: createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}

class PowerLoadout {
  final String id;
  final String name;
  final List<String> powerInstanceIds;

  const PowerLoadout({
    required this.id,
    required this.name,
    required this.powerInstanceIds,
  });
}
