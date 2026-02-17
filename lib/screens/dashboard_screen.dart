import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/admin_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String _totalOrders = '—';
  String _activeWorkers = '—';
  String _aiDecisions = '—';
  String _alerts = '—';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final result = await ApiService.getAdminDashboard();
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final overview = data['overview'] ?? data;
        setState(() {
          _totalOrders = '${overview['totalOrders'] ?? overview['totalTransactions'] ?? 0}';
          _activeWorkers = '${overview['activeEmployees'] ?? overview['activeWorkers'] ?? 0}';
          _aiDecisions = '${data['aiMetrics']?['totalDecisions'] ?? overview['aiDecisionsToday'] ?? 0}';
          _alerts = '${overview['alerts'] ?? overview['lowStockAlerts'] ?? 0}';
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Dashboard',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const Spacer(),
              if (ApiService.isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _card('Total Orders', _totalOrders, Icons.receipt_long_rounded, AppColors.primary),
          const SizedBox(height: 12),
          _card('Active Workers', _activeWorkers, Icons.people_rounded, AppColors.success),
          const SizedBox(height: 12),
          _card('AI Decisions Today', _aiDecisions, Icons.psychology_rounded, AppColors.aiBlue),
          const SizedBox(height: 12),
          _card('Alerts', _alerts, Icons.warning_rounded, AppColors.error),
        ],
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
