import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/api_config.dart';
import 'realtime_service.dart';

class WebRtcCallService {
  final RealtimeService realtime;
  final StreamController<MediaStream> _remoteStreams = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get remoteStreams => _remoteStreams.stream;

  RTCPeerConnection? _pc;
  MediaStream? localStream;
  StreamSubscription? _signals;
  String? _peerId;
  bool _video = false;

  WebRtcCallService(this.realtime);

  Future<void> listenForIncoming(String peerId) async {
    _peerId = peerId;
    if (_signals != null) return;
    _signals = realtime.events.listen((event) async {
      if (event['type'] != 'signal') return;
      final payload = Map<String, dynamic>.from((event['payload'] as Map?) ?? const {});
      final kind = payload['kind']?.toString();
      // The backend already routes the signal to this authenticated socket.
      // Do not compare the sender UUID with a username-based peer reference.

      try {
        if (kind == 'offer') {
          final video = payload['video'] == true;
          await _ensurePeer(peerId, video: video);
          await _pc!.setRemoteDescription(
            RTCSessionDescription(payload['sdp']?.toString(), 'offer'),
          );
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          realtime.sendSignal(peerId, {
            'kind': 'answer',
            'sdp': answer.sdp,
            'video': video,
          });
        } else if (kind == 'answer' && _pc != null) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(payload['sdp']?.toString(), 'answer'),
          );
        } else if (kind == 'candidate' && _pc != null) {
          final c = Map<String, dynamic>.from((payload['candidate'] as Map?) ?? const {});
          await _pc!.addCandidate(
            RTCIceCandidate(
              c['candidate']?.toString(),
              c['sdpMid']?.toString(),
              c['sdpMLineIndex'] is int ? c['sdpMLineIndex'] as int : null,
            ),
          );
        }
      } catch (_) {
        // Signaling errors must not crash the chat screen.
      }
    });
  }

  Future<void> start(String peerId, {required bool video}) async {
    await listenForIncoming(peerId);
    await _ensurePeer(peerId, video: video);
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': video ? 1 : 0,
    });
    await _pc!.setLocalDescription(offer);
    realtime.sendSignal(peerId, {
      'kind': 'offer',
      'sdp': offer.sdp,
      'video': video,
    });
  }

  Future<void> _ensurePeer(String peerId, {required bool video}) async {
    if (_pc != null) {
      _peerId = peerId;
      _video = video;
      return;
    }

    _peerId = peerId;
    _video = video;
    final rawServers = jsonDecode(NexoApiConfig.iceServersJson);
    final servers = (rawServers as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    _pc = await createPeerConnection({'iceServers': servers});
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || _peerId == null) return;
      realtime.sendSignal(_peerId!, {
        'kind': 'candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams.add(event.streams.first);
      }
    };

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    for (final track in localStream!.getTracks()) {
      await _pc!.addTrack(track, localStream!);
    }
  }

  Future<void> stop() async {
    await _signals?.cancel();
    _signals = null;
    for (final track in localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await localStream?.dispose();
    localStream = null;
    await _pc?.close();
    _pc = null;
    _peerId = null;
    _video = false;
  }

  Future<void> dispose() async {
    await stop();
    await _remoteStreams.close();
  }
}