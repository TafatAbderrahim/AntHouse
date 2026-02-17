import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class ChariotsScreen extends StatefulWidget {
  const ChariotsScreen({super.key});
  @override
  State<ChariotsScreen> createState() => _ChariotsScreenState();
}

class _ChariotsScreenState extends State<ChariotsScreen> {
  List<Map<String, dynamic>> _chariots = [];
  bool _loading = true;
  String _statusFilter = 'ALL';

  static const _statuses = ['ALL', 'AVAILABLE', 'IN_USE', 'MAINTENANCE', 'RETIRED'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getAdminChariots();
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final content = data is List ? data : (data['content'] ?? []);
        if (content is List) {
          setState(() {
            _chariots = content.cast<Map<String, dynamic>>();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'ALL') return _chariots;
    return _chariots.where((c) {
      final s = (c['statut'] ?? c['status'] ?? '').toString().toUpperCase();
      return s == _statusFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Chariot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s, style: TextStyle(fontSize: 12, color: _statusFilter == s ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w500)),
                  selected: _statusFilter == s,
                  onSelected: (_) => setState(() => _statusFilter = s),
                  selectedColor: AppColors.primaryDark,
                  backgroundColor: AppColors.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )).toList()),
            ),
            const SizedBox(height: 6),
            Text('${_filtered.length} chariots', style: TextStyle(fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 10),
            if (_filtered.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No chariots found', style: TextStyle(color: AppColors.textMid)))),
            ..._filtered.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final status = (c['statut'] ?? c['status'] ?? 'UNKNOWN').toString();
    final id = c['idChariot']?.toString() ?? c['id']?.toString() ?? '';
    final type = c['typeChariot']?.toString() ?? c['type']?.toString() ?? '';
    final capacity = c['capaciteMax']?.toString() ?? c['capacity']?.toString() ?? '';
    final entrepot = c['entrepotId']?.toString() ?? c['warehouseId']?.toString() ?? '';
    final statusColor = status.contains('AVAILABLE') ? AppColors.success
        : status.contains('IN_USE') ? AppColors.aiBlue
        : status.contains('MAINTENANCE') ? AppColors.accent
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.local_shipping_rounded, color: statusColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chariot #$id', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (type.isNotEmpty) Text('Type: $type', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
          if (capacity.isNotEmpty) Text('Capacity: $capacity', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
          if (entrepot.isNotEmpty) Text('Warehouse: $entrepot', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.textMid, size: 18),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) async {
            if (v == 'delete') {
              try { await ApiService.deleteChariot(id); _fetch(); } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
        ),
      ]),
    );
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Chariot'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Chariot Code * (e.g. CH-001)', border: OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (codeCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code is required'), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(ctx);
            try {
              await ApiService.createChariot({
                'code': codeCtrl.text.trim(),
              });
              _fetch();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chariot added'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }
}
