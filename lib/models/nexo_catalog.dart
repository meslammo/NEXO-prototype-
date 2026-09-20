import 'package:flutter/material.dart';

enum NexoRarity { common, uncommon, rare, epic, legendary, mythic, exclusive }
extension NexoRarityX on NexoRarity {
  String get label {
    switch (this) {
      case NexoRarity.common: return 'Common';
      case NexoRarity.uncommon: return 'Uncommon';
      case NexoRarity.rare: return 'Rare';
      case NexoRarity.epic: return 'Epic';
      case NexoRarity.legendary: return 'Legendary';
      case NexoRarity.mythic: return 'Mythic';
      case NexoRarity.exclusive: return 'NEXO Exclusive';
    }
  }
  Color get color {
    switch (this) {
      case NexoRarity.common: return Colors.blueGrey;
      case NexoRarity.uncommon: return Colors.greenAccent;
      case NexoRarity.rare: return Colors.lightBlueAccent;
      case NexoRarity.epic: return Colors.deepPurpleAccent;
      case NexoRarity.legendary: return Colors.orangeAccent;
      case NexoRarity.mythic: return Colors.redAccent;
      case NexoRarity.exclusive: return Colors.pinkAccent;
    }
  }
}
NexoRarity nexoRarityFromString(String? raw) {
  final value = (raw ?? '').trim().toLowerCase().replaceAll(' ', '_');
  switch (value) {
    case 'uncommon': return NexoRarity.uncommon;
    case 'rare': return NexoRarity.rare;
    case 'epic': return NexoRarity.epic;
    case 'legendary': return NexoRarity.legendary;
    case 'mythic': return NexoRarity.mythic;
    case 'nexo_exclusive':
    case 'exclusive': return NexoRarity.exclusive;
    default: return NexoRarity.common;
  }
}

enum NexoItemType { gift, frame, asset, emoji, crafted }
extension NexoItemTypeX on NexoItemType {
  String get apiValue => name;
  String get label {
    switch (this) {
      case NexoItemType.gift: return 'Gifts';
      case NexoItemType.frame: return 'Frames';
      case NexoItemType.asset: return 'Assets';
      case NexoItemType.emoji: return 'Emoji';
      case NexoItemType.crafted: return 'Crafted';
    }
  }
}
NexoItemType nexoItemTypeFromString(String? raw) => NexoItemType.values.firstWhere((x)=>x.name==(raw??'').toLowerCase(),orElse:()=>NexoItemType.gift);

class NexoCatalogItem {
  final String id, name, image, tagline, description, category, animation;
  final NexoRarity rarity;
  final NexoItemType type;
  final int gems, sortOrder;
  final bool tradeable, marketVisible, active;
  final List<String> tags;

  const NexoCatalogItem({required this.id,required this.name,required this.image,required this.tagline,required this.description,required this.category,required this.animation,required this.rarity,this.type=NexoItemType.gift,required this.gems,this.tradeable=true,this.marketVisible=true,this.active=true,this.sortOrder=0,this.tags=const []});

  factory NexoCatalogItem.fromJson(Map<String,dynamic> json) => NexoCatalogItem(
    id:'${json['id'] ?? ''}', name:'${json['name'] ?? 'Unnamed Item'}', image:'${json['image'] ?? ''}',
    tagline:'${json['tagline'] ?? ''}', description:'${json['description'] ?? json['tagline'] ?? ''}',
    category:'${json['category'] ?? 'featured'}', animation:'${json['animation'] ?? 'pulse'}',
    rarity:nexoRarityFromString(json['rarity']?.toString()),
    type:nexoItemTypeFromString(json['itemType']?.toString() ?? json['type']?.toString()),
    gems:(json['gems'] as num?)?.toInt() ?? 0, sortOrder:(json['sortOrder'] as num?)?.toInt() ?? 0,
    tradeable:json['tradeable'] != false, marketVisible:json['marketVisible'] != false, active:json['active'] != false,
    tags:(json['tags'] as List?)?.map((e)=>e.toString()).toList() ?? const [],
  );
  bool get isGift => type==NexoItemType.gift;
}

typedef NexoGift = NexoCatalogItem;

