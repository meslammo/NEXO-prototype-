import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'realtime_service.dart';

class RoomVoiceService {
  final RealtimeService realtime;
  final ApiClient api;
  final String userId;
  final Map<String,RTCPeerConnection> _peers={};
  final Set<String> _remoteReady={};
  StreamSubscription<Map<String,dynamic>>? _signals;
  MediaStream? localStream;
  String? roomId;
  bool muted=false;

  RoomVoiceService(this.realtime,this.api,this.userId);

  Future<void> start(String room,List<String> peerIds) async {
    await stop();
    if(!NexoApiConfig.configured||userId.isEmpty)return;
    roomId=room;
    List<Map<String,dynamic>> iceServers=[];
    try{
      final r=await api.getJson('/rtc/config');
      final raw=r['iceServers'];
      if(raw is List) iceServers=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    }catch(_){}
    if(iceServers.isEmpty){
      try{
        final raw=jsonDecode(NexoApiConfig.iceServersJson);
        if(raw is List)iceServers=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      }catch(_){}
    }
    try{
      localStream=await navigator.mediaDevices.getUserMedia({'audio':true,'video':false});
      for(final t in localStream!.getAudioTracks())t.enabled=!muted;
    }catch(_){
      localStream=null;
      return;
    }
    _signals=realtime.events.listen(_onSignal);
    final unique=peerIds.where((id)=>id.isNotEmpty&&id!=userId).toSet().toList()..sort();
    for(final peer in unique){
      final offer=userId.compareTo(peer)<0;
      await _ensurePeer(peer,iceServers,offer:offer);
    }
  }

  Future<RTCPeerConnection> _ensurePeer(String peer,List<Map<String,dynamic>> ice,{bool offer=false}) async {
    final existing=_peers[peer];
    if(existing!=null)return existing;
    final pc=await createPeerConnection({'iceServers':ice});
    _peers[peer]=pc;
    pc.onIceCandidate=(c){
      if(c.candidate==null||roomId==null)return;
      realtime.sendSignal(peer,{'kind':'candidate','roomId':roomId,'candidate':{
        'candidate':c.candidate,'sdpMid':c.sdpMid,'sdpMLineIndex':c.sdpMLineIndex
      }});
    };
    if(localStream!=null){
      for(final t in localStream!.getAudioTracks()) await pc.addTrack(t,localStream!);
    }
    if(offer&&!_remoteReady.contains(peer)){
      _remoteReady.add(peer);
      final o=await pc.createOffer({'offerToReceiveAudio':1,'offerToReceiveVideo':0});
      await pc.setLocalDescription(o);
      realtime.sendSignal(peer,{'kind':'offer','roomId':roomId,'sdp':o.sdp});
    }
    return pc;
  }

  Future<void> _onSignal(Map<String,dynamic> event) async {
    if(event['type']!='signal'||roomId==null)return;
    final from=event['fromUserId']?.toString()??'';
    final payload=Map<String,dynamic>.from((event['payload'] as Map?)??const {});
    if(from.isEmpty||payload['roomId']?.toString()!=roomId)return;
    try{
      final pc=await _ensurePeer(from,const [],offer:false);
      final kind=payload['kind']?.toString();
      if(kind=='offer'){
        await pc.setRemoteDescription(RTCSessionDescription(payload['sdp']?.toString()??'','offer'));
        _remoteReady.add(from);
        final answer=await pc.createAnswer({'offerToReceiveAudio':1,'offerToReceiveVideo':0});
        await pc.setLocalDescription(answer);
        realtime.sendSignal(from,{'kind':'answer','roomId':roomId,'sdp':answer.sdp});
      }else if(kind=='answer'){
        await pc.setRemoteDescription(RTCSessionDescription(payload['sdp']?.toString()??'','answer'));
      }else if(kind=='candidate'){
        final c=Map<String,dynamic>.from((payload['candidate'] as Map?)??const {});
        await pc.addCandidate(RTCIceCandidate(c['candidate']?.toString(),c['sdpMid']?.toString(),c['sdpMLineIndex'] is int?c['sdpMLineIndex'] as int:null));
      }
    }catch(_){}
  }

  Future<void> setMuted(bool value) async {
    muted=value;
    for(final t in localStream?.getAudioTracks()??const <MediaStreamTrack>[])t.enabled=!muted;
  }

  Future<void> stop() async {
    await _signals?.cancel();
    _signals=null;
    for(final pc in _peers.values){try{await pc.close();}catch(_){}}
    _peers.clear();
    _remoteReady.clear();
    for(final t in localStream?.getAudioTracks()??const <MediaStreamTrack>[]){try{await t.stop();}catch(_){}}
    try{await localStream?.dispose();}catch(_){}
    localStream=null;
    roomId=null;
  }

  Future<void> dispose() async=>stop();
}
