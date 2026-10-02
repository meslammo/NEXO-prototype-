import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nexo_catalog.dart';
import '../services/api_client.dart';
import '../services/economy_service.dart';
import '../services/power_service.dart';
import '../services/catalog_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';
import '../widgets/power_text.dart';
import '../widgets/nexo_asset_art.dart';
import 'recharge_screen.dart';
import 'membership_screen.dart';

class MarketScreen extends StatefulWidget{const MarketScreen({super.key});@override State<MarketScreen> createState()=>_MarketScreenState();}
class _MarketScreenState extends State<MarketScreen>{
  final search=TextEditingController();List<Map<String,dynamic>> items=[];List<Map<String,dynamic>> memberships=[];Map<String,dynamic> aristocracy={};String category='featured',quick='all';bool loading=true;
  @override void initState(){super.initState();search.addListener(change);load();}
  @override void dispose(){search.removeListener(change);search.dispose();super.dispose();}
  void change()=>setState((){});
  Future<void> load() async{
    final catalog = context.read<NexoCatalogService>();
    final typeValue = (NexoItemType t) {
      switch(t){
        case NexoItemType.nameColor: return 'name_color';
        case NexoItemType.entranceEffect: return 'entrance_effect';
        case NexoItemType.roomBackground: return 'room_background';
        default: return t.name;
      }
    };
    final seed = catalog.marketItems.map((x)=> <String,dynamic>{
      'id':x.id,'name':x.name,'rarity':x.rarity.label,'gems':x.gems,'image':x.image,
      'tagline':x.tagline,'description':x.description,'category':x.category,'animation':x.animation,
      'itemType':typeValue(x.type),'marketVisible':x.marketVisible,'active':x.active,'tradeable':x.tradeable,
      'sortOrder':x.sortOrder,
    }).toList();
    var list=<Map<String,dynamic>>[...seed];
    var ml=<Map<String,dynamic>>[];
    var ar=<String,dynamic>{'currentLevel':0,'products':<Map<String,dynamic>>[]};
    try{
      if(NexoApiConfig.configured){
        final c=await context.read<ApiClient>().getJson('/catalog?market=1');
        final raw=c is List ? c : c['data'];
        if(raw is List && raw.isNotEmpty){
          list=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();
        }
      }
    }catch(_){}
    try{
      if(NexoApiConfig.configured){
        final m=await context.read<ApiClient>().getJson('/memberships/catalog');
        final raw=m is List ? m : m['data'];
        if(raw is List) ml=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();
      }
    }catch(_){}
    try{
      if(NexoApiConfig.configured){
        final a=await context.read<ApiClient>().getJson('/aristocracy/catalog');
        ar=a;
      }
    }catch(_){}
    if(ml.isEmpty){
      ml=[
        {'id':'vip_1_30','kind':'vip','name':'VIP I','durationDays':30,'gemsPrice':1500,'benefits':{'dailyGems':30,'extraDailyMissions':1,'entranceEffects':true}},
        {'id':'vip_2_30','kind':'vip','name':'VIP II','durationDays':30,'gemsPrice':3000,'benefits':{'dailyGems':60,'extraDailyMissions':2,'storeDiscountPercent':5}},
        {'id':'vip_3_30','kind':'vip','name':'VIP III','durationDays':30,'gemsPrice':6500,'benefits':{'dailyGems':100,'extraDailyMissions':3,'profileBadge':true}},
        {'id':'svip_1_30','kind':'svip','name':'SVIP I','durationDays':30,'gemsPrice':10000,'benefits':{'dailyGems':250,'extraDailyMissions':5,'exclusiveStore':true}},
        {'id':'svip_2_30','kind':'svip','name':'SVIP II','durationDays':30,'gemsPrice':18000,'benefits':{'dailyGems':400,'missionBonusPercent':15,'entranceEffects':true}},
        {'id':'svip_3_30','kind':'svip','name':'SVIP III','durationDays':30,'gemsPrice':30000,'benefits':{'dailyGems':650,'missionBonusPercent':20,'exclusiveStore':true}},
      ];
    }
    if((ar['products'] is! List) || (ar['products'] as List).isEmpty){
      ar={'currentLevel':0,'products':[
        {'id':'noble_1','level':1,'name':'Noble I','gemsPrice':5000},
        {'id':'noble_2','level':2,'name':'Noble II','gemsPrice':9000},
        {'id':'noble_3','level':3,'name':'Noble III','gemsPrice':15000},
        {'id':'noble_4','level':4,'name':'Noble IV','gemsPrice':25000},
        {'id':'noble_5','level':5,'name':'Noble V','gemsPrice':40000},
        {'id':'noble_6','level':6,'name':'Noble VI','gemsPrice':65000},
      ]};
    }
    if(mounted)setState((){items=list;memberships=ml;aristocracy=ar;loading=false;});
  }
  NexoRarity rarity(String? r)=>nexoRarityFromString(r);NexoCatalogItem item(Map<String,dynamic> m)=>NexoCatalogItem.fromJson(m);
  bool matches(Map<String,dynamic> m){final t=m['itemType']?.toString()??'',cat=(m['category']?.toString()??'').toLowerCase(),q=search.text.trim().toLowerCase();if(category=='gifts'&&t!='gift')return false;if(category=='frames'&&(t!='frame'||cat=='name_cards'||cat=='chat_style'))return false;if(category=='name_cards'&&cat!='name_cards'&&cat!='chat_style')return false;if(category=='font'&&t!='name_color'&&t!='power')return false;if(category=='entrance'&&t!='entrance_effect')return false;if(category=='rooms'&&t!='room_background')return false;if(category=='powers')return false;if(category=='limited'&&m['limited']!=true)return false;if(category=='new'){final md=m['metadata'] is Map?Map<String,dynamic>.from(m['metadata']):<String,dynamic>{};if(md['isNew']!=true)return false;}if(quick=='featured'&&m['featured']!=true)return false;if(quick=='limited'&&m['limited']!=true)return false;if(quick=='new'){final md=m['metadata'] is Map?Map<String,dynamic>.from(m['metadata']):<String,dynamic>{};if(md['isNew']!=true)return false;}return q.isEmpty||(m['id'].toString()+' '+m['name'].toString()+' '+m['tagline'].toString()).toLowerCase().contains(q);}
  List<Map<String,dynamic>> get filtered=>items.where(matches).toList();
  Color hex(String s){var x=s.replaceAll('#','');if(x.length==6)x='FF'+x;return Color(int.tryParse(x,radix:16)??0xFF54D6FF);}
  Widget preview(Map<String,dynamic> m,double size){final image=m['image']?.toString()??'';if(image.startsWith('color:')){final c=hex(image.substring(6));return Container(width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,color:c,boxShadow:[BoxShadow(color:c.withOpacity(.5),blurRadius:16)]),alignment:Alignment.center,child:const Text('Aa',style:TextStyle(color:Colors.black,fontWeight:FontWeight.w900,fontSize:20)));}if(image.startsWith('gradient:'))return Container(width:size,height:size,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[Color(0xFF54D6FF),Color(0xFFB44CFF),Color(0xFFFF6B9D),Color(0xFFFFD166)])),alignment:Alignment.center,child:const Text('Aa',style:TextStyle(color:Colors.black,fontWeight:FontWeight.w900,fontSize:18)));if(image.startsWith('power:'))return Container(width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.white.withOpacity(.04),border:Border.all(color:rarity(m['rarity']?.toString()).color.withOpacity(.5)),boxShadow:[BoxShadow(color:rarity(m['rarity']?.toString()).color.withOpacity(.35),blurRadius:18)]),alignment:Alignment.center,child:NexoPowerText(text:'Aa',powerId:m['id']?.toString(),style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)));