const _legacyGifts=<NexoGift>[
  NexoGift(id:'neon-heart',name:'Neon Heart',rarity:NexoRarity.common,gems:15,image:'neon_heart.png',tagline:'نبضة نيون لطيفة للشات',description:'هدية نيون خفيفة وسريعة للإرسال في الشات.',category:'gifts',animation:'pulse'),
  NexoGift(id:'shadow-flame',name:'Shadow Flame',rarity:NexoRarity.rare,gems:80,image:'shadow_flame.png',tagline:'لهب مظلم للغرف الليلية',description:'لهب غامض مع أثر مضيء عند الإرسال.',category:'gifts',animation:'float'),
  NexoGift(id:'name-glow',name:'Name Glow',rarity:NexoRarity.rare,gems:120,image:'name_glow_ticket.png',tagline:'وهج مميز للاسم',description:'تأثير اسم قابل للاستخدام في الهوية والشات.',category:'identity',animation:'shine'),
  NexoGift(id:'diamond-glow',name:'Diamond Glow',rarity:NexoRarity.epic,gems:220,image:'diamond_glow.png',tagline:'لمعة ماسية عند الإرسال',description:'هدية ماسية بتأثير لمعان متدرج.',category:'gifts',animation:'shine'),
  NexoGift(id:'galaxy-aura',name:'Galaxy Aura',rarity:NexoRarity.epic,gems:280,image:'galaxy_aura.png',tagline:'هالة مجرية حول الرسالة',description:'هالة فضائية تظهر حول الرسالة والصورة.',category:'effects',animation:'orbit'),
  NexoGift(id:'rainbow-aura',name:'Rainbow Aura',rarity:NexoRarity.epic,gems:350,image:'rainbow_ticket.png',tagline:'أثر طيفي مميز',description:'طيف لوني نابض مناسب للعروض الخاصة.',category:'effects',animation:'rainbow'),
  NexoGift(id:'fire-wings',name:'Fire Wings',rarity:NexoRarity.legendary,gems:650,image:'fire_wings.png',tagline:'دخول ناري قوي',description:'أجنحة نارية بهالة قوية عند الإرسال.',category:'gifts',animation:'float'),
  NexoGift(id:'crown-shine',name:'Crown Shine',rarity:NexoRarity.legendary,gems:900,image:'crown_shine.png',tagline:'تاج لامع للغرف',description:'تاج ملكي متوهج يظهر عند الإهداء.',category:'gifts',animation:'shine'),
  NexoGift(id:'vip-emblem',name:'VIP Emblem',rarity:NexoRarity.exclusive,gems:1800,image:'vip_emblem.png',tagline:'شارة NEXO حصرية',description:'شارة خاصة غير قابلة للتداول.',category:'vip',animation:'pulse',tradeable:false),
];

