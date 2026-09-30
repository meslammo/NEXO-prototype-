import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';

class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_LoginScreenState();}
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin{
  late final TabController tabs;
  final id=TextEditingController(),pass=TextEditingController(),user=TextEditingController(),email=TextEditingController(),name=TextEditingController(),regPass=TextEditingController(),confirm=TextEditingController();
  @override void initState(){super.initState();tabs=TabController(length:2,vsync:this);}
  @override void dispose(){tabs.dispose();for(final c in [id,pass,user,email,name,regPass,confirm]){c.dispose();}super.dispose();}
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:Colors.redAccent));
  Future<void> loginNow() async{if(id.text.trim().isEmpty||pass.text.isEmpty){msg('اكتب بيانات الدخول');return;}try{await context.read<AuthService>().login(id.text,pass.text);}catch(e){msg(e.toString());}}
  Future<void> registerNow() async{if(user.text.trim().length<3||email.text.trim().isEmpty){msg('راجع بيانات الحساب');return;}if(regPass.text.length<8||regPass.text!=confirm.text){msg('كلمة السر لازم تكون 8 أحرف ومتطابقة');return;}try{await context.read<AuthService>().register(username:user.text,email:email.text,displayName:name.text,password:regPass.text);}catch(e){msg(e.toString());}}
  Future<void> guestNow() async{try{await context.read<AuthService>().guest();}catch(e){msg(e.toString());}}
  InputDecoration dec(String h,IconData i)=>InputDecoration(hintText:h,hintStyle:const TextStyle(color:NexoColors.textSecondary),prefixIcon:Icon(i,color:NexoColors.primary),filled:true,fillColor:NexoColors.card,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(15)),borderSide:BorderSide.none));
  Widget f(TextEditingController c,String h,IconData i,{bool obscure=false,TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:9),child:TextField(controller:c,obscureText:obscure,keyboardType:type,style:const TextStyle(color:Colors.white),decoration:dec(h,i)));
  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthService>().busy;
    return Scaffold(
      backgroundColor: NexoColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Icon(Icons.public, color: NexoColors.primary, size: 72),
                  const SizedBox(height: 8),
                  const Text('NEXO', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const Text('Social World • Chat • Games • Store', style: TextStyle(color: NexoColors.textSecondary)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        TabBar(controller: tabs, tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'إنشاء حساب')]),
                        AnimatedBuilder(
                          animation: tabs,
                          builder: (c, _) {
                            if (tabs.index == 0) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    f(id, 'Username أو Email', Icons.person_outline),
                                    f(pass, 'Password', Icons.lock_outline, obscure: true),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(onPressed: busy ? null : loginNow, child: Text(busy ? 'جارٍ الدخول...' : 'تسجيل الدخول')),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  f(user, 'Username', Icons.alternate_email),
                                  f(name, 'Display Name', Icons.person_outline),
                                  f(email, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
                                  f(regPass, 'Password', Icons.lock_outline, obscure: true),
                                  f(confirm, 'Confirm Password', Icons.lock_reset, obscure: true),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(onPressed: busy ? null : registerNow, child: Text(busy ? 'جارٍ الإنشاء...' : 'إنشاء حساب')),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(onPressed: busy ? null : guestNow, icon: const Icon(Icons.person_outline), label: const Text('دخول كضيف للاختبار')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}