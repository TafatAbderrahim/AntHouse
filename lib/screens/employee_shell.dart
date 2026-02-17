import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import '../services/api_service.dart';
import 'emp_dashboard_screen.dart';
import 'emp_receipt_screen.dart';
import 'emp_storage_screen.dart';
import 'emp_picking_screen.dart';
import 'emp_delivery_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  EMPLOYEE SHELL — §7.1 Employee Task Simulation
//  Employee sees only validated operational tasks (FR-6).
//  No AI decision logic or override history visible.
// ═══════════════════════════════════════════════════════════════

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> with WidgetsBindingObserver {
  int _index = 0;
  late final List<OperationalTask> _tasks;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tasks = [];
    _initConnectivity();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final list = await ApiService.getMyTasks();
      if (!mounted || list.isEmpty) return;
      setState(() {
        _tasks = list.map<OperationalTask>((t) {
          final statusStr = (t['status'] ?? 'PENDING').toString().toUpperCase();
          OpTaskStatus status;
          switch (statusStr) {
            case 'IN_PROGRESS':
            case 'STARTED':
              status = OpTaskStatus.inProgress;
              break;
            case 'COMPLETED':
            case 'DONE':
              status = OpTaskStatus.completed;
              break;
            case 'FAILED':
              status = OpTaskStatus.failed;
              break;
            default:
              status = OpTaskStatus.pending;
          }

          final typeStr = (t['type'] ?? 'RECEIPT').toString().toUpperCase();
          OpType opType;
          switch (typeStr) {
            case 'TRANSFER':
            case 'STORAGE':
              opType = OpType.transfer;
              break;
            case 'PICKING':
            case 'PICK':
              opType = OpType.picking;
              break;
            case 'DELIVERY':
              opType = OpType.delivery;
              break;
            default:
              opType = OpType.receipt;
          }

          return OperationalTask(
            id: t['id']?.toString() ?? '',
            orderRef: t['reference'] ?? t['orderRef'] ?? '',
            operation: opType,
            orderType: OrderType.command,
            sku: t['sku'] ?? t['productSku'] ?? '',
            productName: t['productName'] ?? t['description'] ?? '',
            productId: t['productId']?.toString() ?? '',
            expectedQuantity: t['quantity'] ?? t['expectedQuantity'] ?? 0,
            receivedQuantity: t['completedQuantity'] ?? t['receivedQuantity'] ?? 0,
            fromLocation: t['sourceLocation'] ?? t['fromLocation'] ?? '',
            toLocation: t['destinationLocation'] ?? t['toLocation'] ?? '',
            targetFloor: t['floor'] ?? 0,
            status: status,
            assignedEmployeeId: t['assignedToId']?.toString() ?? '',
            assignedChariotId: t['chariotId']?.toString() ?? '',
          );
        }).toList();
      });
    } catch (_) {
      // Keep mock data
    }
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
    // Cancel existing subscription to avoid duplicates if re-initializing
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
    final screens = [
      EmpDashboardScreen(
        tasks: _tasks,
        isOnline: _isOnline,
        onNavigate: (i) => setState(() => _index = i),
      ),
      EmpReceiptScreen(tasks: _tasks, onTaskUpdated: _refresh),
      EmpStorageScreen(tasks: _tasks, onTaskUpdated: _refresh),
      EmpPickingScreen(tasks: _tasks, onTaskUpdated: _refresh),
      EmpDeliveryScreen(tasks: _tasks, onTaskUpdated: _refresh),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _refresh() => setState(() {});

  Widget _buildBottomNav() {
    final width = MediaQuery.of(context).size.width;
    final isCompactPhone = width < 520;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompactPhone ? 6 : 8,
            vertical: 8,
          ),
          child: isCompactPhone
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _navItem(0, Icons.dashboard_rounded, 'Dashboard', compact: true),
                      _navItem(1, Icons.inventory_rounded, 'Receipt', compact: true),
                      _navItem(2, Icons.swap_horiz_rounded, 'Storage', compact: true),
                      _navItem(3, Icons.shopping_basket_rounded, 'Picking', compact: true),
                      _navItem(4, Icons.local_shipping_rounded, 'Delivery', compact: true),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                    _navItem(1, Icons.inventory_rounded, 'Receipt'),
                    _navItem(2, Icons.swap_horiz_rounded, 'Storage'),
                    _navItem(3, Icons.shopping_basket_rounded, 'Picking'),
                    _navItem(4, Icons.local_shipping_rounded, 'Delivery'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label, {bool compact = false}) {
    final active = _index == idx;
    // Count pending tasks per operation
    int badge = 0;
    switch (idx) {
      case 1:
        badge = _tasks.where((t) => t.operation == OpType.receipt && t.status != OpTaskStatus.completed).length;
        break;
      case 2:
        badge = _tasks.where((t) => t.operation == OpType.transfer && t.status != OpTaskStatus.completed).length;
        break;
      case 3:
        badge = _tasks.where((t) => t.operation == OpType.picking && t.status != OpTaskStatus.completed).length;
        break;
      case 4:
        badge = _tasks.where((t) => t.operation == OpType.delivery && t.status != OpTaskStatus.completed).length;
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: compact ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? (active ? 12 : 10) : (active ? 16 : 12),
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: active ? Colors.white : Colors.white60),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: AppColors.textDark, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
