import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'API $statusCode: $message';
}

class ApiClient {
  String? token;
  Uri _uri(String path) {
    final base = NexoApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse(base + '/' + path.replaceFirst(RegExp(r'^/+'), ''));
  }
  Map<String,String> _headers() => {
    'content-type':'application/json',
    if (token != null && token!.isNotEmpty) 'authorization':'Bearer $token',
  };
  Future<Map<String,dynamic>> getJson(String path,{Duration timeout=const Duration(seconds:5)}) async {
    final r=await http.get(_uri(path),headers:_headers()).timeout(timeout);
    return _decode(r);
  }
  Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{Duration timeout=const Duration(seconds:7)}) async {
    final r=await http.post(_uri(path),headers:_headers(),body:jsonEncode(body)).timeout(timeout);
    return _decode(r);
  }
  Map<String,dynamic> _decode(http.Response r) {
    dynamic data;
    try { data=r.body.isEmpty?<String,dynamic>{}:jsonDecode(r.body); } catch (_) { data={'error':r.body}; }
    if(r.statusCode<200||r.statusCode>=300) {
      final message=data is Map ? (data['error'] ?? data).toString() : data.toString();
      throw ApiException(r.statusCode,message);
    }
    return data is Map<String,dynamic> ? data : <String,dynamic>{'data':data};
  }
}