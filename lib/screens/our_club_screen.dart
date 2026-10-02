import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/social_engine.dart';
import '../services/economy_service.dart';
import '../theme/nexo_theme.dart';
import 'missions_screen.dart';
import 'chat_screen.dart';
import 'room_screen.dart';
import 'membership_screen.dart';

class OurClubScreen extends StatelessWidget {
  const OurClubScreen({super.key});

  static const members=[
    ('NEXO_KING','Leader','🇪🇬'),
    ('Shadoww','Admin','🇪🇬'),
    ('GalaxyGirl','Tycoon','🇹🇷'),
    ('Prince_X','Member','🇪🇬'),
    ('Ahmed','Member','🇪🇬'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(
        backgroundColor:NexoColors.background,
        title:const Text('Our Tribe'),
        centerTitle:true,
        actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MissionsScreen())),icon:const Icon(Icons.assignment_outlined))],
      ),
      body:ListView(
        padding:const EdgeInsets.fromLTRB(16,8,16,30),
        children:[
          _tribeHeader(context),
          const SizedBox(height:14),
          _infoRow('Tribe ID','NEXO-2048',Icons.badge_outlined),
          _infoRow('Tribe Level','IV',Icons.workspace_premium_outlined),
          _infoRow('Members','248 / 500',Icons.groups_2_outlined),
          _infoRow('Member Countries','🇪🇬 🇹🇷 🇸🇦 🇦🇪',Icons.public_outlined),
          _infoRow('Weekly Activity','86%',Icons.bolt_outlined),
          const SizedBox(height:16),
          _sectionTitle('Representatives'),
          const SizedBox(height:8),
          _representatives(),
          const SizedBox(height:16),
          _sectionTitle('Tribe Daily Tasks'),
          const SizedBox(height:8),
          Consumer<SocialEngine>(
            builder:(context,s,_){
              final chat=s.activities.where((a)=>a['type']=='chat').length.clamp(0,100);
              final gifts=s.activities.where((a)=>a['type']=='gift_send').length.clamp(0,20);
              return Column(children:[
                _task('Chat with tribe members',chat,3,Icons.forum_outlined),
                _task('Send a tribe gift',gifts,1,Icons.card_giftcard_outlined),
                _task('Join a voice activity',s.activities.where((a)=>a['type']=='voice_call'||a['type']=='video_call').length.clamp(0,1),1,Icons.mic_none_rounded),
                _task('Invite a new member',0,1,Icons.person_add_alt_1_outlined),
              ]);
            },
          ),
          const SizedBox(height:8),
          _action(
            context,
            title:'Open Tribe Chat',
            subtitle:'ادخل الشات وتكلم مع أعضاء المجتمع',
            icon:Icons.chat_bubble_outline,
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChatScreen())),
          ),
          _action(
            context,
            title:'Open NEXO Rooms',
            subtitle:'غرف صوتية 9 كراسي + مايك + ألعاب داخل الشات',
            icon:Icons.record_voice_over_rounded,
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const VoiceRoomsScreen())),
          ),
          _action(
            context,
            title:'VIP / SVIP',
            subtitle:'العضويات، المميزات، الهدايا والمهام الخاصة',
            icon:Icons.workspace_premium_rounded,
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MembershipScreen())),
          ),
          _action(
            context,
            title:'View All Missions',
            subtitle:'اليومية + الأسبوعية + مهام الـTribe',
            icon:Icons.task_alt_outlined,
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MissionsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _tribeHeader(BuildContext context)=>Container(
    padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(
      gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF34205B),Color(0xFF17142F)]),
      borderRadius:BorderRadius.circular(24),
      border:Border.all(color:NexoColors.primary.withOpacity(.35)),
    ),
    child:Column(children:[
      Container(width:80,height:80,decoration:BoxDecoration(shape:BoxShape.circle,color:NexoColors.primary.withOpacity(.13),border:Border.all(color:NexoColors.primary.withOpacity(.55),width:2)),child:const Icon(Icons.groups_rounded,color:NexoColors.primary,size:42)),
      const SizedBox(height:10),
      const Text('NEXO Tribe',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
      const SizedBox(height:4),
      const Text('مجتمعنا — أعضاء، نشاط، مهام، وغرف صوتية',style:TextStyle(color:NexoColors.textSecondary,fontSize:12)),
      const SizedBox(height:14),
      Row(children:[
        Expanded(child:_mini('⚡','Power','8,420')),
        const SizedBox(width:8),
        Expanded(child:_mini('🏆','Weekly','86%')),
        const SizedBox(width:8),
        Expanded(child:_mini('👥','Members','248')),
      ]),
    ]),
  );

  Widget _mini(String a,String b,String c)=>Container(
    padding:const EdgeInsets.symmetric(vertical:10),
    decoration:BoxDecoration(color:Colors.black.withOpacity(.15),borderRadius:BorderRadius.circular(14)),
    child:Column(children:[Text(a,style:const TextStyle(fontSize:18)),const SizedBox(height:3),Text(c,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),Text(b,style:const TextStyle(color:NexoColors.textSecondary,fontSize:9))]),
  );

  Widget _infoRow(String label,String value,IconData icon)=>Container(
    margin:const EdgeInsets.only(bottom:8),
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15),border:Border.all(color:NexoColors.cardBorder)),
    child:Row(children:[Icon(icon,color:NexoColors.primary,size:21),const SizedBox(width:10),Expanded(child:Text(label,style:const TextStyle(color:NexoColors.textSecondary,fontSize:12))),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:12))]),
  );

  Widget _sectionTitle(String title)=>Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:16));

  Widget _representatives()=>Container(
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:NexoColors.cardBorder)),
    child:Column(children:[
      for(final m in members) ListTile(
        dense:true,
        contentPadding:EdgeInsets.zero,
        leading:CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.12),child:Text(m.$1[0],style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.bold))),
        title:Text(m.$1,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),
        subtitle:Text(m.$2,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),
        trailing:Text(m.$3,style:const TextStyle(fontSize:18)),
      ),
    ]),
  );

  Widget _task(String title,int progress,int target,IconData icon)=>Container(
    margin:const EdgeInsets.only(bottom:8),
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(15),border:Border.all(color:NexoColors.cardBorder)),
    child:Row(children:[
      CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.12),child:Icon(icon,color:NexoColors.primary,size:19)),
      const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:12)),
        const SizedBox(height:6),
        LinearProgressIndicator(value:target==0?0:progress/target,minHeight:5,borderRadius:BorderRadius.circular(10)),
      ])),
      const SizedBox(width:10),
      Text('$progress/$target',style:TextStyle(color:progress>=target?NexoColors.success:Colors.white70,fontSize:10,fontWeight:FontWeight.bold)),
    ]),
  );

  Widget _action(BuildContext context,{required String title,required String subtitle,required IconData icon,required VoidCallback onTap})=>Container(
    margin:const EdgeInsets.only(top:8),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(17),border:Border.all(color:NexoColors.primary.withOpacity(.25))),
    child:ListTile(onTap:onTap,leading:CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.12),child:Icon(icon,color:NexoColors.primary)),title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(subtitle,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)),trailing:const Icon(Icons.chevron_left_rounded,color:Colors.white54)),
  );
}