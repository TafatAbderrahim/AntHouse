import 'package:flutter/material.dart';

import '../models/admin_data.dart';
import 'ai_validation_screen.dart';
import 'audit_logs_screen.dart';
import 'dashboard_screen.dart';
import 'warehouse_screen.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({super.key});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    WarehouseScreen(),
    AiValidationScreen(),
    AuditLogsScreen(),
  ];

  final _labels = const ['Operations', 'Warehouse', 'AI Validation', 'Audit Logs'];
  final _icons = const [Icons.dashboard_outlined, Icons.warehouse_outlined, Icons.psychology_alt_outlined, Icons.history];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isDesktop ? null : Drawer(child: _navList()),
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
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        Builder(
                          builder: (innerContext) => IconButton(
                            onPressed: () => Scaffold.of(innerContext).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        ),
                      Text(
                        _labels[_index],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.aiBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Supervisor', style: TextStyle(color: AppColors.aiBlue, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _screens[_index],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navList() {
    return ListView(
      children: [
        const SizedBox(height: 16),
        const ListTile(
          title: Text('ANT BMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: Text('Supervisor Panel', style: TextStyle(color: Colors.white70)),
        ),
        const Divider(color: Colors.white24),
        for (var i = 0; i < _labels.length; i++)
          ListTile(
            leading: Icon(_icons[i], color: Colors.white),
            title: Text(_labels[i], style: const TextStyle(color: Colors.white)),
            selected: _index == i,
            selectedTileColor: Colors.white.withValues(alpha: 0.12),
            onTap: () {
              setState(() => _index = i);
              Navigator.of(context).maybePop();
            },
          ),
        const Divider(color: Colors.white24),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ],
    );
  }
}
