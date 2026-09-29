import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/social_engine.dart';
import '../theme/nexo_theme.dart';
import 'chat_screen.dart';
import 'games_screen.dart';
import 'our_club_screen.dart';

enum MissionGroup { daily, weekly, tribe }

class NexoMission {
  final String id,title,subtitle,action;
  final MissionGroup group;
  final int target,reward;
  final IconData icon;
  const NexoMission({required this.id,required this.title,required this.subtitle,required this.group,required this.target,required this.reward,required this.icon,required this.action});
}

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  static const missions=<NexoMission>[
    NexoMission(id:'d1',title:'أرسل 5 رسائل',subtitle:'تفاعل مع أصحابك اليوم',group:MissionGroup.daily,target:5,reward:40,icon:Icons.chat_bubble_outline,action:'chat'),
    NexoMission(id:'d2',title:'أرسل هدية',subtitle:'شارك هدية واحدة اليوم',group:MissionGroup.daily,target:1,reward:60,icon:Icons.card_giftcard_outlined,action:'chat'),
    NexoMission(id:'d3',title:'استخدم 3 إيموجي',subtitle:'عبّر عن نفسك في الشات',group:MissionGroup.daily,target:3,reward:30,icon:Icons.emoji_emotions_outlined,action:'chat'),
    NexoMission(id:'d4',title:'العب جولة',subtitle:'شارك في لعبة اجتماعية',group:MissionGroup.daily,target:1,reward:50,icon:Icons.sports_esports_outlined,action:'games'),
    NexoMission(id:'d5',title:'نشاط صوتي',subtitle:'شارك في مكالمة أو غرفة',group:MissionGroup.daily,target:1,reward:75,icon:Icons.record_voice_over_outlined,action:'tribe'),
    NexoMission(id:'w1',title:'50 رسالة هذا الأسبوع',subtitle:'تفاعل باستمرار مع المجتمع',group:MissionGroup.weekly,target:50,reward:250,icon:Icons.forum_outlined,action:'chat'),
    NexoMission(id:'w2',title:'5 هدايا هذا الأسبوع',subtitle:'شارك الدعم مع الأصدقاء',group:MissionGroup.weekly,target:5,reward:300,icon:Icons.redeem_outlined,action:'chat'),
    NexoMission(id:'w3',title:'3 جولات ألعاب',subtitle:'ارفع نشاطك الأسبوعي',group:MissionGroup.weekly,target:3,reward:220,icon:Icons.emoji_events_outlined,action:'games'),
    NexoMission(id:'w4',title:'500 نقطة نشاط',subtitle:'اجمع نقاط NEXO من تفاعلك',group:MissionGroup.weekly,target:500,reward:400,icon:Icons.bolt_outlined,action:'tribe'),
    NexoMission(id:'t1',title:'3 رسائل داخل الـTribe',subtitle:'حافظ على نشاط القبيلة',group:MissionGroup.tribe,target:3,reward:80,icon:Icons.groups_outlined,action:'tribe'),
    NexoMission(id:'t2',title:'هدية لعضو',subtitle:'شارك هدية مع أحد الأعضاء',group:MissionGroup.tribe,target:1,reward:100,icon:Icons.volunteer_activism_outlined,action:'chat'),
    NexoMission(id:'t3',title:'نشاط صوتي للقبيلة',subtitle:'شارك في نشاط صوتي',group:MissionGroup.tribe,target:1,reward:120,icon:Icons.mic_none_rounded,action:'tribe'),
    NexoMission(id:'t4',title:'دعوة عضو جديد',subtitle:'كبّر مجتمعك',group:MissionGroup.tribe,target:1,reward:150,icon:Icons.person_add_alt_1_outlined,action:'tribe'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:NexoColors.background,
      appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('Missions'),centerTitle:true),
      body:Consumer<SocialEngine>(
        builder:(context,social,_){
          final daily=_daily(social),weekly=_weekly(social);
          return ListView(
            padding:const EdgeInsets.fromLTRB(16,8,16,28),
            children:[
              _hero(social),
              const SizedBox(height:16),
              _group(context,'المهام اليومية',Icons.today_outlined,MissionGroup.daily,(m)=>_dailyProgress(m,daily)),
              const SizedBox(height:18),
              _group(context,'المهام الأسبوعية',Icons.calendar_month_outlined,MissionGroup.weekly,(m)=>_weeklyProgress(m,weekly)),
              const SizedBox(height:18),
              _group(context,'مهام الـTribe اليومية',Icons.groups_rounded,MissionGroup.tribe,(m)=>_tribeProgress(m,social)),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(SocialEngine s)=>Container(
    padding:const EdgeInsets.all(18),
    decoration:BoxDecoration(
      gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF24194D),Color(0xFF12152C)]),
      borderRadius:BorderRadius.circular(22),border:Border.all(color:NexoColors.primary.withOpacity(.28))),
    child:Row(children:[
      Container(width:58,height:58,decoration:BoxDecoration(shape:BoxShape.circle,color:NexoColors.primary.withOpacity(.16)),child:const Icon(Icons.assignment_turned_in_outlined,color:NexoColors.primary,size:30)),
      const SizedBox(width:14),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('NEXO Missions',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w800)),
        const SizedBox(height:4),
        Text('اليومي + الأسبوعي + الـTribe',style:TextStyle(color:Colors.white.withOpacity(.65),fontSize:12)),
        const SizedBox(height:8),
        Text('نشاطك اليوم: ' + s.getDailyScore().toString() + ' نقطة',style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w700,fontSize:12)),
      ])),
    ]),
  );

  int _count(SocialEngine s,String type,{int days=1}){
    final now=DateTime.now(),start=now.subtract(Duration(days:days));
    return s.activities.where((a){
      final d=a['timestamp'];
      return d is DateTime && d.isAfter(start) && a['type']==type;
    }).length;
  }

  Map<String,int> _daily(SocialEngine s)=>{
    'chat':_count(s,'chat'),
    'gift':_count(s,'gift_send'),
    'emoji':_count(s,'emoji_use'),
    'game':_count(s,'game_win'),
    'voice':_count(s,'voice_call')+_count(s,'video_call'),
  };

  Map<String,int> _weekly(SocialEngine s)=>{
    'chat':_count(s,'chat',days:7),
    'gift':_count(s,'gift_send',days:7),
    'game':_count(s,'game_win',days:7),
    'score':s.getWeeklyScore(),
  };

  int _dailyProgress(NexoMission m,Map<String,int> p){
    final k=m.id=='d1'?'chat':m.id=='d2'?'gift':m.id=='d3'?'emoji':m.id=='d4'?'game':'voice';
    return (p[k]??0).clamp(0,m.target);
  }

  int _weeklyProgress(NexoMission m,Map<String,int> p){
    final k=m.id=='w1'?'chat':m.id=='w2'?'gift':m.id=='w3'?'game':'score';
    return (p[k]??0).clamp(0,m.target);
  }

  int _tribeProgress(NexoMission m,SocialEngine s){
    if(m.id=='t1') return _count(s,'chat').clamp(0,m.target);
    if(m.id=='t2') return _count(s,'gift_send').clamp(0,m.target);
    if(m.id=='t3') return (_count(s,'voice_call')+_count(s,'video_call')).clamp(0,m.target);
    return 0;
  }

  Widget _group(BuildContext context,String title,IconData icon,MissionGroup group,int Function(NexoMission) progress){
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(icon,color:NexoColors.primary,size:20),const SizedBox(width:8),Text(title,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))]),
      const SizedBox(height:10),
      ...missions.where((m)=>m.group==group).map((m)=>_tile(context,m,progress(m))),
    ]);
  }

  Widget _tile(BuildContext context,NexoMission m,int progress)=>Container(
    margin:const EdgeInsets.only(bottom:10),
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:progress>=m.target?NexoColors.success.withOpacity(.45):NexoColors.cardBorder)),
    child:Row(children:[
      CircleAvatar(backgroundColor:NexoColors.primary.withOpacity(.13),child:Icon(m.icon,color:NexoColors.primary)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(m.title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),
        const SizedBox(height:3),
        Text(m.subtitle,style:const TextStyle(color:NexoColors.textSecondary,fontSize:11)),
        const SizedBox(height:8),
        LinearProgressIndicator(value:m.target==0?0:progress/m.target,minHeight:6,borderRadius:BorderRadius.circular(10)),
        const SizedBox(height:5),
        Text(progress.toString() + '/' + m.target.toString() + '  •  +' + m.reward.toString() + ' Gems',style:TextStyle(color:progress>=m.target?NexoColors.success:NexoColors.textSecondary,fontSize:10,fontWeight:FontWeight.w600)),
      ])),
      const SizedBox(width:8),
      TextButton(onPressed:()=>_go(context,m),child:Text(progress>=m.target?'مكتملة':'ابدأ')),
    ]),
  );

  Future<void> _go(BuildContext context,NexoMission m) async {
    if(m.action=='chat'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChatScreen()));
    }else if(m.action=='games'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>const GamesScreen()));
    }else{
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>const OurClubScreen()));
    }
  }
}
