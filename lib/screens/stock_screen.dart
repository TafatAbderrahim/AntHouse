import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _ledger = [];
  bool _loadingSummary = true;
  bool _loadingAlerts = true;
  bool _loadingLedger = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    _fetchSummary();
    _fetchAlerts();
    _fetchLedger();
  }

  Future<void> _fetchSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final result = await ApiService.getAdminInventorySummary();
      if (result['success'] == true && result['data'] != null) {
        setState(() { _summary = result['data'] is Map ? result['data'] : {}; _loadingSummary = false; });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingSummary = false);
  }

  Future<void> _fetchAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final result = await ApiService.getInventoryAlerts();
      setState(() {
        _alerts = result.whereType<Map<String, dynamic>>().toList();
        _loadingAlerts = false;
      });
      return;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingAlerts = false);
  }

  Future<void> _fetchLedger() async {
    setState(() => _loadingLedger = true);
    try {
      final result = await ApiService.getStockLedger();
      setState(() {
        _ledger = result.whereType<Map<String, dynamic>>().toList();
        _loadingLedger = false;
      });
      return;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingLedger = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMid,
          indicatorColor: AppColors.primaryDark,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Alerts'),
            Tab(text: 'Ledger'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tabCtrl, children: [
          _buildSummaryTab(),
          _buildAlertsTab(),
          _buildLedgerTab(),
        ]),
      ),
    ]);
  }

  Widget _buildSummaryTab() {
    if (_loadingSummary) return const Center(child: CircularProgressIndicator());
    final entries = _summary.entries.toList();
    if (entries.isEmpty) return Center(child: Text('No stock summary available', style: TextStyle(color: AppColors.textMid)));

    return RefreshIndicator(
      onRefresh: _fetchSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: entries.map((e) {
            return Container(
              width: 180, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatKey(e.key), style: TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('${e.value}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ]),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_loadingAlerts) return const Center(child: CircularProgressIndicator());
    if (_alerts.isEmpty) return Center(child: Text('No inventory alerts', style: TextStyle(color: AppColors.textMid)));

    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (_, i) {
          final a = _alerts[i];
          final type = (a['type'] ?? a['alertType'] ?? 'ALERT').toString();
          final product = a['productName'] ?? a['produitNom'] ?? 'Product #${a['productId'] ?? a['produitId'] ?? ''}';
          final msg = a['message'] ?? a['description'] ?? '';
          final isLow = type.toUpperCase().contains('LOW') || type.toUpperCase().contains('RUPTURE');
          final color = isLow ? AppColors.error : AppColors.accent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(isLow ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$product', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$type', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                if (msg.toString().isNotEmpty)
                  Text('$msg', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
              ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildLedgerTab() {
    if (_loadingLedger) return const Center(child: CircularProgressIndicator());
    if (_ledger.isEmpty) return Center(child: Text('No ledger entries', style: TextStyle(color: AppColors.textMid)));

    return RefreshIndicator(
      onRefresh: _fetchLedger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ledger.length,
        itemBuilder: (_, i) {
          final e = _ledger[i];
          final type = (e['typeTransaction'] ?? e['type'] ?? '').toString();
          final qty = e['quantite'] ?? e['quantity'] ?? '';
          final product = e['produitNom'] ?? e['productName'] ?? 'Product #${e['produitId'] ?? e['productId'] ?? ''}';
          final date = e['dateTransaction'] ?? e['date'] ?? '';
          final isEntry = type.toUpperCase().contains('ENTR') || type.toUpperCase().contains('IN');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              Icon(isEntry ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isEntry ? AppColors.success : AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$product', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$type  •  $date', style: TextStyle(fontSize: 11, color: AppColors.textMid)),
              ])),
              Text('${isEntry ? "+" : "-"}$qty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isEntry ? AppColors.success : AppColors.error)),
            ]),
          );
        },
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
