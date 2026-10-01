import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';

class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_LoginScreenState();}
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin{
  late final TabController tabs;
  final id=TextEditingController(),pass=TextEditingController(),user=TextEditingController(),email=TextEditingController(),name=TextEditingController(),regPass=TextEditingController(),confirm=TextEditingController();
  @override void initState(){super.initState();tabs=TabController(length:2,vsync:this);}
  bool showPass=false,showRegPass=false,showConfirm=false;
  @override void dispose(){tabs.dispose();for(final c in [id,pass,user,email,name,regPass,confirm]){c.dispose();}super.dispose();}
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:Colors.redAccent));
  String authError(Object e){
    final m=e.toString();
    if(m.contains('API 401')||m.contains('INVALID_CREDENTIALS')) return 'اسم المستخدم أو كلمة السر غير صحيحة';
    if(m.contains('API 403')||m.contains('ACCOUNT_BANNED')) return 'الحساب موقوف';
    if(m.contains('No session token')) return 'تعذر إنشاء جلسة الدخول';
    return m;
  }
  Future<void> loginNow() async{if(id.text.trim().isEmpty||pass.text.isEmpty){msg('اكتب بيانات الدخول');return;}FocusManager.instance.primaryFocus?.unfocus();try{await context.read<AuthService>().login(id.text.trim(),pass.text);}catch(e){msg(authError(e));}}
  Future<void> registerNow() async{if(user.text.trim().length<3||email.text.trim().isEmpty){msg('راجع بيانات الحساب');return;}if(regPass.text.length<8||regPass.text!=confirm.text){msg('كلمة السر لازم تكون 8 أحرف ومتطابقة');return;}try{await context.read<AuthService>().register(username:user.text,email:email.text,displayName:name.text,password:regPass.text);}catch(e){msg(e.toString());}}
  Future<void> guestNow() async{try{await context.read<AuthService>().guest();}catch(e){msg(e.toString());}}
  InputDecoration dec(String h,IconData i)=>InputDecoration(hintText:h,hintStyle:const TextStyle(color:NexoColors.textSecondary),prefixIcon:Icon(i,color:NexoColors.primary),filled:true,fillColor:NexoColors.card,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(15)),borderSide:BorderSide.none));
  Widget f(TextEditingController c,String h,IconData? i,{bool obscure=false,bool visible=false,VoidCallback? onToggle,TextInputType? type})=>Container(
    margin:const EdgeInsets.only(bottom:10),
    padding:const EdgeInsets.symmetric(horizontal:12,vertical:2),
    decoration:BoxDecoration(
      color:NexoColors.surface,
      borderRadius:BorderRadius.circular(15),
      border:Border.all(color:NexoColors.primary.withOpacity(.20)),
    ),
    child:TextField(
      controller:c,
      obscureText:obscure && !visible,
      keyboardType:type,
      style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600),
      decoration:InputDecoration(
        hintText:h,
        hintStyle:const TextStyle(color:NexoColors.textSecondary,fontWeight:FontWeight.w500),
        prefixIcon:i==null ? null : Icon(i,color:NexoColors.primary),
        suffixIcon: obscure ? IconButton(
          tooltip: visible ? 'إخفاء كلمة السر' : 'إظهار كلمة السر',
          onPressed:onToggle,
          icon:Icon(visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,color:NexoColors.primary),
        ) : null,
        border:InputBorder.none,
        enabledBorder:InputBorder.none,
        focusedBorder:InputBorder.none,
        contentPadding:const EdgeInsets.symmetric(vertical:14),
      ),
    ),
  );
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
                                    f(pass, 'Password', null, obscure: true, visible: showPass, onToggle:()=>setState(()=>showPass=!showPass)),
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
                                  f(regPass, 'Password', null, obscure: true, visible: showRegPass, onToggle:()=>setState(()=>showRegPass=!showRegPass)),
                                  f(confirm, 'Confirm Password', null, obscure: true, visible: showConfirm, onToggle:()=>setState(()=>showConfirm=!showConfirm)),
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