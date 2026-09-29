import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';
import 'profile_feature_screen.dart';
import 'inventory_screen.dart';
import 'our_club_screen.dart';
import 'missions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState()=>_ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String,dynamic> data={};
  bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{
      final r=await context.read<ApiClient>().getJson('/profile/summary');
      if(mounted)setState(()=>data=Map<String,dynamic>.from(r));
    }catch(_){}
    if(mounted)setState(()=>loading=false);
  }
  Color _hex(String raw){
    var s=raw.replaceAll('#','').trim();
    if(s.length==6)s='FF'+s;
    return Color(int.tryParse(s,radix:16)??0xFF54D6FF);
  }

  void _open(ProfileFeature f)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProfileFeatureScreen(feature:f))).then((_)=>_load());

  @override Widget build(BuildContext context){
    final auth=context.watch<AuthService>();
    final econ=context.watch<EconomyService>();
    final user=auth.user??const <String,dynamic>{};
    final name=data['displayName']?.toString()??user['displayName']?.toString()??user['username']?.toString()??'NEXO_KING';
    final username=data['username']?.toString()??user['username']?.toString()??'nexo_user';
    final uid=(data['id']??auth.userId??'').toString();
    final nameColor=_hex(data['nameColor']?.toString()??user['nameColor']?.toString()??'#54D6FF');
    final friends=(data['friendsCount'] as num?)?.toInt()??0;
    final following=(data['followingCount'] as num?)?.toInt()??0;
    final followers=(data['followersCount'] as num?)?.toInt()??0;
    final level=(data['level'] as num?)?.toInt()??(user['level'] as num?)?.toInt()??1;

    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(backgroundColor:NexoColors.background,elevation:0,actions:[
        IconButton(onPressed:()=>_open(ProfileFeature.connections),icon:const Icon(Icons.person_add_alt_1_rounded,color:Colors.white70)),
        IconButton(onPressed:(){},icon:const Icon(Icons.settings_outlined,color:Colors.white70)),
      ]),
      body:loading
        ? const Center(child:CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh:_load,
          child:ListView(padding:const EdgeInsets.fromLTRB(14,0,14,24),children:[
            Container(
              padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF1B1738),Color(0xFF0E1829)]),borderRadius:BorderRadius.circular(22),border:Border.all(color:nameColor.withOpacity(.25))),
              child:Column(children:[
                CircleAvatar(radius:48,backgroundColor:nameColor.withOpacity(.14),child:Text(name.isEmpty?'?':name.substring(0,1),style:TextStyle(color:nameColor,fontSize:38,fontWeight:FontWeight.w900))),
                const SizedBox(height:10),
                Text(name,style:TextStyle(color:nameColor,fontSize:22,fontWeight:FontWeight.w900,shadows:[Shadow(color:nameColor.withOpacity(.45),blurRadius:12)])),
                const SizedBox(height:3),
                Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Text(username,style:const TextStyle(color:NexoColors.textSecondary,fontSize:11)),
                  const SizedBox(width:8),
                  Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:NexoColors.primary.withOpacity(.12),borderRadius:BorderRadius.circular(8)),child:Text('UID '+uid.substring(0,uid.length>8?8:uid.length),style:const TextStyle(color:NexoColors.primary,fontSize:9))),
                ]),
                const SizedBox(height:8),
                Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),decoration:BoxDecoration(color:NexoColors.gold.withOpacity(.12),borderRadius:BorderRadius.circular(8)),child:Text('Lv.$level',style:const TextStyle(color:NexoColors.gold,fontWeight:FontWeight.bold,fontSize:11))),
                  const SizedBox(width:7),
                  const Text('NEXO Member',style:TextStyle(color:Colors.white60,fontSize:11)),
                ]),
                const SizedBox(height:14),
                Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
                  _stat('Friends',friends),_stat('Following',following),_stat('Followers',followers)
                ]),
              ])
            ),
            const SizedBox(height:12),
            GestureDetector(
              onTap:()=>_open(ProfileFeature.wealth),
              child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:NexoColors.primary.withOpacity(.18))),child:Row(children:[
                const CircleAvatar(backgroundColor:Color(0x2223D6FF),child:Icon(Icons.diamond_rounded,color:NexoColors.primary)),
                const SizedBox(width:10),
                const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('My Wallet',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),Text('Gems · Wealth Level · Recharge',style:TextStyle(color:NexoColors.textSecondary,fontSize:10))])),
                Text(econ.gems.toString()+' 💎',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900)),
              ]))
            ),
            const SizedBox(height:14),
            const _SectionTitle('My Profile'),
            _featureGrid([
              _Feature('Wealth Level',Icons.diamond_rounded,NexoColors.primary,()=>_open(ProfileFeature.wealth)),
              _Feature('SVIP',Icons.workspace_premium_rounded,NexoColors.gold,()=>_open(ProfileFeature.svip)),
              _Feature('Aristocracy',Icons.account_balance_rounded,Colors.orangeAccent,()=>_open(ProfileFeature.aristocracy)),
              _Feature('Charm Level',Icons.favorite_rounded,Colors.pinkAccent,()=>_open(ProfileFeature.charm)),
              _Feature('Shop',Icons.storefront_rounded,Colors.cyanAccent,()=>_open(ProfileFeature.shop)),
              _Feature('Points Bank',Icons.account_balance_wallet_rounded,Colors.greenAccent,()=>_open(ProfileFeature.pointsBank)),
              _Feature('Tribe',Icons.groups_rounded,Colors.purpleAccent,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OurClubScreen()))),
              _Feature('Task',Icons.task_alt_rounded,Colors.orangeAccent,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MissionsScreen()))),
            ]),
            const SizedBox(height:18),
            const _SectionTitle('My Space'),
            _space('My Moments','اللحظات والمنشورات',Icons.photo_library_outlined,()=>_open(ProfileFeature.moments)),
            _space('My Room','خلفية الغرفة وتأثير الدخول',Icons.meeting_room_outlined,()=>_open(ProfileFeature.room)),
            _space('Hall Of Honor','ترتيب Wealth و Charm',Icons.emoji_events_outlined,()=>_open(ProfileFeature.hallOfHonor)),
            _space('My Couple','الارتباط داخل NEXO',Icons.favorite_border_rounded,()=>_open(ProfileFeature.couple)),
            _space('Connection','Following و Followers',Icons.people_alt_outlined,()=>_open(ProfileFeature.connections)),
            _space('Collection','إدارة العناصر المملوكة',Icons.inventory_2_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InventoryScreen()))),
          ]),
        ),
    );
  }

  Widget _featureGrid(List<_Feature> items)=>GridView.builder(
    shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:items.length,
    gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:.88),
    itemBuilder:(_,i)=>InkWell(onTap:items[i].onTap,borderRadius:BorderRadius.circular(15),child:Container(
      padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15),border:Border.all(color:NexoColors.cardBorder)),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(items[i].icon,color:items[i].color,size:25),const SizedBox(height:7),
        Text(items[i].label,textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))
      ])
    ))
  );

  Widget _space(String title,String sub,IconData icon,VoidCallback tap)=>Container(
    margin:const EdgeInsets.only(bottom:8),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(14),border:Border.all(color:NexoColors.cardBorder)),
    child:ListTile(onTap:tap,leading:CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.11),child:Icon(icon,color:NexoColors.primary,size:21)),title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:13)),subtitle:Text(sub,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),trailing:const Icon(Icons.chevron_left_rounded,color:Colors.white38))
  );

  Widget _stat(String label,int value)=>Column(children:[Text(value.toString(),style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text(label,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10))]);
}

class _Feature { final String label; final IconData icon; final Color color; final VoidCallback onTap; const _Feature(this.label,this.icon,this.color,this.onTap); }
class _SectionTitle extends StatelessWidget { final String text; const _SectionTitle(this.text); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:9,right:3),child:Text(text,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900))); }
