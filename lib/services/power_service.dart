import 'package:flutter/foundation.dart';
import '../models/power_models.dart';

/// Power Engine — client state + mock server rules.
/// Activate starts timer; deactivate freezes remaining duration.
/// Trade must not increase global supply (enforced when wired to API).
class PowerService extends ChangeNotifier {
  static const Duration defaultTimedDuration = Duration(days: 3);

  final String playerId;
  final List<PowerDefinition> _definitions = [];
  final Map<String, PowerInstance> _owned = {};
  final List<RarityConfig> _rarities = List.from(defaultRarityTable);
  final Map<String, PowerLoadout> _loadouts = {};

  bool _loading = false;
  String? _error;

  PowerService({this.playerId = '1'}) {
    _seed();
  }

  bool get isLoading => _loading;
  String? get error => _error;
  List<PowerDefinition> get definitions => List.unmodifiable(_definitions);
  List<PowerInstance> get ownedPowers => _owned.values.toList(growable: false);
  List<RarityConfig> get rarityTable => List.unmodifiable(_rarities);
  List<PowerLoadout> get loadouts => _loadouts.values.toList();

  int get collectionScore {
    var score = 0;
    for (final inst in _owned.values) {
      final def = definitionById(inst.definitionId);
      if (def == null) continue;
      final r = _rarities.cast<RarityConfig?>().firstWhere(
            (x) => x?.rarityId == def.rarityId,
            orElse: () => null,
          );
      score += r?.collectorScore ?? 0;
    }
    return score;
  }

  Set<String> get ownedDefinitionIds =>
      _owned.values.map((e) => e.definitionId).toSet();

  List<PowerDefinition> get missingDefinitions =>
      _definitions.where((d) => !ownedDefinitionIds.contains(d.id)).toList();

  PowerDefinition? definitionById(String id) {
    try {
      return _definitions.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void _seed() {
    _definitions.addAll([
      const PowerDefinition(
        id: 'power_glow_frame',
        name: 'إطار التوهج',
        description: 'توهج خفيف حول الملف الشخصي',
        categoryId: PowerCategoryId.profile,
        rarityId: PowerRarityId.common,
        isTradeable: true,
        isPermanent: true,
      ),
      const PowerDefinition(
        id: 'power_chat_spark',
        name: 'شرارة الشات',
        description: 'تأثير رسائل مميز',
        categoryId: PowerCategoryId.chat,
        rarityId: PowerRarityId.uncommon,
        isTradeable: true,
        isPermanent: true,
      ),
      const PowerDefinition(
        id: 'power_vip_aura',
        name: 'هالة VIP',
        description: 'هالة غرفة مؤقتة',
        categoryId: PowerCategoryId.room,
        rarityId: PowerRarityId.rare,
        isTradeable: true,
        isPermanent: false,
        maxSupply: 5000,
        globalSupply: 120,
      ),
      const PowerDefinition(
        id: 'power_fire_wings',
        name: 'أجنحة النار',
        description: 'تأثير أفاتار نادر',
        categoryId: PowerCategoryId.avatar,
        rarityId: PowerRarityId.epic,
        isTradeable: true,
        isPermanent: false,
        maxSupply: 1000,
        globalSupply: 40,
      ),
      const PowerDefinition(
        id: 'power_mythic_crown',
        name: 'التاج الأسطوري',
        description: 'تاج جامع نادر جداً',
        categoryId: PowerCategoryId.collector,
        rarityId: PowerRarityId.mythic,
        isTradeable: false,
        isPermanent: true,
        maxSupply: 50,
        globalSupply: 12,
      ),
    ]);

    // Seed one owned power for the current user
    final first = _definitions.first;
    final id = 'inst_${first.id}_$playerId';
    _owned[id] = PowerInstance(
      instanceId: id,
      definitionId: first.id,
      ownerId: playerId,
      state: PowerStateId.owned,
      isTradeable: first.isTradeable,
      createdAt: DateTime.now().toUtc(),
      remainingDurationMs:
          first.isPermanent ? null : defaultTimedDuration.inMilliseconds,
    );

    // Second owned timed power
    final vip = _definitions.firstWhere((d) => d.id == 'power_vip_aura');
    final id2 = 'inst_${vip.id}_$playerId';
    _owned[id2] = PowerInstance(
      instanceId: id2,
      definitionId: vip.id,
      ownerId: playerId,
      state: PowerStateId.owned,
      isTradeable: vip.isTradeable,
      createdAt: DateTime.now().toUtc(),
      remainingDurationMs: defaultTimedDuration.inMilliseconds,
    );
  }

  /// Duration starts on first activation (server rule).
  Future<PowerInstance> activate(String instanceId) async {
    final power = _owned[instanceId];
    if (power == null) throw StateError('POWER_NOT_FOUND');
    if (!power.canActivate) throw StateError('POWER_NOT_ACTIVATABLE');

    final def = definitionById(power.definitionId);
    var remaining = power.remainingDurationMs;
    if (remaining == null && def != null && !def.isPermanent) {
      remaining = defaultTimedDuration.inMilliseconds;
    }

    final updated = power.copyWith(
      state: PowerStateId.active,
      remainingDurationMs: remaining,
      activatedAt: DateTime.now().toUtc(),
    );
    _owned[instanceId] = updated;
    notifyListeners();
    return updated;
  }

  /// Deactivate freezes remaining time — does not reset.
  Future<PowerInstance> deactivate(String instanceId) async {
    final power = _owned[instanceId];
    if (power == null) throw StateError('POWER_NOT_FOUND');

    final updated = power.copyWith(state: PowerStateId.inactive);
    _owned[instanceId] = updated;
    notifyListeners();
    return updated;
  }

  Future<PowerLoadout> saveLoadout(String name, List<String> instanceIds) async {
    final id = 'loadout_${DateTime.now().millisecondsSinceEpoch}';
    final loadout = PowerLoadout(id: id, name: name, powerInstanceIds: instanceIds);
    _loadouts[id] = loadout;
    notifyListeners();
    return loadout;
  }

  Future<void> applyLoadout(String loadoutId) async {
    final loadout = _loadouts[loadoutId];
    if (loadout == null) throw StateError('LOADOUT_NOT_FOUND');
    for (final id in loadout.powerInstanceIds) {
      if (_owned.containsKey(id)) {
        await activate(id);
      }
    }
  }

  /// Demo grant only — production grants come from server (missions/admin).
  Future<PowerInstance> debugGrant(String definitionId) async {
    final def = definitionById(definitionId);
    if (def == null) throw StateError('DEFINITION_NOT_FOUND');
    if (def.maxSupply != null &&
        def.globalSupply != null &&
        def.globalSupply! >= def.maxSupply!) {
      throw StateError('MAX_SUPPLY_REACHED');
    }
    final id = 'inst_${definitionId}_${DateTime.now().millisecondsSinceEpoch}';
    final inst = PowerInstance(
      instanceId: id,
      definitionId: definitionId,
      ownerId: playerId,
      state: PowerStateId.owned,
      isTradeable: def.isTradeable,
      createdAt: DateTime.now().toUtc(),
      remainingDurationMs:
          def.isPermanent ? null : defaultTimedDuration.inMilliseconds,
    );
    _owned[id] = inst;
    notifyListeners();
    return inst;
  }
}
