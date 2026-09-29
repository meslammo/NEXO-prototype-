import 'package:flutter/foundation.dart';

enum FrameRarity { common, uncommon, rare, epic, legendary, mythic }

extension FrameRarityX on FrameRarity {
  String get label => switch (this) {
    FrameRarity.common => 'Common',
    FrameRarity.uncommon => 'Uncommon',
    FrameRarity.rare => 'Rare',
    FrameRarity.epic => 'Epic',
    FrameRarity.legendary => 'Legendary',
    FrameRarity.mythic => 'Mythic',
  };
}

@immutable
class NexoFrame {
  final String id, name, assetPath;
  final FrameRarity rarity;
  final int column, row;
  final String? requirement;

  const NexoFrame({
    required this.id,
    required this.name,
    required this.rarity,
    required this.assetPath,
    required this.column,
    required this.row,
    this.requirement,
  });
}

const nexoFrameAtlasPath = 'assets/items/frames/frame_atlas.svg';

const nexoFrames = <NexoFrame>[
  NexoFrame(id:'sunrise_frame',name:'Sunrise Frame',rarity:FrameRarity.common,assetPath:nexoFrameAtlasPath,column:0,row:0),
  NexoFrame(id:'simple_gold',name:'Simple Gold',rarity:FrameRarity.common,assetPath:nexoFrameAtlasPath,column:1,row:0),
  NexoFrame(id:'ocean_wave',name:'Ocean Wave',rarity:FrameRarity.common,assetPath:nexoFrameAtlasPath,column:2,row:0),
  NexoFrame(id:'papyrus_ring',name:'Papyrus Ring',rarity:FrameRarity.common,assetPath:nexoFrameAtlasPath,column:3,row:0),
  NexoFrame(id:'desert_oasis',name:'Desert Oasis',rarity:FrameRarity.uncommon,assetPath:nexoFrameAtlasPath,column:0,row:1),
  NexoFrame(id:'balloon_party',name:'Balloon Party',rarity:FrameRarity.uncommon,assetPath:nexoFrameAtlasPath,column:1,row:1),
  NexoFrame(id:'zodiac_frame',name:'Zodiac Frame',rarity:FrameRarity.uncommon,assetPath:nexoFrameAtlasPath,column:2,row:1),
  NexoFrame(id:'bronze_frame_lv10',name:'Bronze Frame',rarity:FrameRarity.uncommon,assetPath:nexoFrameAtlasPath,column:3,row:1,requirement:'Lv.10'),
  NexoFrame(id:'bonded_hearts_frame',name:'Bonded Hearts Frame',rarity:FrameRarity.uncommon,assetPath:nexoFrameAtlasPath,column:4,row:1),
  NexoFrame(id:'crystal_ring',name:'Crystal Ring',rarity:FrameRarity.rare,assetPath:nexoFrameAtlasPath,column:0,row:2),
  NexoFrame(id:'warrior_frame',name:'Warrior Frame',rarity:FrameRarity.rare,assetPath:nexoFrameAtlasPath,column:1,row:2),
  NexoFrame(id:'love_bloom',name:'Love Bloom',rarity:FrameRarity.rare,assetPath:nexoFrameAtlasPath,column:2,row:2),
  NexoFrame(id:'silver_frame_lv25',name:'Silver Frame',rarity:FrameRarity.rare,assetPath:nexoFrameAtlasPath,column:3,row:2,requirement:'Lv.25'),
  NexoFrame(id:'ramadan_lantern_frame',name:'Ramadan Lantern Frame',rarity:FrameRarity.rare,assetPath:nexoFrameAtlasPath,column:4,row:2),
  NexoFrame(id:'fire_lion',name:'Fire Lion',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:0,row:3),
  NexoFrame(id:'diamond_princess',name:'Diamond Princess',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:1,row:3),
  NexoFrame(id:'golden_wings',name:'Golden Wings',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:2,row:3),
  NexoFrame(id:'gold_frame_lv50',name:'Gold Frame',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:3,row:3,requirement:'Lv.50'),
  NexoFrame(id:'emerald_lantern_frame',name:'Emerald Lantern Frame',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:4,row:3),
  NexoFrame(id:'eternal_bond_frame',name:'Eternal Bond Frame',rarity:FrameRarity.epic,assetPath:nexoFrameAtlasPath,column:5,row:3),
  NexoFrame(id:'noble_frame_rank1',name:'Noble Frame',rarity:FrameRarity.legendary,assetPath:nexoFrameAtlasPath,column:0,row:4,requirement:'Rank 1/6'),
  NexoFrame(id:'scribe_frame_rank2',name:'Scribe Frame',rarity:FrameRarity.legendary,assetPath:nexoFrameAtlasPath,column:1,row:4,requirement:'Rank 2/6'),
  NexoFrame(id:'vizier_frame_rank3',name:'Vizier Frame',rarity:FrameRarity.legendary,assetPath:nexoFrameAtlasPath,column:2,row:4,requirement:'Rank 3/6'),
  NexoFrame(id:'platinum_frame_lv100',name:'Platinum Frame',rarity:FrameRarity.legendary,assetPath:nexoFrameAtlasPath,column:3,row:4,requirement:'Lv.100'),
  NexoFrame(id:'anniversary_frame',name:'Anniversary Frame',rarity:FrameRarity.legendary,assetPath:nexoFrameAtlasPath,column:4,row:4),
  NexoFrame(id:'high_priest_frame_rank4',name:'High Priest Frame',rarity:FrameRarity.mythic,assetPath:nexoFrameAtlasPath,column:0,row:5,requirement:'Rank 4/6'),
  NexoFrame(id:'nomarch_frame_rank5',name:'Nomarch Frame',rarity:FrameRarity.mythic,assetPath:nexoFrameAtlasPath,column:1,row:5,requirement:'Rank 5/6'),
  NexoFrame(id:'pharaoh_frame_rank6',name:'Pharaoh Frame',rarity:FrameRarity.mythic,assetPath:nexoFrameAtlasPath,column:2,row:5,requirement:'Rank 6/6'),
  NexoFrame(id:'mythic_frame_lv200',name:'Mythic Frame',rarity:FrameRarity.mythic,assetPath:nexoFrameAtlasPath,column:3,row:5,requirement:'Lv.200'),
  NexoFrame(id:'new_year_frame',name:'New Year Frame',rarity:FrameRarity.mythic,assetPath:nexoFrameAtlasPath,column:4,row:5),
];