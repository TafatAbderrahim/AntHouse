import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isPhone = size.width < 600;

    // Responsive sizing
    final logoSize = isDesktop ? 440.0 : (isPhone ? 180.0 : 300.0);
    final titleSize = isDesktop ? 56.0 : (isPhone ? 30.0 : 42.0);
    final subtitleSize = isDesktop ? 18.0 : (isPhone ? 12.0 : 15.0);
    final btnHeight = isDesktop ? 68.0 : (isPhone ? 52.0 : 60.0);
    final btnFontSize = isDesktop ? 24.0 : (isPhone ? 16.0 : 20.0);
    final btnHorizontalPad = isDesktop ? 80.0 : (isPhone ? 40.0 : 60.0);
    final sponsorFontSize = isDesktop ? 14.0 : (isPhone ? 11.0 : 12.0);
    final sponsorLogoSize = isDesktop ? 32.0 : (isPhone ? 20.0 : 24.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF006D84), Color(0xFF0E93AF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ═══ Ant Mascot – large & crisp ═══
                  Image.asset(
                    'assets/images/ant_logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.precision_manufacturing_rounded,
                      size: isDesktop ? 120 : 70,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 36 : 20),

                  // ═══ Brand Name ═══
                  Text(
                    'ANT BMS',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 10 : 6),
                  Text(
                    'WAREHOUSE MANAGEMENT',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.white60,
                      letterSpacing: isDesktop ? 5 : 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // ═══ Log in button ═══
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: btnHorizontalPad),
                    child: SizedBox(
                      width: isDesktop ? 400 : double.infinity,
                      height: btnHeight,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/login'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 2.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: btnFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 20 : 14),
                  // BMS Sponsor - BIG
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sponsored by',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: sponsorFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/images/logo_bms_large.png',
                        width: isDesktop ? 240 : 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          'BMS Electric',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 60 : 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