if(image.startsWith('effect:'))return Container(width:size,height:size,decoration:BoxDecoration(shape:BoxShape.circle,gradient:const LinearGradient(colors:[Color(0xFF54D6FF),Color(0xFFB44CFF)])),child:const Icon(Icons.auto_awesome,color:Colors.white));if(image.startsWith('room:'))return Container(width:size,height:size,decoration:const BoxDecoration(borderRadius:BorderRadius.all(Radius.circular(16)),gradient:LinearGradient(colors:[Color(0xFF10162B),Color(0xFF3A1C5A)])),child:const Icon(Icons.meeting_room,color:Colors.white70));return NexoAssetArt(item:item(m),size:size);}
  String duration(Map<String,dynamic> m){final d=(m['durationDays'] as num?)?.toInt()??0;return d>0?d.toString()+' يوم':'دائم';}
  Future<void> buy(Map<String,dynamic> m) async{if(!NexoApiConfig.configured){final e=context.read<EconomyService>();final cost=(m['gems'] as num?)?.toInt()??0;if(e.gems<cost){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Gems غير كافية')));return;}e.setGems(e.gems-cost);e.addItem(m['id'].toString(),1);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ تمت إضافة '+m['name'].toString()+' إلى مقتنياتك')));return;}final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(backgroundColor:NexoColors.card,title:Text(m['name'].toString(),style:TextStyle(color:rarity(m['rarity']?.toString()).color,fontWeight:FontWeight.bold)),content:Text('شراء مقابل '+m['gems'].toString()+' Gems؟',style:const TextStyle(color:Colors.white70)),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(context,true),child:const Text('شراء'))]));if(ok!=true)return;try{final r=await context.read<ApiClient>().postJson('/gifts/buy',{'giftId':m['id'],'idempotencyKey':'store-'+m['id'].toString()+'-'+DateTime.now().microsecondsSinceEpoch.toString()});final e=context.read<EconomyService>();e.setGems((r['gems'] as num?)?.toInt()??e.gems);e.addItem(m['id'].toString(),1);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('✅ تمت إضافة '+m['name'].toString())));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الشراء: '+e.toString()),backgroundColor:Colors.redAccent));}}
  Future<void> equip(Map<String,dynamic> m) async{final t=m['itemType']?.toString();final slot=t=='frame'?'frame':t=='name_color'?'name_color':t=='entrance_effect'?'entrance_effect':t=='room_background'?'room_background':t=='power'?'power':null;if(slot==null)return;try{if(NexoApiConfig.configured)await context.read<ApiClient>().postJson('/profile/equipped',{'slot':slot,'itemId':m['id']});if(slot=='power')context.read<PowerService>().setActivePower(m['id'].toString());if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('✅ تم تفعيل العنصر')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التفعيل: '+e.toString()),backgroundColor:Colors.redAccent));}}
  void details(Map<String,dynamic> m,int owned){showDialog(context:context,builder:(_)=>AlertDialog(backgroundColor:NexoColors.card,title:Text(m['name'].toString(),style:TextStyle(color:rarity(m['rarity']?.toString()).color,fontWeight:FontWeight.bold)),content:Column(mainAxisSize:MainAxisSize.min,children:[preview(m,120),const SizedBox(height:8),Text(m['description']?.toString()??'',style:const TextStyle(color:Colors.white70),textAlign:TextAlign.center),const SizedBox(height:7),Text(m['gems'].toString()+' Gems • '+duration(m),style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold)),Text(owned>0?'Owned x'+owned.toString():'Not owned',style:const TextStyle(color:NexoColors.textSecondary))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),ElevatedButton(onPressed:(){Navigator.pop(context);buy(m);},child:const Text('شراء'))]));}
  Widget card(Map<String,dynamic> m){final e=context.watch<EconomyService>();final owned=e.inventory[m['id']?.toString()]??0;return Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(17),border:Border.all(color:rarity(m['rarity']?.toString()).color.withOpacity(.35))),child:Column(children:[Expanded(child:GestureDetector(onTap:()=>details(m,owned),child:preview(m,84))),Text(m['name'].toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11)),Text(m['rarity'].toString(),style:TextStyle(color:rarity(m['rarity']?.toString()).color,fontSize:9)),Text(m['gems'].toString()+' 💎',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold,fontSize:10)),Text(owned>0?'Owned x'+owned.toString():duration(m),style:const TextStyle(color:NexoColors.textSecondary,fontSize:9)),const SizedBox(height:3),Row(children:[Expanded(child:OutlinedButton(onPressed:()=>details(m,owned),child:const Text('Preview',style:TextStyle(fontSize:9)))),const SizedBox(width:4),Expanded(child:ElevatedButton(onPressed:()=>buy(m),child:const Text('Buy',style:TextStyle(fontSize:9))))]),if(owned>0&&['frame','name_color','entrance_effect','room_background','power'].contains(m['itemType']))TextButton(onPressed:()=>equip(m),child:const Text('Equip',style:TextStyle(fontSize:9))) ]));}
  Widget membershipList(String kind) {
    final visible = memberships.where((p) => p['kind'] == kind).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(kind.toUpperCase(), style: TextStyle(color: kind == 'svip' ? NexoColors.gold : NexoColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...visible.map((p) => Card(
          color: NexoColors.card,
          child: ListTile(
            title: Text(p['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(p['durationDays'].toString() + ' يوم • ' + p['gemsPrice'].toString() + ' Gems', style: const TextStyle(color: NexoColors.textSecondary)),
            trailing: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipScreen(initialKind: kind))),
              child: const Text('فتح'),
            ),
          ),
        )),
      ],
    );
  }
  Widget aristocracyList(){final cur=(aristocracy['currentLevel'] as num?)?.toInt()??0;final raw=aristocracy['products'];final list=raw is List?raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():<Map<String,dynamic>>[];return ListView(padding:const EdgeInsets.all(12),children:[Text('Aristocracy • Lv.'+cur.toString()+'/6',style:const TextStyle(color:NexoColors.gold,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:8),...list.map((p){final lv=(p['level'] as num?)?.toInt()??0;return Card(color:NexoColors.card,child:ListTile(leading:CircleAvatar(backgroundColor:NexoColors.gold.withOpacity(.12),child:Text(lv.toString(),style:const TextStyle(color:NexoColors.gold,fontWeight:FontWeight.bold))),title:Text(p['name'].toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(p['gemsPrice'].toString()+' Gems',style:const TextStyle(color:NexoColors.textSecondary)),trailing:ElevatedButton(onPressed:lv<=cur?null:()async{try{final r=await context.read<ApiClient>().postJson('/aristocracy/buy',{'productId':p['id'],'idempotencyKey':'aristocracy-'+p['id'].toString()+'-'+DateTime.now().microsecondsSinceEpoch.toString()});final e=context.read<EconomyService>();e.setGems((r['gems'] as num?)?.toInt()??e.gems);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('✅ تم رفع Aristocracy')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الترقية: '+e.toString()),backgroundColor:Colors.redAccent));}},child:Text(lv<=cur?'مفتوحة':'ترقية'))));})]);}
  @override
  Widget build(BuildContext context) {
    final cats = const [
      ['featured', 'Featured'], ['gifts', 'Gifts'], ['frames', 'Profile Frames'], ['font', 'Font Color'],
      ['entrance', 'Entrance Effects'], ['rooms', 'Room Backgrounds'], ['name_cards', 'Name Cards / Chat Style'],
      ['vip', 'VIP'], ['svip', 'SVIP'], ['aristocracy', 'Aristocracy'], ['all', 'All'],
    ];
    final shown = category == 'featured'
        ? items.where((m) => m['featured'] == true).toList()
        : category == 'all'
            ? items.where(matches).toList()
            : category == 'vip' || category == 'svip' || category == 'aristocracy'
                ? const <Map<String, dynamic>>[]
                : filtered;
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(
        backgroundColor: NexoColors.background,
        title: const Text('NEXO Store'),
        centerTitle: true,
        actions: [
          Consumer<EconomyService>(
            builder: (_, e, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(child: Text(e.gems.toString() + ' 💎', style: const TextStyle(color: NexoColors.primary, fontWeight: FontWeight.w900))),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargeScreen())),
            icon: const Icon(Icons.add_card, color: NexoColors.gold),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: search,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: NexoColors.primary),
                      hintText: 'Search Store',
                      hintStyle: TextStyle(color: NexoColors.textSecondary),
                      filled: true,
                      fillColor: NexoColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: ['all', 'featured', 'new', 'limited'].map((x) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(label: Text(x.toUpperCase()), selected: quick == x, onSelected: (_) { setState(() => quick = x); }),
                  )).toList()),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(children: cats.map((c) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(label: Text(c[1]), selected: category == c[0], onSelected: (_) { setState(() => category = c[0]); }),
                  )).toList()),
                ),
                Expanded(
                  child: category == 'vip'
                      ? membershipList('vip')
                      : category == 'svip'
                          ? membershipList('svip')
                          : category == 'aristocracy'
                              ? aristocracyList()
                              : GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: shown.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .70),
                                  itemBuilder: (_, i) => card(shown[i]),
                                ),
                ),
              ],
            ),
    );
  }
}