import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import 'dashboard_screen.dart';
import 'warehouse_screen.dart';
import 'users_screen.dart';
import 'inventory_screen.dart';
import 'ai_analytics_screen.dart';
import 'overrides_screen.dart';
import 'audit_logs_screen.dart';
import 'system_integrity_screen.dart';
import 'profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.people_rounded, 'Users'),
    _NavItem(Icons.warehouse_rounded, 'Warehouse'),
    _NavItem(Icons.inventory_2_rounded, 'Inventory'),
    _NavItem(Icons.psychology_rounded, 'AI Analytics'),
    _NavItem(Icons.compare_arrows_rounded, 'Overrides'),
    _NavItem(Icons.receipt_long_rounded, 'Audit Logs'),
    _NavItem(Icons.security_rounded, 'System Integrity'),
  ];

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const WarehouseScreen(),
    const InventoryScreen(),
    const AiAnalyticsScreen(),
    const OverridesScreen(),
    const AuditLogsScreen(),
    const SystemIntegrityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 700;
    final isPhone = w <= 700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isPhone ? _buildDrawer() : null,
      bottomNavigationBar: isPhone ? _buildBottomNav() : null,
      body: Row(
        children: [
          if (isDesktop && _isSidebarOpen) _buildExpandedSidebar(),
          if (isDesktop && !_isSidebarOpen) _buildRailSidebar(),
          if (isTablet && !isDesktop) _buildRailSidebar(),
          Expanded(child: _buildMainContent(isTablet, isPhone)),
        ],
      ),
    );
  }

  // ═══════════════════ BOTTOM NAV FOR PHONE ═══════════════════

  Widget? _buildBottomNav() {
    // Only show bottom nav for the 4 most-used items on phone
    final phoneItems = [0, 2, 3, 4]; // Dashboard, Warehouse, Inventory, AI
    final currentPhoneIdx = phoneItems.indexOf(_selectedIndex);

    return NavigationBar(
      height: 72,
      selectedIndex: currentPhoneIdx == -1 ? 0 : currentPhoneIdx,
      onDestinationSelected: (i) => _goTo(phoneItems[i]),
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      destinations: phoneItems.map((idx) {
        final item = _navItems[idx];
        return NavigationDestination(
          icon: Icon(item.icon, size: 24),
          selectedIcon: Icon(item.icon, size: 24, color: AppColors.primary),
          label: item.label,
        );
      }).toList(),
    );
  }

  // ═══════════════════ MAIN CONTENT ═══════════════════

  Widget _buildMainContent(bool isTablet, bool isPhone) {
    return Column(
      children: [
        _buildTopBar(isTablet, isPhone),
        Expanded(
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isTablet, bool isPhone) {
    final titles = [
      'Dashboard', 'Users', 'Warehouse',
      'Inventory', 'AI Analytics', 'Overrides',
      'Audit Logs', 'System Integrity', 'Profile',
    ];
    final titleSize = isPhone ? 20.0 : 28.0;
    final barHeight = isPhone ? 60.0 : 72.0;

    return Container(
      height: barHeight,
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu_rounded,
                  color: AppColors.textDark, size: 26),
              onPressed: () {
                if (isPhone) {
                  Scaffold.of(ctx).openDrawer();
                } else {
                  setState(() => _isSidebarOpen = !_isSidebarOpen);
                }
              },
            ),
          ),
          SizedBox(width: isPhone ? 4 : 8),
          Flexible(
            child: Text(
              titles[_selectedIndex],
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Online indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 8 : 14,
              vertical: isPhone ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isPhone ? 6 : 8,
                  height: isPhone ? 6 : 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isPhone ? 4 : 6),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: isPhone ? 12 : 16,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isPhone ? 6 : 14),
          if (!isPhone)
            IconButton(
              icon: Badge(
                smallSize: 8,
                backgroundColor: AppColors.error,
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textMid,
                  size: isPhone ? 22 : 26,
                ),
              ),
              onPressed: () {},
            ),
          SizedBox(width: isPhone ? 4 : 8),
          InkWell(
            onTap: () => _goTo(8), // Profile
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: isPhone ? 18 : 24,
              backgroundColor: AppColors.primaryDark,
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 14 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ EXPANDED SIDEBAR ═══════════════════

  Widget _buildExpandedSidebar() {
    return Container(
      width: 300,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(_navItems.length, (i) => _buildSidebarItem(i)),
            ),
          ),
          const Divider(
              color: Colors.white24, height: 1, indent: 16, endIndent: 16),
          _buildSidebarItem(8, icon: Icons.person_rounded, label: 'Profile'),
          _buildSidebarLogout(),
          // BMS Sponsor - BIG
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.all(10),
            child: ClipRect(
              child: Transform.scale(
                scale: 2.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.warehouse, color: Colors.white, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANT HOUSE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              SizedBox(height: 2),
              Text('Warehouse',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, {IconData? icon, String? label}) {
    final isActive = _selectedIndex == index;
    final item = index < _navItems.length ? _navItems[index] : null;
    final ic = icon ?? item!.icon;
    final lb = label ?? item!.label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: isActive ? const Color(0xFF1A9BB5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _goTo(index),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(ic,
                    size: 23,
                    color: isActive ? Colors.white : Colors.white60),
                const SizedBox(width: 14),
                Text(lb,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 30 / 2,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
          hoverColor: AppColors.error.withValues(alpha: 0.15),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 24, color: Colors.white60),
                SizedBox(width: 14),
                Text('Logout',
                    style: TextStyle(color: Colors.white70, fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ RAIL SIDEBAR ═══════════════════

  Widget _buildRailSidebar() {
    return Container(
      width: 80,
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.all(9),
            child: ClipRect(
              child: Transform.scale(
                scale: 2.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.warehouse, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(_navItems.length, (i) {
                final isActive = _selectedIndex == i;
                return Tooltip(
                  message: _navItems[i].label,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color:
                          isActive ? AppColors.sidebarHover : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _goTo(i),
                        child: SizedBox(
                          width: 52,
                          height: 48,
                          child: Icon(_navItems[i].icon,
                              size: 24,
                              color: isActive ? Colors.white : Colors.white60),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Tooltip(
            message: 'Profile',
            child: IconButton(
              icon: Icon(Icons.person_rounded,
                  size: 26,
                  color:
                      _selectedIndex == 8 ? Colors.white : Colors.white60),
              onPressed: () => _goTo(8),
            ),
          ),
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon:
                  const Icon(Icons.logout_rounded, size: 26, color: Colors.white60),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/login'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════ MOBILE DRAWER ═══════════════════

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.sidebar,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            _buildSidebarHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: List.generate(_navItems.length, (i) => _buildSidebarItem(i)),
              ),
            ),
            const Divider(
                color: Colors.white24, height: 1, indent: 16, endIndent: 16),
            _buildSidebarItem(8, icon: Icons.person_rounded, label: 'Profile'),
            _buildSidebarLogout(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop();
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
