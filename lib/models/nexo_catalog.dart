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
NexoRarity nexoRarityFromString(String? raw) {
  final value = (raw ?? '').trim().toLowerCase().replaceAll(' ', '_');
  switch (value) {
    case 'rare': return NexoRarity.rare;
    case 'epic': return NexoRarity.epic;
    case 'legendary': return NexoRarity.legendary;
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
 NexoCatalogItem(id:'frame-cyan',name:'Cyan Orbit Frame',type:NexoItemType.frame,rarity:NexoRarity.rare,gems:900,image:'assets/nexo/frames/cyan-orbit.svg',tagline:'إطار مدار سماوي',description:'إطار دائري أزرق متوهج.',category:'frames',animation:'orbit'),
 NexoCatalogItem(id:'frame-violet',name:'Violet Pulse Frame',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:1800,image:'assets/nexo/frames/violet-pulse.svg',tagline:'نبض بنفسجي',description:'إطار نبضي بنفسجي.',category:'frames',animation:'pulse'),
 NexoCatalogItem(id:'frame-royal',name:'Royal Gold Frame',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:4200,image:'assets/nexo/frames/royal-gold.svg',tagline:'إطار ذهبي ملكي',description:'حلقة ذهبية للـProfile.',category:'frames',animation:'shine'),
 NexoCatalogItem(id:'frame-fire',name:'Inferno Frame',type:NexoItemType.frame,rarity:NexoRarity.legendary,gems:6000,image:'assets/nexo/frames/fire-ring.svg',tagline:'حلقة نارية',description:'إطار ناري قوي.',category:'frames',animation:'orbit'),
 NexoCatalogItem(id:'frame-galaxy',name:'Galaxy Ring Frame',type:NexoItemType.frame,rarity:NexoRarity.epic,gems:3000,image:'assets/nexo/frames/galaxy-ring.svg',tagline:'مدار مجري',description:'إطار فضائي متحرك.',category:'frames',animation:'orbit'),
 NexoCatalogItem(id:'frame-exclusive',name:'NEXO Exclusive Frame',type:NexoItemType.frame,rarity:NexoRarity.exclusive,gems:55000,image:'assets/nexo/frames/nexo-exclusive.svg',tagline:'إطار حصري',description:'إطار محدود.',category:'frames',animation:'shine',tradeable:false),
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
];

final nexoGifts=nexoCatalogSeed.where((e)=>e.type==NexoItemType.gift).toList(growable:false);
final nexoFrames=nexoCatalogSeed.where((e)=>e.type==NexoItemType.frame).toList(growable:false);
final nexoAssets=nexoCatalogSeed.where((e)=>e.type==NexoItemType.asset).toList(growable:false);
NexoGift? giftById(String id){for(final gift in nexoGifts){if(gift.id==id)return gift;}return null;}
