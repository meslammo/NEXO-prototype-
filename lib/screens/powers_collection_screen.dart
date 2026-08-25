import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/power_models.dart';
import '../services/power_service.dart';
import '../theme/nexo_theme.dart';

/// شاشة كولكشن الـ Powers — تفعيل / إيقاف
class PowersCollectionScreen extends StatelessWidget {
  const PowersCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.surface,
      appBar: AppBar(
        backgroundColor: NexoColors.surface,
        title: const Text('كولكشن الـ Powers', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<PowerService>(
            builder: (_, powers, __) => Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Center(
                child: Text(
                  'النقاط ${powers.collectionScore}',
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PowerService>(
        builder: (context, powers, _) {
          final owned = powers.ownedPowers;
          final missing = powers.missingDefinitions;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'المملوك ${owned.length} · الناقص ${missing.length}',
                style: const TextStyle(color: NexoColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                'المملوك',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (owned.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد Powers بعد', style: TextStyle(color: Colors.white54)),
                ),
              ...owned.map((p) => _OwnedTile(instance: p)),
              const SizedBox(height: 24),
              const Text(
                'الناقص من الكولكشن',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...missing.map((d) => _MissingTile(definition: d)),
            ],
          );
        },
      ),
    );
  }
}

class _OwnedTile extends StatelessWidget {
  final PowerInstance instance;
  const _OwnedTile({required this.instance});

  @override
  Widget build(BuildContext context) {
    final powers = context.read<PowerService>();
    final def = powers.definitionById(instance.definitionId);
    final name = def?.name ?? instance.definitionId;
    final rarity = def?.rarityId ?? '?';
    final active = instance.isActive;
    final mins = instance.remainingDurationMs != null
        ? (instance.remainingDurationMs! / 1000 / 60).round()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rarityColor(rarity).withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _rarityColor(rarity),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${_stateLabel(instance.state)} · $rarity${mins != null ? ' · متبقي $mins د' : ''}',
          style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
        ),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: active ? Colors.orangeAccent : const Color(0xFF7B5CFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () async {
            try {
              if (active) {
                await powers.deactivate(instance.instanceId);
              } else {
                await powers.activate(instance.instanceId);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            }
          },
          child: Text(active ? 'إيقاف' : 'تفعيل'),
        ),
      ),
    );
  }

  String _stateLabel(String state) {
    switch (state) {
      case PowerStateId.active:
      case PowerStateId.equipped:
        return 'مفعّل';
      case PowerStateId.inactive:
        return 'متوقف';
      case PowerStateId.owned:
        return 'مملوك';
      case PowerStateId.expired:
        return 'منتهي';
      default:
        return state;
    }
  }
}

class _MissingTile extends StatelessWidget {
  final PowerDefinition definition;
  const _MissingTile({required this.definition});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _rarityColor(definition.rarityId).withOpacity(0.25),
        child: Icon(Icons.lock_outline, color: _rarityColor(definition.rarityId), size: 18),
      ),
      title: Text(definition.name, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(
        '${definition.rarityId} · ${definition.categoryId}',
        style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

Color _rarityColor(String rarity) {
  switch (rarity) {
    case PowerRarityId.common:
      return Colors.grey;
    case PowerRarityId.uncommon:
      return Colors.green;
    case PowerRarityId.rare:
      return Colors.blue;
    case PowerRarityId.epic:
      return Colors.purple;
    case PowerRarityId.legendary:
      return Colors.orange;
    case PowerRarityId.mythic:
      return Colors.redAccent;
    case PowerRarityId.limited:
      return Colors.teal;
    default:
      return Colors.blueGrey;
  }
}
