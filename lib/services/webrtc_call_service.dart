import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/api_config.dart';
import 'realtime_service.dart';

class WebRtcCallService {
  final RealtimeService realtime;
  final StreamController<MediaStream> _remoteStreams=StreamController.broadcast();
  Stream<MediaStream> get remoteStreams=>_remoteStreams.stream;
  RTCPeerConnection? _pc;
  MediaStream? localStream;
  StreamSubscription? _signals;
  WebRtcCallService(this.realtime);

  Future<void> start(String peerId,{required bool video}) async {
    await stop();
    final servers=(jsonDecode(NexoApiConfig.iceServersJson) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    _pc=await createPeerConnection({'iceServers':servers});
    _pc!.onIceCandidate=(c){if(c.candidate==null)return;realtime.sendSignal(peerId,{'kind':'candidate','candidate':{'candidate':c.candidate,'sdpMid':c.sdpMid,'sdpMLineIndex':c.sdpMLineIndex}});};
    _pc!.onTrack=(event){if(event.streams.isNotEmpty)_remoteStreams.add(event.streams.first);};
    localStream=await navigator.mediaDevices.getUserMedia({'audio':true,'video':video?{'facingMode':'user'}:false});
    for(final track in localStream!.getTracks()){await _pc!.addTrack(track,localStream!);}
    _signals=realtime.events.listen((event) async {
      if(event['type']!='signal')return;
      final payload=Map<String,dynamic>.from(event['payload'] as Map);
      final kind=payload['kind']?.toString();
      if(kind=='offer'){
        await _pc!.setRemoteDescription(RTCSessionDescription(payload['sdp'].toString(),'offer'));
        final answer=await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        realtime.sendSignal(peerId,{'kind':'answer','sdp':answer.sdp});
      }else if(kind=='answer'){
        await _pc!.setRemoteDescription(RTCSessionDescription(payload['sdp'].toString(),'answer'));
      }else if(kind=='candidate'){
        final c=Map<String,dynamic>.from(payload['candidate'] as Map);
        await _pc!.addCandidate(RTCIceCandidate(c['candidate'],c['sdpMid'],c['sdpMLineIndex']));
      }
    });
    final offer=await _pc!.createOffer({'offerToReceiveAudio':1,'offerToReceiveVideo':video?1:0});
    await _pc!.setLocalDescription(offer);
    realtime.sendSignal(peerId,{'kind':'offer','sdp':offer.sdp});
  }
  Future<void> stop() async {
    await _signals?.cancel();_signals=null;
    for(final t in localStream?.getTracks() ?? <MediaStreamTrack>[]){await t.stop();}
    await localStream?.dispose();localStream=null;await _pc?.close();_pc=null;
  }
  Future<void> dispose() async {await stop();await _remoteStreams.close();}
}