const _newGifts=<NexoGift>[
  NexoGift(id:'dragon',name:'Dragon',rarity:NexoRarity.legendary,gems:12000,image:'assets/nexo/gifts/dragon.svg',tagline:'تنين NEXO الأسطوري',description:'تنين طاقة بوهج ناري.',category:'legendary',animation:'float',sortOrder:20),
  NexoGift(id:'unicorn',name:'Unicorn',rarity:NexoRarity.legendary,gems:9000,image:'assets/nexo/gifts/unicorn.svg',tagline:'اليونيكورن المتوهج',description:'يونيكورن سماوي بتدرجات مضيئة.',category:'legendary',animation:'shine',sortOrder:21),
  NexoGift(id:'phoenix',name:'Phoenix',rarity:NexoRarity.legendary,gems:15000,image:'assets/nexo/gifts/phoenix.svg',tagline:'بعث الفينيكس',description:'طائر العنقاء بنبض ناري.',category:'legendary',animation:'float',sortOrder:22),
  NexoGift(id:'nexo-car',name:'NEXO Car',rarity:NexoRarity.epic,gems:3500,image:'assets/nexo/gifts/nexo-car.svg',tagline:'السيارة النيون',description:'سيارة NEXO الرياضية.',category:'vehicles',animation:'pulse',sortOrder:23),
  NexoGift(id:'al-hurra',name:'Al-Hurra',rarity:NexoRarity.exclusive,gems:75000,image:'assets/nexo/gifts/al-hurra.svg',tagline:'الحُرّة',description:'رمز حرية حصري.',category:'exclusive',animation:'orbit',sortOrder:24,tradeable:false),
  NexoGift(id:'purity',name:'Purity',rarity:NexoRarity.epic,gems:1800,image:'assets/nexo/gifts/purity.svg',tagline:'النقاء',description:'قطرة نقاء مضيئة.',category:'gifts',animation:'shine',sortOrder:25),
  NexoGift(id:'moon-wolf',name:'Moon Wolf',rarity:NexoRarity.epic,gems:2400,image:'assets/nexo/gifts/moon-wolf.svg',tagline:'ذئب القمر',description:'ذئب سماوي بتأثير قمري.',category:'gifts',animation:'pulse',sortOrder:26),
  NexoGift(id:'crystal-rose',name:'Crystal Rose',rarity:NexoRarity.rare,gems:450,image:'assets/nexo/gifts/crystal-rose.svg',tagline:'وردة كريستالية',description:'وردة بلورية ملونة.',category:'gifts',animation:'shine',sortOrder:27),
  NexoGift(id:'thunder-core',name:'Thunder Core',rarity:NexoRarity.rare,gems:700,image:'assets/nexo/gifts/thunder-core.svg',tagline:'قلب البرق',description:'نواة برق بنبض سريع.',category:'effects',animation:'pulse',sortOrder:28),
  NexoGift(id:'royal-chest',name:'Royal Chest',rarity:NexoRarity.legendary,gems:6000,image:'assets/nexo/gifts/royal-chest.svg',tagline:'الصندوق الملكي',description:'صندوق جوائز ذهبي.',category:'featured',animation:'shine',sortOrder:29),
  NexoGift(id:'ocean-serpent',name:'Ocean Serpent',rarity:NexoRarity.epic,gems:3200,image:'assets/nexo/gifts/ocean-serpent.svg',tagline:'ثعبان المحيط',description:'ثعبان مائي طيفي.',category:'gifts',animation:'float',sortOrder:30),
  NexoGift(id:'cosmic-orb',name:'Cosmic Orb',rarity:NexoRarity.rare,gems:550,image:'assets/nexo/gifts/cosmic-orb.svg',tagline:'الكرة الكونية',description:'طاقة كونية دورانية.',category:'effects',animation:'orbit',sortOrder:31),
];

