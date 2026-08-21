import 'package:flutter/foundation.dart';

enum ItemRarity { common, rare, epic, legendary }

@immutable
class ItemModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final ItemRarity rarity;
  final int basePrice;
  final int quantity;
  final String type;
  final Map<String, dynamic> properties;

  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.basePrice,
    this.quantity = 1,
    required this.type,
    this.properties = const {},
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final rarityValue = json['rarity']?.toString();
    return ItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: ItemRarity.values.firstWhere(
        (value) => value.name == rarityValue,
        orElse: () => ItemRarity.common,
      ),
      basePrice: (json['basePrice'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      type: json['type'] as String,
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'rarity': rarity.name,
        'basePrice': basePrice,
        'quantity': quantity,
        'type': type,
        'properties': properties,
      };
}
