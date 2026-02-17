import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class SystemIntegrityScreen extends StatefulWidget {
  const SystemIntegrityScreen({super.key});

  @override
  State<SystemIntegrityScreen> createState() => _SystemIntegrityScreenState();
}

class _SystemIntegrityScreenState extends State<SystemIntegrityScreen> {
  bool _loading = true;
  bool _apiOnline = false;
  Map<String, dynamic> _aiHealth = {};
  Map<String, dynamic> _warehouseState = {};

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.checkHealth(),
        ApiService.getAiHealth().catchError((_) => <String, dynamic>{}),
        ApiService.getAiWarehouseState().catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _apiOnline = results[0] as bool;
        _aiHealth = results[1] is Map<String, dynamic> ? results[1] as Map<String, dynamic> : {};
        _warehouseState = results[2] is Map<String, dynamic> ? results[2] as Map<String, dynamic> : {};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final aiStatus = _aiHealth['success'] == true ? 'Running' : 'Unknown';
    final aiData = _aiHealth['data'];
    final aiDetail = aiData is Map ? (aiData['status'] ?? aiStatus).toString() : aiStatus;

    final whData = _warehouseState['data'];
    final whDetail = whData is Map
        ? 'Products: ${whData['totalProducts'] ?? '?'} · Locations: ${whData['totalLocations'] ?? '?'}'
        : 'No data';

    return RefreshIndicator(
      onRefresh: _checkAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('System Integrity',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _checkAll,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statusCard(
            'API Gateway',
            _apiOnline ? 'Online' : 'Offline',
            Icons.cloud_done_rounded,
            _apiOnline ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 10),
          _statusCard(
            'Database',
            _apiOnline ? 'Healthy' : 'Unknown',
            Icons.storage_rounded,
            _apiOnline ? AppColors.success : AppColors.textMid,
          ),
          const SizedBox(height: 10),
          _statusCard(
            'AI Engine',
            aiDetail,
            Icons.psychology_rounded,
            _aiHealth['success'] == true ? AppColors.aiBlue : AppColors.textMid,
          ),
          const SizedBox(height: 10),
          _statusCard(
            'Warehouse State',
            whDetail,
            Icons.warehouse_rounded,
            _warehouseState['success'] == true ? AppColors.primary : AppColors.textMid,
          ),
          const SizedBox(height: 10),
          _statusCard(
            'Auth Service',
            ApiService.isLoggedIn ? 'Authenticated' : 'Not logged in',
            Icons.verified_user_rounded,
            ApiService.isLoggedIn ? AppColors.success : AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(
      String label, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