final nexoCatalogSeed=<NexoCatalogItem>[
 ..._legacyGifts,..._newGifts,
  NexoCatalogItem(id:'frame-01-sunrise',name:'Sunrise Frame',type:NexoItemType.frame,rarity:NexoRarity.common,gems:100,image:'assets/nexo/frames/original_30/frame-01-sunrise.png',tagline:'Sunrise Frame',description:'Sunrise Frame',category:'frames',animation:'shine',sortOrder:100,tradeable:true),
 NexoCatalogItem(id:'frame-02-simple-gold',name:'Simple Gold',type:NexoItemType.frame,rarity:NexoRarity.common,gems:150,image:'assets/nexo/frames/original_30/frame-02-simple-gold.png',tagline:'Simple Gold',description:'Simple Gold',category:'frames',animation:'shine',sortOrder:101,tradeable:true),
 NexoCatalogItem(id:'frame-03-ocean-wave',name:'Ocean Wave',type:NexoItemType.frame,rarity:NexoRarity.common,gems:200,image:'assets/nexo/frames/original_30/frame-03-ocean-wave.png',tagline:'Ocean Wave',description:'Ocean Wave',category:'frames',animation:'float',sortOrder:102,tradeable:true),
 NexoCatalogItem(id:'frame-04-papyrus-ring',name:'Papyrus Ring',type:NexoItemType.frame,rarity:NexoRarity.common,gems:250,image:'assets/nexo/frames/original_30/frame-04-papyrus-ring.png',tagline:'Papyrus Ring',description:'Papyrus Ring',category:'frames',animation:'pulse',sortOrder:103,tradeable:true),
 NexoCatalogItem(id:'frame-cyan',name:'Cyan Orbit Frame',type:NexoItemType.frame,rarity:NexoRarity.common,gems:250,image:'assets/nexo/frames/cyan-orbit.svg',tagline:'Legacy Cyan Orbit Frame',description:'Cyan Orbit Frame',category:'frames',animation:'shine',sortOrder:104,tradeable:true),
 NexoCatalogItem(id:'frame-05-desert-oasis',name:'Desert Oasis',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:400,image:'assets/nexo/frames/original_30/frame-05-desert-oasis.png',tagline:'Desert Oasis',description:'Desert Oasis',category:'frames',animation:'float',sortOrder:105,tradeable:true),
 NexoCatalogItem(id:'frame-06-balloon-party',name:'Balloon Party',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:500,image:'assets/nexo/frames/original_30/frame-06-balloon-party.png',tagline:'Balloon Party',description:'Balloon Party',category:'frames',animation:'pulse',sortOrder:106,tradeable:true),
 NexoCatalogItem(id:'frame-07-zodiac',name:'Zodiac Frame',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:650,image:'assets/nexo/frames/original_30/frame-07-zodiac.png',tagline:'Zodiac Frame',description:'Zodiac Frame',category:'frames',animation:'orbit',sortOrder:107,tradeable:true),
 NexoCatalogItem(id:'frame-08-bronze-lv10',name:'Bronze Frame (Lv.10)',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:800,image:'assets/nexo/frames/original_30/frame-08-bronze-lv10.png',tagline:'Bronze Frame (Lv.10)',description:'Bronze Frame (Lv.10)',category:'frames',animation:'shine',sortOrder:108,tradeable:true),
 NexoCatalogItem(id:'frame-09-bonded-hearts',name:'Bonded Hearts Frame',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:1000,image:'assets/nexo/frames/original_30/frame-09-bonded-hearts.png',tagline:'Bonded Hearts Frame',description:'Bonded Hearts Frame',category:'frames',animation:'pulse',sortOrder:109,tradeable:true),
 NexoCatalogItem(id:'frame-violet',name:'Violet Pulse Frame',type:NexoItemType.frame,rarity:NexoRarity.uncommon,gems:1000,image:'assets/nexo/frames/violet-pulse.svg',tagline:'Legacy Violet Pulse Frame',description:'Violet Pulse Frame',category:'frames',animation:'shine',sortOrder:110,tradeable:true),
 NexoCatalogItem(id:'frame-10-crystal-ring',name:'Crystal Ring',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:1500,image:'assets/nexo/frames/original_30/frame-10-crystal-ring.png',tagline:'Crystal Ring',description:'Crystal Ring',category:'frames',animation:'shine',sortOrder:111,tradeable:true),
 NexoCatalogItem(id:'frame-11-warrior',name:'Warrior Frame',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:2000,image:'assets/nexo/frames/original_30/frame-11-warrior.png',tagline:'Warrior Frame',description:'Warrior Frame',category:'frames',animation:'float',sortOrder:112,tradeable:true),
 NexoCatalogItem(id:'frame-12-love-bloom',name:'Love Bloom',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:2500,image:'assets/nexo/frames/original_30/frame-12-love-bloom.png',tagline:'Love Bloom',description:'Love Bloom',category:'frames',animation:'pulse',sortOrder:113,tradeable:true),
 NexoCatalogItem(id:'frame-13-silver-lv25',name:'Silver Frame (Lv.25)',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:3000,image:'assets/nexo/frames/original_30/frame-13-silver-lv25.png',tagline:'Silver Frame (Lv.25)',description:'Silver Frame (Lv.25)',category:'frames',animation:'shine',sortOrder:114,tradeable:true),
 NexoCatalogItem(id:'frame-14-ramadan-lantern',name:'Ramadan Lantern Frame',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:4000,image:'assets/nexo/frames/original_30/frame-14-ramadan-lantern.png',tagline:'Ramadan Lantern Frame',description:'Ramadan Lantern Frame',category:'frames',animation:'shine',sortOrder:115,tradeable:true),
 NexoCatalogItem(id:'frame-galaxy',name:'Galaxy Ring Frame',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:3000,image:'assets/nexo/frames/galaxy-ring.svg',tagline:'Legacy Galaxy Ring Frame',description:'Galaxy Ring Frame',category:'frames',animation:'shine',sortOrder:116,tradeable:true),
 NexoCatalogItem(id:'frame-15-fire-lion',name:'Fire Lion',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:6000,image:'assets/nexo/frames/original_30/frame-15-fire-lion.png',tagline:'Fire Lion',description:'Fire Lion',category:'frames',animation:'float',sortOrder:117,tradeable:true),
 NexoCatalogItem(id:'frame-16-diamond-princess',name:'Diamond Princess',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:7500,image:'assets/nexo/frames/original_30/frame-16-diamond-princess.png',tagline:'Diamond Princess',description:'Diamond Princess',category:'frames',animation:'shine',sortOrder:118,tradeable:true),
 NexoCatalogItem(id:'frame-17-golden-wings',name:'Golden Wings',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:9000,image:'assets/nexo/frames/original_30/frame-17-golden-wings.png',tagline:'Golden Wings',description:'Golden Wings',category:'frames',animation:'float',sortOrder:119,tradeable:true),
 NexoCatalogItem(id:'frame-18-gold-lv50',name:'Gold Frame (Lv.50)',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:11000,image:'assets/nexo/frames/original_30/frame-18-gold-lv50.png',tagline:'Gold Frame (Lv.50)',description:'Gold Frame (Lv.50)',category:'frames',animation:'shine',sortOrder:120,tradeable:true),
 NexoCatalogItem(id:'frame-19',name:'Frame 19',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:13000,image:'assets/nexo/frames/original_30/frame-19-frame-19.png',tagline:'Frame 19',description:'Frame 19',category:'frames',animation:'pulse',sortOrder:121,tradeable:true),
 NexoCatalogItem(id:'frame-20-eternal-bond',name:'Eternal Bond Frame',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:15000,image:'assets/nexo/frames/original_30/frame-20-eternal-bond.png',tagline:'Eternal Bond Frame',description:'Eternal Bond Frame',category:'frames',animation:'pulse',sortOrder:122,tradeable:true),
 NexoCatalogItem(id:'frame-royal',name:'Royal Gold Frame',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:11000,image:'assets/nexo/frames/royal-gold.svg',tagline:'Legacy Royal Gold Frame',description:'Royal Gold Frame',category:'frames',animation:'shine',sortOrder:123,tradeable:true),
 NexoCatalogItem(id:'frame-21-noble',name:'Noble Frame (Rank 1/6)',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:20000,image:'assets/nexo/frames/original_30/frame-21-noble.png',tagline:'Noble Frame (Rank 1/6)',description:'Noble Frame (Rank 1/6)',category:'frames',animation:'shine',sortOrder:124,tradeable:true),
 NexoCatalogItem(id:'frame-22-scribe',name:'Scribe Frame (Rank 2/6)',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:25000,image:'assets/nexo/frames/original_30/frame-22-scribe.png',tagline:'Scribe Frame (Rank 2/6)',description:'Scribe Frame (Rank 2/6)',category:'frames',animation:'shine',sortOrder:125,tradeable:true),
 NexoCatalogItem(id:'frame-23-vizier',name:'Vizier Frame (Rank 3/6)',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:30000,image:'assets/nexo/frames/original_30/frame-23-vizier.png',tagline:'Vizier Frame (Rank 3/6)',description:'Vizier Frame (Rank 3/6)',category:'frames',animation:'shine',sortOrder:126,tradeable:true),
 NexoCatalogItem(id:'frame-24-platinum-lv100',name:'Platinum Frame (Lv.100)',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:40000,image:'assets/nexo/frames/original_30/frame-24-platinum-lv100.png',tagline:'Platinum Frame (Lv.100)',description:'Platinum Frame (Lv.100)',category:'frames',animation:'shine',sortOrder:127,tradeable:true),
 NexoCatalogItem(id:'frame-25-anniversary',name:'Anniversary Frame',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:50000,image:'assets/nexo/frames/original_30/frame-25-anniversary.png',tagline:'Anniversary Frame',description:'Anniversary Frame',category:'frames',animation:'pulse',sortOrder:128,tradeable:true),
 NexoCatalogItem(id:'frame-fire',name:'Inferno Frame',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:50000,image:'assets/nexo/frames/fire-ring.svg',tagline:'Legacy Inferno Frame',description:'Inferno Frame',category:'frames',animation:'shine',sortOrder:129,tradeable:true),
 NexoCatalogItem(id:'frame-26-high-priest',name:'High Priest Frame (Rank 4/6)',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:75000,image:'assets/nexo/frames/original_30/frame-26-high-priest.png',tagline:'High Priest Frame (Rank 4/6)',description:'High Priest Frame (Rank 4/6)',category:'frames',animation:'shine',sortOrder:130,tradeable:true),
 NexoCatalogItem(id:'frame-27-nomarch',name:'Nomarch Frame (Rank 5/6)',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:100000,image:'assets/nexo/frames/original_30/frame-27-nomarch.png',tagline:'Nomarch Frame (Rank 5/6)',description:'Nomarch Frame (Rank 5/6)',category:'frames',animation:'shine',sortOrder:131,tradeable:true),
 NexoCatalogItem(id:'frame-28-pharaoh',name:'Pharaoh Frame (Rank 6/6)',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:150000,image:'assets/nexo/frames/original_30/frame-28-pharaoh.png',tagline:'Pharaoh Frame (Rank 6/6)',description:'Pharaoh Frame (Rank 6/6)',category:'frames',animation:'shine',sortOrder:132,tradeable:true),
 NexoCatalogItem(id:'frame-29-mythic-lv200',name:'Mythic Frame (Lv.200)',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:200000,image:'assets/nexo/frames/original_30/frame-29-mythic-lv200.png',tagline:'Mythic Frame (Lv.200)',description:'Mythic Frame (Lv.200)',category:'frames',animation:'shine',sortOrder:133,tradeable:true),
 NexoCatalogItem(id:'frame-30-new-year',name:'New Year Frame',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:250000,image:'assets/nexo/frames/original_30/frame-30-new-year.png',tagline:'New Year Frame',description:'New Year Frame',category:'frames',animation:'orbit',sortOrder:134,tradeable:true),
 NexoCatalogItem(id:'frame-exclusive',name:'NEXO Exclusive Frame',type:NexoItemType.frame,rarity:NexoRarity.mythic,gems:150000,image:'assets/nexo/frames/nexo-exclusive.svg',tagline:'Legacy NEXO Exclusive Frame',description:'NEXO Exclusive Frame',category:'frames',animation:'shine',sortOrder:135,tradeable:false),
NexoCatalogItem(id:'asset-cosmic',name:'Cosmic Aura Asset',type:NexoItemType.asset,rarity:NexoRarity.epic,gems:1200,image:'assets/nexo/assets/cosmic-aura.svg',tagline:'هالة كونية',description:'هالة خلفية للهوية.',category:'assets',animation:'orbit'),
 NexoCatalogItem(id:'asset-inferno',name:'Inferno Wings Asset',type:NexoItemType.asset,rarity:NexoRarity.legendary,gems:4500,image:'assets/nexo/assets/inferno-wings.svg',tagline:'أجنحة لهب',description:'أجنحة هوية متوهجة.',category:'assets',animation:'float'),
 NexoCatalogItem(id:'asset-halo',name:'Royal Halo Asset',type:NexoItemType.asset,rarity:NexoRarity.legendary,gems:5200,image:'assets/nexo/assets/royal-halo.svg',tagline:'الهالة الملكية',description:'هالة حول الصورة.',category:'assets',animation:'shine'),
 NexoCatalogItem(id:'asset-shield',name:'NEXO Shield Asset',type:NexoItemType.asset,rarity:NexoRarity.rare,gems:800,image:'assets/nexo/assets/nexo-shield.svg',tagline:'درع NEXO',description:'رمز حماية للهوية.',category:'assets',animation:'pulse'),
 NexoCatalogItem(id:'asset-comet',name:'Star Comet Asset',type:NexoItemType.asset,rarity:NexoRarity.epic,gems:2200,image:'assets/nexo/assets/star-comet.svg',tagline:'ذيل نجمي',description:'مؤثر سريع.',category:'assets',animation:'float'),
 NexoCatalogItem(id:'asset-prism',name:'Prism Burst Asset',type:NexoItemType.asset,rarity:NexoRarity.exclusive,gems:28000,image:'assets/nexo/assets/prism-burst.svg',tagline:'انفجار طيفي',description:'أصل بصري حصري.',category:'assets',animation:'rainbow',tradeable:false),
 NexoCatalogItem(id:'emoji-laugh',name:'Laugh Burst',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:25,image:'assets/nexo/emoji/laugh.svg',tagline:'ضحكة نيون',description:'إيموجي متحرك.',category:'emoji',animation:'pulse'),
 NexoCatalogItem(id:'emoji-fire',name:'Fire Emoji',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:60,image:'assets/nexo/emoji/fire.svg',tagline:'لهب سريع',description:'إيموجي لهب.',category:'emoji',animation:'float'),
 NexoCatalogItem(id:'emoji-heart',name:'Purple Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'assets/nexo/emoji/purple-heart.svg',tagline:'قلب بنفسجي',description:'إيموجي قلب.',category:'emoji',animation:'pulse'),
 NexoCatalogItem(id:'emoji-crown',name:'Crown Emoji',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:75,image:'assets/nexo/emoji/crown.svg',tagline:'تاج لامع',description:'إيموجي تاج.',category:'emoji',animation:'shine'),
 NexoCatalogItem(id:'emoji-wow',name:'Wow Emoji',type:NexoItemType.emoji,rarity:NexoRarity.epic,gems:120,image:'assets/nexo/emoji/wow.svg',tagline:'دهشة',description:'إيموجي دهشة.',category:'emoji',animation:'pulse'),
 NexoCatalogItem(id:'emoji-love',name:'Love Emoji',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:90,image:'assets/nexo/emoji/love.svg',tagline:'حب',description:'إيموجي حب.',category:'emoji',animation:'shine'),
 NexoCatalogItem(id:'emoji-rocket',name:'Rocket Emoji',type:NexoItemType.emoji,rarity:NexoRarity.epic,gems:150,image:'assets/nexo/emoji/rocket.svg',tagline:'انطلق',description:'إيموجي صاروخ.',category:'emoji',animation:'float'),
 NexoCatalogItem(id:'emoji-snow',name:'Snow Emoji',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:65,image:'assets/nexo/emoji/snow.svg',tagline:'ثلج نيون',description:'إيموجي ثلجي.',category:'emoji',animation:'orbit'),
 NexoCatalogItem(id:'crafted-shadow-mask',name:'Shadow Mask',type:NexoItemType.crafted,rarity:NexoRarity.epic,gems:0,image:'assets/nexo/crafted/shadow-mask.svg',tagline:'مصنوع بالـWorkshop',description:'قطعة تصنيع.',category:'crafted',animation:'pulse',marketVisible:false),
 NexoCatalogItem(id:'crafted-phoenix-seal',name:'Phoenix Seal',type:NexoItemType.crafted,rarity:NexoRarity.legendary,gems:0,image:'assets/nexo/crafted/phoenix-seal.svg',tagline:'ختم الفينيكس',description:'قطعة تصنيع نادرة.',category:'crafted',animation:'shine',marketVisible:false),
 NexoCatalogItem(id:'crafted-prism-token',name:'Prism Token',type:NexoItemType.crafted,rarity:NexoRarity.rare,gems:0,image:'assets/nexo/crafted/prism-token.svg',tagline:'توكن طيفي',description:'قطعة مصنعة.',category:'crafted',animation:'rainbow',marketVisible:false),
 NexoCatalogItem(id:'crafted-nebula-core',name:'Nebula Core',type:NexoItemType.crafted,rarity:NexoRarity.epic,gems:0,image:'assets/nexo/crafted/nebula-core.svg',tagline:'نواة سديم',description:'نواة مصنعة.',category:'crafted',animation:'orbit',marketVisible:false),
 NexoCatalogItem(id:'crafted-golden-signet',name:'Golden Signet',type:NexoItemType.crafted,rarity:NexoRarity.legendary,gems:0,image:'assets/nexo/crafted/golden-signet.svg',tagline:'خاتم ذهبي مصنوع',description:'ختم ملكي مصنوع.',category:'crafted',animation:'shine',marketVisible:false),
 NexoCatalogItem(id:'crafted-arcana',name:'NEXO Arcana',type:NexoItemType.crafted,rarity:NexoRarity.exclusive,gems:0,image:'assets/nexo/crafted/nexo-arcana.svg',tagline:'أركانا NEXO',description:'قطعة تصنيع حصرية.',category:'crafted',animation:'orbit',tradeable:false,marketVisible:false),
  NexoCatalogItem(id:'asset-sky-plane',name:'NEXO Sky Plane',type:NexoItemType.asset,rarity:NexoRarity.rare,gems:1600,image:'assets/nexo/assets/sky-plane.svg',tagline:'طائرة NEXO النيون',description:'طائرة نيون تحلق حول الهوية.',category:'assets',animation:'float',sortOrder:15),
  NexoCatalogItem(id:'asset-galaxy',name:'Galaxy',type:NexoItemType.asset,rarity:NexoRarity.epic,gems:3200,image:'assets/nexo/assets/galaxy.svg',tagline:'مجرة NEXO',description:'مجرة طيفية تدور حول الهوية.',category:'assets',animation:'orbit',sortOrder:16),
  NexoCatalogItem(id:'emoji-grinning',name:'Grinning',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:😀',tagline:'Grinning',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-joy',name:'Joy',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:25,image:'emoji:😂',tagline:'Joy',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-heart-eyes',name:'Heart Eyes',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:😍',tagline:'Heart Eyes',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-cool',name:'Cool',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:35,image:'emoji:😎',tagline:'Cool',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-cry',name:'Crying',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:😭',tagline:'Crying',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-angry',name:'Angry',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:30,image:'emoji:😡',tagline:'Angry',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-scream',name:'Scream',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:35,image:'emoji:😱',tagline:'Scream',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-thinking',name:'Thinking',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:🤔',tagline:'Thinking',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-party',name:'Party',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:35,image:'emoji:🥳',tagline:'Party',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-devil',name:'Devil',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:40,image:'emoji:😈',tagline:'Devil',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-thumbs-up',name:'Thumbs Up',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:👍',tagline:'Thumbs Up',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-thumbs-down',name:'Thumbs Down',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:👎',tagline:'Thumbs Down',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-wave',name:'Wave',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:👋',tagline:'Wave',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-pray',name:'Pray',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:25,image:'emoji:🙏',tagline:'Pray',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-clap',name:'Clap',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:25,image:'emoji:👏',tagline:'Clap',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-red-heart',name:'Red Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:25,image:'emoji:❤️',tagline:'Red Heart',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-purple-heart',name:'Purple Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:💜',tagline:'Purple Heart',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-blue-heart',name:'Blue Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:💙',tagline:'Blue Heart',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-green-heart',name:'Green Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:💚',tagline:'Green Heart',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-yellow-heart',name:'Yellow Heart',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:💛',tagline:'Yellow Heart',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-fire',name:'Fire',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:60,image:'emoji:🔥',tagline:'Fire',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-sparkles',name:'Sparkles',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:40,image:'emoji:✨',tagline:'Sparkles',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-party-popper',name:'Party Popper',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:40,image:'emoji:🎉',tagline:'Party Popper',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-rocket',name:'Rocket',type:NexoItemType.emoji,rarity:NexoRarity.epic,gems:75,image:'emoji:🚀',tagline:'Rocket',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-gem',name:'Gem',type:NexoItemType.emoji,rarity:NexoRarity.epic,gems:80,image:'emoji:💎',tagline:'Gem',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-crown',name:'Crown',type:NexoItemType.emoji,rarity:NexoRarity.epic,gems:80,image:'emoji:👑',tagline:'Crown',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-lightning',name:'Lightning',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:55,image:'emoji:⚡',tagline:'Lightning',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-star',name:'Star',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:45,image:'emoji:🌟',tagline:'Star',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-check',name:'Check',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:✅',tagline:'Check',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-x',name:'Cross',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:20,image:'emoji:❌',tagline:'Cross',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-hundred',name:'Hundred',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:50,image:'emoji:💯',tagline:'Hundred',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-handshake',name:'Handshake',type:NexoItemType.emoji,rarity:NexoRarity.common,gems:30,image:'emoji:🤝',tagline:'Handshake',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),
  NexoCatalogItem(id:'emoji-hearts',name:'Heart Hands',type:NexoItemType.emoji,rarity:NexoRarity.rare,gems:40,image:'emoji:🫶',tagline:'Heart Hands',description:'Standard emoji for chat and collection.',category:'emoji',animation:'pulse'),

];

final nexoGifts=nexoCatalogSeed.where((e)=>e.type==NexoItemType.gift).toList(growable:false);
final nexoFrames=nexoCatalogSeed.where((e)=>e.type==NexoItemType.frame).toList(growable:false);
final nexoAssets=nexoCatalogSeed.where((e)=>e.type==NexoItemType.asset).toList(growable:false);
NexoGift? giftById(String id){for(final gift in nexoGifts){if(gift.id==id)return gift;}return null;}