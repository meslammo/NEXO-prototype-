import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/nexo_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  final id = TextEditingController();
  final pass = TextEditingController();
  final user = TextEditingController();
  final email = TextEditingController();
  final name = TextEditingController();
  final regPass = TextEditingController();
  final confirm = TextEditingController();

  bool showPass = false;
  bool showRegPass = false;
  bool showConfirm = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
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
          content: Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: error ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String authError(Object error) {
    final m = error.toString();
    if (m.contains('API 401') || m.contains('INVALID_CREDENTIALS')) {
      return 'اسم المستخدم أو البريد الإلكتروني أو كلمة السر غير صحيحة';
    }
    if (m.contains('API 403') || m.contains('ACCOUNT_BANNED')) {
      return 'الحساب موقوف حاليًا';
    }
    if (m.contains('API 409') ||
        m.contains('USERNAME_OR_EMAIL_EXISTS') ||
        m.contains('ACCOUNT_EXISTS')) {
      return 'اسم المستخدم أو البريد الإلكتروني مستخدم بالفعل';
    }
    if (m.contains('INVALID_ACCOUNT_INPUT')) {
      return 'راجع اسم المستخدم والبريد الإلكتروني وكلمة السر';
    }
    if (m.contains('API 400') || m.contains('LOGIN_REQUIRED')) {
      return 'أكمل بيانات الدخول المطلوبة';
    }
    if (m.contains('No session token')) {
      return 'تم تسجيل الدخول لكن تعذر إنشاء الجلسة';
    }
    if (m.contains('TimeoutException') || m.contains('timed out')) {
      return 'الاتصال بالسيرفر استغرق وقتًا طويلًا. جرّب مرة أخرى';
    }
    if (m.contains('SocketException') ||
        m.contains('Failed host lookup') ||
        m.contains('ClientException')) {
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
      await context.read<AuthService>().login(
            id.text.trim(),
            pass.text,
          );
    } catch (e) {
      msg(authError(e));
    }
  }

  Future<void> registerNow() async {
    final username = user.text.trim();
    final mail = email.text.trim();
    final displayName = name.text.trim().isEmpty ? username : name.text.trim();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(username)) {
      msg('اسم المستخدم: 3–24 حرفًا، أرقام أو _ فقط');
      return;
    }

    if (!RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(mail)) {
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
      id.text = 'nexo_demo';
      pass.text = '12345678';
    });
    msg('تم وضع بيانات حساب الاختبار', error: false);
  }

  InputDecoration fieldDecoration(
    String hint,
    IconData? icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: NexoColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon:
          icon == null ? null : Icon(icon, color: NexoColors.primary),
      suffixIcon: suffix,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 15,
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    bool password = false,
    bool visible = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    VoidCallback? onEditingComplete,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NexoColors.primary.withOpacity(.20),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: password && !visible,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !password,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        validator: validator,
        onEditingComplete: onEditingComplete,
        decoration: fieldDecoration(
          hint,
          icon,
          suffix: password
              ? IconButton(
                  tooltip: visible ? 'إخفاء كلمة السر' : 'إظهار كلمة السر',
                  onPressed: onToggle,
                  icon: Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: NexoColors.primary.withOpacity(.08),
        border: Border.all(
          color: NexoColors.primary.withOpacity(.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            color: NexoColors.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'حساب اختبار جاهز للتجربة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: fillQaAccount,
            child: const Text('تعبئة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthService>().busy;

    return Scaffold(
      backgroundColor: NexoColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [NexoColors.primary, NexoColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexoColors.primary.withOpacity(.24),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 43,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NEXO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Social World • Chat • Games • Store',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NexoColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: NexoColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: NexoColors.primary.withOpacity(.10),
                      ),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: tabs,
                          onTap: (_) => setState(() {}),
                          tabs: const [
                            Tab(text: 'تسجيل الدخول'),
                            Tab(text: 'إنشاء حساب'),
                          ],
                        ),
                        AnimatedBuilder(
                          animation: tabs,
                          builder: (context, _) {
                            return Padding(
                              padding: const EdgeInsets.all(17),
                              child: tabs.index == 0
                                  ? Column(
                                      children: [
                                        field(
                                          id,
                                          'اسم المستخدم أو البريد الإلكتروني',
                                          Icons.person_outline_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction:
                                              TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                        ),
                                        field(
                                          pass,
                                          'كلمة السر',
                                          Icons.lock_outline_rounded,
                                          password: true,
                                          visible: showPass,
                                          onToggle: () => setState(
                                            () => showPass = !showPass,
                                          ),
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction:
                                              TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onEditingComplete: busy
                                              ? null
                                              : loginNow,
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed:
                                                busy ? null : loginNow,
                                            child: Text(
                                              busy
                                                  ? 'جارٍ تسجيل الدخول...'
                                                  : 'تسجيل الدخول',
                                            ),
                                          ),
                                        ),
                                        qaCard(),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        field(
                                          user,
                                          'اسم المستخدم',
                                          Icons.alternate_email_rounded,
                                          textInputAction:
                                              TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.newUsername,
                                          ],
                                        ),
                                        field(
                                          name,
                                          'اسم العرض',
                                          Icons.badge_outlined,
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                        field(
                                          email,
                                          'البريد الإلكتروني',
                                          Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction:
                                              TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.email,
                                          ],
                                        ),
                                        field(
                                          regPass,
                                          'كلمة السر',
                                          Icons.lock_outline_rounded,
                                          password: true,
                                          visible: showRegPass,
                                          onToggle: () => setState(
                                            () => showRegPass = !showRegPass,
                                          ),
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction:
                                              TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                        ),
                                        field(
                                          confirm,
                                          'تأكيد كلمة السر',
                                          Icons.verified_user_outlined,
                                          password: true,
                                          visible: showConfirm,
                                          onToggle: () => setState(
                                            () => showConfirm = !showConfirm,
                                          ),
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          textInputAction:
                                              TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                          onEditingComplete: busy
                                              ? null
                                              : registerNow,
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed:
                                                busy ? null : registerNow,
                                            child: Text(
                                              busy
                                                  ? 'جارٍ إنشاء الحساب...'
                                                  : 'إنشاء حساب',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    height: 47,
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
                    style: TextStyle(
                      color: NexoColors.textSecondary,
                      fontSize: 11,
                    ),
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
