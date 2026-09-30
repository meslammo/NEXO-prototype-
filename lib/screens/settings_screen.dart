import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';
import 'font_color_screen.dart';

class SettingsScreen extends StatefulWidget{const SettingsScreen({super.key});@override State<SettingsScreen> createState()=>_SettingsScreenState();}
class _SettingsScreenState extends State<SettingsScreen>{
  final display=TextEditingController(),bio=TextEditingController(),oldPass=TextEditingController(),newPass=TextEditingController(),confirm=TextEditingController();
  bool loading=true,saving=false,notifications=true,sound=true,vibration=true,showOnline=true,allowMessages=true,glow=true;
  String language='ar';
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final c in [display,bio,oldPass,newPass,confirm])c.dispose();super.dispose();}
  Future<void> load() async{try{final r=await context.read<ApiClient>().getJson('/account/settings');final u=r['user'] is Map?Map<String,dynamic>.from(r['user']):<String,dynamic>{};final p=r['preferences'] is Map?Map<String,dynamic>.from(r['preferences']):<String,dynamic>{};display.text=u['displayName']?.toString()??'';bio.text=u['bio']?.toString()??'';if(mounted)setState((){notifications=p['notificationsEnabled']!=false;sound=p['soundEnabled']!=false;vibration=p['vibrationEnabled']!=false;showOnline=p['showOnline']!=false;allowMessages=p['allowMessages']!=false;language=p['language']?.toString()??'ar';glow=u['glow']!=false;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  Future<void> save() async{setState(()=>saving=true);try{await context.read<ApiClient>().postJson('/account/settings',{'displayName':display.text.trim(),'bio':bio.text.trim(),'notificationsEnabled':notifications,'soundEnabled':sound,'vibrationEnabled':vibration,'showOnline':showOnline,'allowMessages':allowMessages,'language':language,'glow':glow});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('✅ تم حفظ الإعدادات')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()),backgroundColor:Colors.redAccent));}finally{if(mounted)setState(()=>saving=false);}}
  Future<void> changePassword() async{if(newPass.text.length<8||newPass.text!=confirm.text){msg('كلمة السر الجديدة غير صالحة');return;}try{await context.read<ApiClient>().postJson('/auth/change-password',{'oldPassword':oldPass.text,'newPassword':newPass.text});oldPass.clear();newPass.clear();confirm.clear();msg('✅ تم تغيير كلمة السر',true);}catch(e){msg(e.toString());}}
  void msg(String s,[bool ok=false])=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:ok?NexoColors.success:Colors.redAccent));
  InputDecoration dec(String h)=>InputDecoration(hintText:h,hintStyle:const TextStyle(color:NexoColors.textSecondary),filled:true,fillColor:NexoColors.card,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none));
  Widget sw(String t,String sub,bool v,ValueChanged<bool> f)=>SwitchListTile.adaptive(value:v,onChanged:f,activeColor:NexoColors.primary,title:Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(sub,style:const TextStyle(color:NexoColors.textSecondary,fontSize:10)));
  Widget group(String t,List<Widget> c)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:NexoColors.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:NexoColors.cardBorder)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.only(bottom:9),child:Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:15))),...c]));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoColors.background,
      appBar: AppBar(backgroundColor: NexoColors.background, title: const Text('Settings'), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                group('الحساب', [
                  TextField(controller: display, style: const TextStyle(color: Colors.white), decoration: dec('Display Name')),
                  const SizedBox(height: 8),
                  TextField(controller: bio, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: dec('Bio')),
                ]),
                group('المظهر والهوية', [
                  sw('Glow', 'وهج الاسم', glow, (v) => setState(() => glow = v)),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: NexoColors.primary),
                    title: const Text('Font Color', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('اختيار لون الاسم من المتجر', style: TextStyle(color: NexoColors.textSecondary, fontSize: 10)),
                    trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FontColorScreen())),
                  ),
                ]),
                group('الإشعارات', [
                  sw('Notifications', 'الإشعارات', notifications, (v) => setState(() => notifications = v)),
                  sw('Sound', 'الأصوات', sound, (v) => setState(() => sound = v)),
                  sw('Vibration', 'الاهتزاز', vibration, (v) => setState(() => vibration = v)),
                ]),
                group('الخصوصية', [
                  sw('Show Online', 'ظهور الحالة', showOnline, (v) => setState(() => showOnline = v)),
                  sw('Allow Messages', 'السماح بالرسائل', allowMessages, (v) => setState(() => allowMessages = v)),
                  ListTile(
                    leading: const Icon(Icons.language, color: NexoColors.primary),
                    title: const Text('Language', style: TextStyle(color: Colors.white)),
                    trailing: DropdownButton<String>(
                      value: language,
                      dropdownColor: NexoColors.card,
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) { if (v != null) setState(() => language = v); },
                    ),
                  ),
                ]),
                group('الأمان', [
                  TextField(controller: oldPass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: dec('Current Password')),
                  const SizedBox(height: 7),
                  TextField(controller: newPass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: dec('New Password')),
                  const SizedBox(height: 7),
                  TextField(controller: confirm, obscureText: true, style: const TextStyle(color: Colors.white), decoration: dec('Confirm New Password')),
                  const SizedBox(height: 7),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: changePassword, child: const Text('تغيير كلمة السر'))),
                  const SizedBox(height: 5),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: saving ? null : save, child: Text(saving ? 'جاري الحفظ...' : 'حفظ الإعدادات'))),
                  TextButton.icon(onPressed: () => context.read<AuthService>().logout(), icon: const Icon(Icons.logout, color: Colors.redAccent), label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent))),
                ]),
              ],
            ),
    );
  }
}