import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import '../theme/nexo_theme.dart';

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});
  @override State<LeaderboardsScreen> createState()=>_LeaderboardsScreenState();
}
class _LeaderboardsScreenState extends State<LeaderboardsScreen>{
  final types=const [('wealth','Wealth','💎'),('charm','Charm','✨'),('gifts','Gifts','🎁'),('games','Games','🎮'),('hosts','Hosts','🎙️')];
  String type='wealth'; List<Map<String,dynamic>> rows=[]; bool loading=true; Timer? timer;
  @override void initState(){super.initState();load();timer=Timer.periodic(const Duration(seconds:20),(_)=>load());}
  @override void dispose(){timer?.cancel();super.dispose();}
  Future<void> load() async{
    if(!NexoApiConfig.configured){if(mounted)setState(()=>loading=false);return;}
    try{
      final r=await context.read<ApiClient>().getJson('/leaderboards?type='+type+'&limit=20');
      final raw=r['items']??r['data'];
      if(raw is List&&mounted)setState((){rows=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();loading=false;});
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  String score(Map<String,dynamic> x){
    final n=(x['score'] as num?)?.toInt()??0;
    if(type=='wealth')return n.toString()+' 💎';
    if(type=='gifts')return n.toString()+' gifts';
    if(type=='hosts')return n.toString()+' rooms';
    return n.toString();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:NexoColors.background,
    appBar:AppBar(backgroundColor:NexoColors.background,title:const Text('NEXO Leaderboards'),centerTitle:true),
    body:Column(children:[
      SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.fromLTRB(12,10,12,6),child:Row(children:types.map((t)=>Padding(
        padding:const EdgeInsetsDirectional.only(end:7),
        child:ChoiceChip(label:Text(t.$3+' '+t.$2),selected:type==t.$1,onSelected:(_){setState(()=>type=t.$1);load();}),
      )).toList())),
      Expanded(child:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
        onRefresh:load,
        child:ListView.builder(
          padding:const EdgeInsets.all(12),itemCount:rows.length,
          itemBuilder:(_,i){
            final x=rows[i],rank=(x['rank'] as num?)?.toInt()??i+1;
            final name=x['displayName']?.toString()??x['username']?.toString()??'NEXO Player';
            return Container(
              margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),
              decoration:BoxDecoration(
                gradient:rank<=3?const LinearGradient(colors:[Color(0xFF271D4C),Color(0xFF132C43)]):null,
                color:rank<=3?null:NexoColors.card,borderRadius:BorderRadius.circular(18),
                border:Border.all(color:rank<=3?NexoColors.gold.withOpacity(.30):NexoColors.cardBorder),
              ),
              child:Row(children:[
                SizedBox(width:38,child:Text('#$rank',textAlign:TextAlign.center,style:TextStyle(color:rank<=3?NexoColors.gold:Colors.white54,fontWeight:FontWeight.w900,fontSize:16))),
                CircleAvatar(radius:24,backgroundColor:NexoColors.primary.withOpacity(.12),child:Text(name.isEmpty?'?':name.substring(0,1).toUpperCase(),style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900))),
                const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
                  const SizedBox(height:3),
                  Text('@'+(x['username']?.toString()??''),style:const TextStyle(color:NexoColors.textSecondary,fontSize:9)),
                ])),
                Text(score(x),style:const TextStyle(color:NexoColors.primary,fontWeight:FontWeight.w900,fontSize:11)),
              ]),
            );
          },
        ),
      )),
    ]),
  );
}
