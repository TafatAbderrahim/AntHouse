import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import 'sup_dashboard_screen.dart';
import 'sup_ai_review_screen.dart';
import 'sup_incidents_screen.dart';
import 'warehouse_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  SUPERVISOR SHELL — §7.2 Supervisor Task Simulation
//  Oversee operations, validate AI outputs, monitor warehouse
//  activity in real time.
// ═══════════════════════════════════════════════════════════════

class SupervisorShellNew extends StatefulWidget {
  const SupervisorShellNew({super.key});

  @override
  State<SupervisorShellNew> createState() => _SupervisorShellNewState();
}

class _SupervisorShellNewState extends State<SupervisorShellNew> with WidgetsBindingObserver {
  int _index = 0;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  bool _isOnline = true;

  final _labels = const ['Operations', 'Warehouse', 'AI Review', 'Incidents'];
  final _icons = const [
    Icons.dashboard_rounded,
    Icons.warehouse_rounded,
    Icons.psychology_alt_rounded,
    Icons.warning_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initConnectivity();
    }
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _setOnlineFromResult(result);
    // Cancel existing to avoid duplicates
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      _setOnlineFromResult(result);
    });
  }

  void _setOnlineFromResult(dynamic result) {
    bool online;
    if (result is ConnectivityResult) {
      online = result != ConnectivityResult.none;
    } else if (result is List<ConnectivityResult>) {
      online = result.any((r) => r != ConnectivityResult.none);
    } else {
      online = true;
    }

    if (!mounted) return;
    if (_isOnline != online) {
      setState(() => _isOnline = online);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final screens = [
      const SupDashboardScreen(),
      const WarehouseScreen(),
      const SupAiReviewScreen(),
      const SupIncidentsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.sidebar,
              child: _navList(),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              color: AppColors.sidebar,
              child: SafeArea(child: _navList()),
            ),
          Expanded(
            child: Column(
              children: [
                // ── Top Bar ──
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        Builder(
                          builder: (innerCtx) => IconButton(
                            onPressed: () => Scaffold.of(innerCtx).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _labels[_index],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Live indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isOnline 
                              ? AppColors.success.withValues(alpha: 0.1) 
                              : AppColors.textMid.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: _isOnline ? AppColors.success : AppColors.textMid),
                            const SizedBox(width: 5),
                            Text(
                              _isOnline ? 'LIVE' : 'OFFLINE', 
                              style: TextStyle(
                                color: _isOnline ? AppColors.success : AppColors.textMid, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w800, 
                                letterSpacing: 1
                              )
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.aiBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Supervisor', style: TextStyle(color: AppColors.aiBlue, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _index == 1
                      ? screens[_index]
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: screens[_index],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom nav for mobile
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white60,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: List.generate(_labels.length, (i) => BottomNavigationBarItem(
                  icon: Icon(_icons[i]),
                  label: _labels[i],
                )),
              ),
            ),
    );
  }

  Widget _navList() {
    return Column(
      children: [
        // ── Logo header ──
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(7),
                child: ClipRect(
                  child: Transform.scale(
                    scale: 2.5,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.warehouse_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ANT HOUSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('Supervisor Panel', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),

        // ── Nav items ──
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < _labels.length; i++) _navTile(i),
            ],
          ),
        ),

        // ── Logout ──
        const Divider(color: Colors.white24, height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
          title: const Text('Logout', style: TextStyle(color: Colors.white70, fontSize: 14)),
          onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _navTile(int i) {
    final selected = _index == i;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(_icons[i], color: selected ? Colors.white : Colors.white60, size: 20),
        title: Text(
          _labels[i],
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() => _index = i);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}
