import 'package:json_annotation/json_annotation.dart';

part 'item_model.g.dart';

enum ItemRarity { common, rare, epic, legendary }

@JsonSerializable()
class ItemModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final ItemRarity rarity;
  final int basePrice;
  final int quantity;
  final String type; // 'cosmetic', 'tool', 'resource', 'material'
  final Map<String, dynamic> properties;

  ItemModel({
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

  factory ItemModel.fromJson(Map<String, dynamic> json) => _$ItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$ItemModelToJson(this);
}
