import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nexo_service.dart';
import '../services/economy_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';
import '../widgets/nexo_asset_art.dart';
import 'name_glow_screen.dart';
import 'inventory_screen.dart';
import 'our_club_screen.dart';
import 'recharge_screen.dart';
import 'craft_screen.dart';

class ProfileScreen extends StatefulWidget{const ProfileScreen({super.key});@override State<ProfileScreen> createState()=>_ProfileScreenState();}
class _ProfileScreenState extends State<ProfileScreen>{
  Map<String,Map<String,dynamic>> equipped={};
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){_loadEquipped();});}
  Future<void> _loadEquipped() async{
    final auth=context.read<AuthService>();if(!(NexoApiConfig.configured&&auth.online))return;
    try{
      final r=await context.read<ApiClient>().getJson('/profile/equipped');final raw=r['data'];final out=<String,Map<String,dynamic>>{};
      if(raw is List){for(final row in raw.whereType<Map>()){out['${row['slot']}']=Map<String,dynamic>.from(row);}}
      if(mounted)setState(()=>equipped=out);
    }catch(_){}
  }
  Color _parseColor(String value){try{return Color(int.parse('0xFF'+value.replaceFirst('#','')));}catch(_){return NexoColors.primary;}}
  Widget _avatar(NexoCatalogService catalog,String avatar,Color color){
    final frameId=equipped['frame']?['id']?.toString(),assetId=equipped['profile_asset']?['id']?.toString();
    final frame=frameId==null?null:catalog.getById(frameId),asset=assetId==null?null:catalog.getById(assetId);
    return SizedBox(width:150,height:150,child:Stack(alignment:Alignment.center,children:[
      if(asset!=null)NexoAssetArt(item:asset,size:146),
      CircleAvatar(radius:51,backgroundColor:NexoColors.card,child:Text(avatar.isEmpty?'N':avatar[0],style:TextStyle(color:color,fontSize:34,fontWeight:FontWeight.bold))),
      if(frame!=null)NexoAssetArt(item:frame,size:136),
    ]));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:NexoColors.background,
    appBar:AppBar(title:const Text('Profile'),centerTitle:true,backgroundColor:NexoColors.background,actions:[IconButton(onPressed:_loadEquipped,icon:const Icon(Icons.refresh_rounded))]),
    body:Consumer3<NexoService,EconomyService,NexoCatalogService>(builder:(context,nexo,economy,catalog,_){
      final user=nexo.currentUser,color=_parseColor(user.nameColor),frame=equipped['frame'],asset=equipped['profile_asset'];
      return ListView(padding:const EdgeInsets.fromLTRB(16,10,16,30),children:[
        Center(child:_avatar(catalog,user.avatar,color)),const SizedBox(height:4),
        Center(child:Text(user.displayName,style:TextStyle(color:color,fontSize:22,fontWeight:FontWeight.bold,shadows:user.glow?[Shadow(color:color,blurRadius:14),Shadow(color:color.withOpacity(.45),blurRadius:26)]:null))),
        const SizedBox(height:4),Center(child:Text('💎 ${economy.gems} Gems',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold))),
        const SizedBox(height:12),
        Row(children:[Expanded(child:_Stat('Level',user.level.toString())),const SizedBox(width:8),Expanded(child:_Stat('Reputation',user.reputation.toString())),const SizedBox(width:8),Expanded(child:_Stat('NEXO Score',user.nexoScore.toString()))]),
        const SizedBox(height:18),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:NexoColors.primary.withOpacity(.22))),child:Row(children:[
          const Icon(Icons.style_rounded,color:NexoColors.primary),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Equipped Cosmetics',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
            Text('Frame: ${frame?['name'] ?? 'None'} · Asset: ${asset?['name'] ?? 'None'}',style:const TextStyle(color:NexoColors.textSecondary,fontSize:11))
          ])),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InventoryScreen())),child:const Text('تغيير'))
        ])),
        const SizedBox(height:18),const Text('حسابك',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),const SizedBox(height:10),
        _Menu(icon:Icons.auto_awesome_rounded,title:'Font Colour',subtitle:'لون ووهج الاسم + المعاينة داخل الشات',color:color,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NameGlowScreen()))),
        _Menu(icon:Icons.inventory_2_rounded,title:'Collection / Inventory',subtitle:'Gifts · Frames · Assets · Emoji · Crafted',color:const Color(0xFF7B5CFF),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InventoryScreen()))),
        _Menu(icon:Icons.handyman_rounded,title:'Workshop / Craft',subtitle:'التصنيع يدخل المنتج إلى المخزون',color:Colors.deepPurpleAccent,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CraftScreen()))),
        _Menu(icon:Icons.groups_rounded,title:'Our Club',subtitle:'المجتمع والعضوية والنشاط',color:NexoColors.primary,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OurClubScreen()))),
        _Menu(icon:Icons.military_tech_rounded,title:'Badges',subtitle:user.badges.isEmpty?'لا توجد شارات بعد':user.badges.join(' · '),color:Colors.amber,onTap:(){}),
        _Menu(icon:Icons.workspace_premium_rounded,title:'VIP / Recharge',subtitle:'العضوية والمزايا وشحن Gems',color:Colors.amber,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RechargeScreen()))),
      ]);
    }),
  );
}
class _Stat extends StatelessWidget{final String label,value;const _Stat(this.label,this.value);@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(vertical:13,horizontal:8),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(14),border:Border.all(color:NexoColors.cardBorder)),child:Column(children:[Text(label,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),const SizedBox(height:4),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:17))]));}
class _Menu extends StatelessWidget{final IconData icon;final String title,subtitle;final Color color;final VoidCallback onTap;const _Menu({required this.icon,required this.title,required this.subtitle,required this.color,required this.onTap});@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:color.withOpacity(.3))),child:ListTile(onTap:onTap,leading:CircleAvatar(backgroundColor:color.withOpacity(.14),child:Icon(icon,color:color)),title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(subtitle,style:const TextStyle(color:NexoColors.textSecondary,fontSize:11)),trailing:const Icon(Icons.chevron_left_rounded,color:Colors.white54)));}
