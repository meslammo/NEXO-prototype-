import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final id = TextEditingController();
  final pass = TextEditingController();
  final user = TextEditingController();
  final email = TextEditingController();
  final name = TextEditingController();
  final regPass = TextEditingController();
  final confirm = TextEditingController();

  int tab = 0;
  bool showPass = false;
  bool showRegPass = false;
  bool showConfirm = false;

  @override
  void dispose() {
    for (final c in [id, pass, user, email, name, regPass, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void msg(String text, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: error ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  String authError(Object error) {
    final m = error.toString();
    if (m.contains('API 401') || m.contains('INVALID_CREDENTIALS')) {
      return 'اسم المستخدم أو البريد الإلكتروني أو كلمة السر غير صحيحة';
    }
    if (m.contains('API 403') || m.contains('ACCOUNT_BANNED')) return 'الحساب موقوف حاليًا';
    if (m.contains('API 409') || m.contains('USERNAME_OR_EMAIL_EXISTS') || m.contains('ACCOUNT_EXISTS')) {
      return 'اسم المستخدم أو البريد الإلكتروني مستخدم بالفعل';
    }
    if (m.contains('INVALID_ACCOUNT_INPUT')) return 'راجع اسم المستخدم والبريد الإلكتروني وكلمة السر';
    if (m.contains('API 400') || m.contains('LOGIN_REQUIRED')) return 'أكمل بيانات الدخول المطلوبة';
    if (m.contains('No session token')) return 'تم تسجيل الدخول لكن تعذر إنشاء الجلسة';
    if (m.contains('TimeoutException') || m.contains('timed out')) return 'الاتصال بسيرفر NEXO استغرق وقتًا طويلًا';
    if (m.contains('SocketException') || m.contains('Failed host lookup') || m.contains('ClientException')) {
      return 'تعذر الاتصال بسيرفر NEXO';
    }
    return 'حدث خطأ غير متوقع. جرّب مرة أخرى';
  }

  Future<void> loginNow() async {
    if (id.text.trim().isEmpty || pass.text.isEmpty) {
      msg('اكتب اسم المستخدم أو البريد الإلكتروني وكلمة السر');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await context.read<AuthService>().login(id.text.trim(), pass.text);
    } catch (e) {
      msg(authError(e));
    }
  }

  Future<void> registerNow() async {
    final username = user.text.trim();
    final mail = email.text.trim().toLowerCase();
    final displayName = name.text.trim().isEmpty ? username : name.text.trim();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(username)) {
      msg('اسم المستخدم: من 3 إلى 24 حرفًا، أرقام أو _ فقط');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(mail)) {
      msg('اكتب بريدًا إلكترونيًا صحيحًا');
      return;
    }
    if (regPass.text.length < 8) {
      msg('كلمة السر لازم تكون 8 أحرف على الأقل');
      return;
    }
    if (regPass.text != confirm.text) {
      msg('تأكيد كلمة السر غير مطابق');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await context.read<AuthService>().register(
        username: username,
        email: mail,
        displayName: displayName,
        password: regPass.text,
      );
    } catch (e) {
      msg(authError(e));
    }
  }

  Future<void> guestNow() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await context.read<AuthService>().guest();
    } catch (e) {
      msg(authError(e));
    }
  }

  void fillQaAccount() {
    setState(() {
      tab = 0;
      id.text = 'nexo_demo';
      pass.text = '12345678';
    });
    msg('تم تعبئة حساب الاختبار', error: false);
  }

  InputDecoration decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: NexoColors.textSecondary, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: NexoColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: NexoColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: NexoColors.primary.withOpacity(.16)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: NexoColors.primary.withOpacity(.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: NexoColors.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    );
  }

  Widget field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool password = false,
    bool visible = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    TextInputAction? action,
    Iterable<String>? autofillHints,
    VoidCallback? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        obscureText: password && !visible,
        keyboardType: keyboardType,
        textInputAction: action,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !password,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: decoration(
          hint,
          icon,
          suffix: password
              ? IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: NexoColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget qaCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexoColors.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: NexoColors.primary.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: NexoColors.primary),
              SizedBox(width: 9),
              Expanded(
                child: Text('حساب QA جاهز للتجربة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SelectableText(
            'Username: nexo_demo\nPassword: 12345678',
            textAlign: TextAlign.left,
            style: TextStyle(color: NexoColors.textSecondary, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: fillQaAccount,
            icon: const Icon(Icons.input_rounded),
            label: const Text('تعبئة تلقائية'),
          ),
        ],
      ),
    );
  }

  Widget tabButton(String label, int value) {
    final active = tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? NexoColors.primary.withOpacity(.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : NexoColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final busy = auth.busy;

    return Scaffold(
      backgroundColor: NexoColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: NexoColors.primary.withOpacity(.28),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SvgPicture.asset(
                        'assets/nexo/logo_icon.svg',
                        fit: BoxFit.cover,
                        semanticsLabel: 'NEXO',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'NEXO',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Social World • Chat • Games • Store',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: NexoColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: NexoColors.card,
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: NexoColors.primary.withOpacity(.10)),
                      ),
                      child: Row(
                        children: [
                          tabButton('تسجيل الدخول', 0),
                          tabButton('إنشاء حساب', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: NexoColors.card,
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: NexoColors.primary.withOpacity(.10)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: tab == 0
                            ? Column(
                                key: const ValueKey('login'),
                                children: [
                                  field(
                                    id,
                                    'اسم المستخدم أو البريد الإلكتروني',
                                    Icons.person_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    action: TextInputAction.next,
                                  ),
                                  field(
                                    pass,
                                    'كلمة السر',
                                    Icons.lock_outline_rounded,
                                    password: true,
                                    visible: showPass,
                                    onToggle: () => setState(() => showPass = !showPass),
                                    keyboardType: TextInputType.visiblePassword,
                                    action: TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    onSubmitted: busy ? null : loginNow,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: busy ? null : loginNow,
                                      child: Text(busy ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  qaCard(),
                                ],
                              )
                            : Column(
                                key: const ValueKey('register'),
                                children: [
                                  field(
                                    user,
                                    'اسم المستخدم',
                                    Icons.alternate_email_rounded,
                                    action: TextInputAction.next,
                                    autofillHints: const [AutofillHints.newUsername],
                                  ),
                                  field(
                                    name,
                                    'اسم العرض',
                                    Icons.badge_outlined,
                                    action: TextInputAction.next,
                                  ),
                                  field(
                                    email,
                                    'البريد الإلكتروني',
                                    Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    action: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  field(
                                    regPass,
                                    'كلمة السر',
                                    Icons.lock_outline_rounded,
                                    password: true,
                                    visible: showRegPass,
                                    onToggle: () => setState(() => showRegPass = !showRegPass),
                                    keyboardType: TextInputType.visiblePassword,
                                    action: TextInputAction.next,
                                    autofillHints: const [AutofillHints.newPassword],
                                  ),
                                  field(
                                    confirm,
                                    'تأكيد كلمة السر',
                                    Icons.verified_user_outlined,
                                    password: true,
                                    visible: showConfirm,
                                    onToggle: () => setState(() => showConfirm = !showConfirm),
                                    keyboardType: TextInputType.visiblePassword,
                                    action: TextInputAction.done,
                                    autofillHints: const [AutofillHints.newPassword],
                                    onSubmitted: busy ? null : registerNow,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: busy ? null : registerNow,
                                      child: Text(busy ? 'جارٍ إنشاء الحساب...' : 'إنشاء حساب'),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : guestNow,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('دخول كضيف للاختبار'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'NEXO QA • Online build',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: NexoColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
