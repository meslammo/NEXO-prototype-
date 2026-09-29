import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/economy_service.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';
import 'inventory_screen.dart';
import 'our_club_screen.dart';
import 'missions_screen.dart';
import 'recharge_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(
        backgroundColor:NexoColors.background,
        elevation:0,
        actions:[
          IconButton(onPressed:(){},icon:const Icon(Icons.settings_outlined,color:Colors.white70)),
          IconButton(onPressed:(){},icon:const Icon(Icons.more_horiz_rounded,color:Colors.white70)),
        ],
      ),
      body:Consumer2<AuthService,EconomyService>(
        builder:(context,auth,economy,_){
          final u=auth.user ?? const <String,dynamic>{
            'username':'NEXO_KING','displayName':'NEXO Player','avatar':'N',
            'level':12,'reputation':850,'gems':12450,'vipLevel':'Premium'
          };
          final name=(u['displayName']??u['username']??'NEXO Player').toString();
          final username=(u['username']??'nexo_player').toString();
          final avatar=(u['avatar']??name).toString();
          final level=(u['level'] as num?)?.toInt()??1;
          final rep=(u['reputation'] as num?)?.toInt()??0;
          final vip=(u['vipLevel']??'Base').toString();

          return ListView(
            padding:const EdgeInsets.fromLTRB(14,0,14,28),
            children:[
              _profileTop(name,username,avatar,level),
              const SizedBox(height:8),
              Row(children:[
                Expanded(child:_stat('Friends','1')),
                const SizedBox(width:6),
                Expanded(child:_stat('Following','1')),
                const SizedBox(width:6),
                Expanded(child:_stat('Followers','10')),
              ]),
              const SizedBox(height:12),
              _wallet(economy.gems),
              const SizedBox(height:12),
              _featureGrid(context,vip,rep),
              const SizedBox(height:16),
              _section('My Space'),
              _menu(context,'Moments','منشوراتك وذكرياتك',Icons.photo_library_outlined,()=>_snack(context,'Moments قريبًا')),
              _menu(context,'My Room','الغرفة الشخصية والديكور',Icons.meeting_room_outlined,()=>_snack(context,'My Room قريبًا')),
              _menu(context,'Hall Of Honor','الترتيب والإنجازات',Icons.emoji_events_outlined,()=>_snack(context,'Hall Of Honor قريبًا')),
              _menu(context,'My Couple','رابط اجتماعي خاص',Icons.favorite_border_rounded,()=>_snack(context,'My Couple قريبًا')),
              _menu(context,'Collection','Gifts · Frames · Assets · Emoji',Icons.inventory_2_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InventoryScreen()))),
            ],
          );
        },
      ),
    );
  }

  Widget _profileTop(String name,String username,String avatar,int level)=>Container(
    padding:const EdgeInsets.fromLTRB(6,4,6,16),
    child:Row(
      children:[
        Container(
          width:78,height:78,
          decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:NexoColors.primary.withOpacity(.65),width:2.2),color:NexoColors.card),
          child:CircleAvatar(backgroundColor:NexoColors.surface,child:Text(avatar.isEmpty?'N':avatar[0],style:const TextStyle(color:NexoColors.primary,fontSize:30,fontWeight:FontWeight.bold))),
        ),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(name,style:const TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w800)),
          const SizedBox(height:3),
          Text('UID: ' + username,style:const TextStyle(color:NexoColors.textSecondary,fontSize:11)),
          const SizedBox(height:6),
          Row(children:[
            _badge('Lv.' + level.toString(),NexoColors.success),
            const SizedBox(width:6),
            _badge('NEXO',NexoColors.primary),
          ]),
        ])),
        IconButton(onPressed:(){},icon:const Icon(Icons.edit_outlined,color:Colors.white70)),
      ],
    ),
  );

  Widget _badge(String text,Color color)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
    decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:color.withOpacity(.28))),
    child:Text(text,style:TextStyle(color:color,fontSize:9,fontWeight:FontWeight.bold)),
  );

  Widget _stat(String label,String value)=>Container(
    padding:const EdgeInsets.symmetric(vertical:11),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(13)),
    child:Column(children:[Text(value,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(label,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10))]),
  );

  Widget _wallet(int gems)=>Container(
    padding:const EdgeInsets.all(15),
    decoration:BoxDecoration(
      gradient:const LinearGradient(begin:Alignment.centerLeft,end:Alignment.centerRight,colors:[Color(0xFF39205F),Color(0xFF17182E)]),
      borderRadius:BorderRadius.circular(16),
      border:Border.all(color:const Color(0xFF8C5BFF).withOpacity(.35)),
    ),
    child:Row(children:[
      const Icon(Icons.account_balance_wallet_outlined,color:Color(0xFFC89BFF),size:24),
      const SizedBox(width:10),
      const Expanded(child:Text('My Wallet',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),
      Text(gems.toString(),style:const TextStyle(color:Color(0xFFC89BFF),fontWeight:FontWeight.w800,fontSize:17)),
      const SizedBox(width:4),
      const Icon(Icons.diamond_rounded,color:Color(0xFFC89BFF),size:16),
      const Icon(Icons.chevron_left_rounded,color:Colors.white54),
    ]),
  );

  Widget _featureGrid(BuildContext context,String vip,int rep)=>GridView.count(
    crossAxisCount:4,
    shrinkWrap:true,
    physics:const NeverScrollableScrollPhysics(),
    mainAxisSpacing:8,crossAxisSpacing:8,
    childAspectRatio:.92,
    children:[
      _feature(context,'Wealth Level','💎',()=>_snack(context,'Wealth Level: ' + rep.clamp(1,99).toString())),
      _feature(context,'SVIP','👑',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RechargeScreen()))),
      _feature(context,'Aristocracy','🏛️',()=>_snack(context,'Aristocracy — ' + vip)),
      _feature(context,'Charm Level','💜',()=>_snack(context,'Charm Level قريبًا')),
      _feature(context,'Shop','🛍️',()=>_snack(context,'افتح Market من الشريط السفلي')),
      _feature(context,'Points Bank','🏦',()=>_snack(context,'Points Bank قريبًا')),
      _feature(context,'Family / Tribe','🏠',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OurClubScreen()))),
      _feature(context,'Task','📋',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MissionsScreen()))),
    ],
  );

  Widget _feature(BuildContext context,String title,String emoji,VoidCallback onTap)=>InkWell(
    onTap:onTap,
    borderRadius:BorderRadius.circular(15),
    child:Container(
      padding:const EdgeInsets.symmetric(horizontal:4,vertical:9),
      decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15),border:Border.all(color:NexoColors.cardBorder)),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Text(emoji,style:const TextStyle(fontSize:22)),
        const SizedBox(height:5),
        Text(title,textAlign:TextAlign.center,maxLines:2,style:const TextStyle(color:Colors.white70,fontSize:9,fontWeight:FontWeight.w600)),
      ]),
    ),
  );

  Widget _section(String title)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:16)));

  Widget _menu(BuildContext context,String title,String subtitle,IconData icon,VoidCallback onTap)=>Container(
    margin:const EdgeInsets.only(bottom:8),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15),border:Border.all(color:NexoColors.cardBorder)),
    child:ListTile(
      onTap:onTap,
      dense:true,
      leading:CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.11),child:Icon(icon,color:NexoColors.primary,size:20)),
      title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:13)),
      subtitle:Text(subtitle,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),
      trailing:const Icon(Icons.chevron_left_rounded,color:Colors.white54),
    ),
  );

  void _snack(BuildContext context,String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));
}