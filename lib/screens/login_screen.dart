import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _loading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final identifier = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username/email and password')),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final user = MockAuthService.authenticate(identifier, password);

    if (!mounted) return;

    if (user == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
      return;
    }

    if (!user.canAuthenticate) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account is disabled or locked')),
      );
      return;
    }

    user.lastLogin = DateTime.now();

    if (mounted) {
      // Route by role — §7.1 Employee, §7.2 Supervisor, §7.3 Admin
      switch (user.role) {
        case 'admin':
          Navigator.of(context).pushReplacementNamed('/admin');
          break;
        case 'supervisor':
          Navigator.of(context).pushReplacementNamed('/supervisor');
          break;
        case 'employee':
          Navigator.of(context).pushReplacementNamed('/employee');
          break;
        default:
          Navigator.of(context).pushReplacementNamed('/admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;
    final isPhone = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D5F), Color(0xFF006D84), Color(0xFF0E93AF)],
          ),
        ),
        child: Stack(
          children: [
            // ── Subtle dot pattern ──
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter()),
            ),

            // ── Main content ──
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 20 : 40,
                    vertical: isPhone ? 24 : 40,
                  ),
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(isPhone),
                ),
              ),
            ),

            // ── BMS Sponsor badge – bottom-right ──
            Positioned(
              right: isPhone ? 16 : 32,
              bottom: isPhone ? 12 : 24,
              child: _buildBmsSponsorBadge(isPhone),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ DESKTOP (large-scale) ═══════════════════

  Widget _buildDesktopLayout() {
    return Container(
      width: 1100,
      constraints: const BoxConstraints(maxHeight: 760),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 80,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left: Mascot hero panel ──
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF006D84), Color(0xFF0E93AF)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ant mascot – BIG 400px
                  Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Image.asset(
                      'assets/images/ant_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.warehouse_rounded,
                        size: 160,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'ANT BMS',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WAREHOUSE MANAGEMENT SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'MobAI Hackathon 2026',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right: Login form ──
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
              child: _buildForm(isDesktop: true),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ MOBILE / TABLET ═══════════════════

  Widget _buildMobileLayout(bool isPhone) {
    final logoSize = isPhone ? 100.0 : 140.0;
    final cardPadding = isPhone ? 24.0 : 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top branding area (on gradient bg) ──
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            'assets/images/ant_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.warehouse_rounded,
              size: isPhone ? 50 : 60,
              color: Colors.white54,
            ),
          ),
        ),
        SizedBox(height: isPhone ? 12 : 16),
        Text(
          'ANT BMS',
          style: TextStyle(
            fontSize: isPhone ? 32 : 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'WAREHOUSE MANAGEMENT SYSTEM',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white60,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isPhone ? 24 : 32),

        // ── Glass-effect login card ──
        Container(
          width: isPhone ? double.infinity : 520,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: _buildForm(isDesktop: false, isPhone: isPhone),
        ),

        SizedBox(height: isPhone ? 16 : 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'MobAI Hackathon 2026',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ FORM ═══════════════════

  Widget _buildForm({bool isDesktop = false, bool isPhone = false}) {
    final titleSize = isDesktop ? 36.0 : (isPhone ? 24.0 : 30.0);
    final subtitleSize = isDesktop ? 18.0 : (isPhone ? 14.0 : 16.0);
    final badgeTextSize = isDesktop ? 16.0 : (isPhone ? 12.0 : 14.0);
    final inputHeight = isDesktop ? 72.0 : (isPhone ? 52.0 : 60.0);
    final inputFontSize = isDesktop ? 20.0 : (isPhone ? 16.0 : 18.0);
    final iconSize = isDesktop ? 24.0 : (isPhone ? 18.0 : 20.0);
    final btnHeight = isDesktop ? 64.0 : (isPhone ? 52.0 : 56.0);
    final btnFontSize = isDesktop ? 22.0 : (isPhone ? 16.0 : 18.0);
    final gap = isDesktop ? 24.0 : (isPhone ? 14.0 : 18.0);
    final bigGap = isDesktop ? 40.0 : (isPhone ? 20.0 : 28.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign In',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 4),
        Text(
          'Role-based secure access',
          style: TextStyle(fontSize: subtitleSize, color: AppColors.textLight),
        ),
        SizedBox(height: bigGap),

        // ── Role-based access badge ──
        Container(
          padding: EdgeInsets.all(isDesktop ? 16 : 10),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded,
                  size: iconSize, color: AppColors.primaryDark),
              SizedBox(width: isDesktop ? 12 : 8),
              Expanded(
                child: Text(
                  'ADMIN · SUPERVISOR · EMPLOYEE',
                  style: TextStyle(
                    fontSize: badgeTextSize,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: gap),

        // ── Username / Email ──
        _buildTextField(
          controller: _emailCtrl,
          hint: 'Username or Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          height: inputHeight,
          fontSize: inputFontSize,
          iconSize: iconSize,
        ),
        SizedBox(height: gap * 0.7),

        // ── Password ──
        _buildTextField(
          controller: _passwordCtrl,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_loading) _signIn();
          },
          height: inputHeight,
          fontSize: inputFontSize,
          iconSize: iconSize,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: iconSize,
              color: AppColors.textLight,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: isDesktop ? 10 : 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: isDesktop ? 16 : 13,
                color: AppColors.textLight,
              ),
            ),
          ),
        ),
        SizedBox(height: gap),

        // ── Sign In button ──
        SizedBox(
          width: double.infinity,
          height: btnHeight,
          child: FilledButton(
            onPressed: _loading ? null : _signIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 18 : 14)),
              elevation: 0,
            ),
            child: _loading
                ? SizedBox(
                    width: isDesktop ? 28 : 22,
                    height: isDesktop ? 28 : 22,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.login_rounded,
                          size: iconSize, color: Colors.white),
                      SizedBox(width: isDesktop ? 12 : 8),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: btnFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ TEXT FIELD ═══════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double height,
    required double fontSize,
    required double iconSize,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    bool obscure = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        obscureText: obscure,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: AppColors.textLight, fontSize: fontSize * 0.9),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, size: iconSize, color: AppColors.textLight),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: iconSize + 28),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: (height - fontSize - 8) / 2,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }

  // ═══════════════════ BMS SPONSOR ═══════════════════

  Widget _buildBmsSponsorBadge(bool isPhone) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 10 : 16,
        vertical: isPhone ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo_bms_small.png',
            width: isPhone ? 24 : 36,
            height: isPhone ? 24 : 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          SizedBox(width: isPhone ? 6 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sponsored by',
                style: TextStyle(
                    fontSize: isPhone ? 9 : 12,
                    color: Colors.white54,
                    letterSpacing: 0.5),
              ),
              Text(
                'BMS Electric',
                style: TextStyle(
                    fontSize: isPhone ? 13 : 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════ BACKGROUND PATTERN ═══════════════════

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
