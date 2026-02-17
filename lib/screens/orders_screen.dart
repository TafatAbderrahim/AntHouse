import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getOrders(page: _page);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final content = data['content'] ?? data;
        if (content is List) {
          setState(() {
            _orders = content.cast<Map<String, dynamic>>();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Text('${_orders.length} orders', style: TextStyle(fontSize: 14, color: AppColors.textMid, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (_page > 0) IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { _page--; _fetch(); }),
              Text('Page ${_page + 1}', style: TextStyle(fontSize: 13, color: AppColors.textMid)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { _page++; _fetch(); }),
            ]),
            const SizedBox(height: 10),
            if (_orders.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No orders found', style: TextStyle(color: AppColors.textMid)))),
            ..._orders.map(_buildOrderCard),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final status = (o['statut'] ?? o['status'] ?? '').toString();
    final id = o['idCommandeAchat']?.toString() ?? o['id']?.toString() ?? '';
    final statusColor = status.toLowerCase().contains('complet') ? AppColors.success
        : status.toLowerCase().contains('progr') ? AppColors.aiBlue
        : status.toLowerCase().contains('cancel') ? AppColors.error
        : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Order #$id', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        if (o['fournisseur'] != null || o['supplier'] != null)
          Row(children: [
            const Icon(Icons.business, size: 14, color: AppColors.textMid),
            const SizedBox(width: 4),
            Text(o['fournisseur']?.toString() ?? o['supplier']?.toString() ?? '', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
          ]),
        if (o['dateCommande'] != null || o['createdAt'] != null)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textMid),
              const SizedBox(width: 4),
              Text(o['dateCommande']?.toString() ?? o['createdAt']?.toString() ?? '', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
            ])),
        if (o['lignes'] != null && o['lignes'] is List)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Text('${(o['lignes'] as List).length} line items', style: TextStyle(fontSize: 12, color: AppColors.textMid))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 8)),
            onPressed: () async {
              try { await ApiService.deleteOrder(id); _fetch(); } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            }),
        ]),
      ]),
    );
  }

  void _showCreateDialog() {
    final orderIdCtrl = TextEditingController();
    final productIdCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final dateCtrl = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Order'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: orderIdCtrl, decoration: const InputDecoration(labelText: 'Order ID (e.g. CMD-001) *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: productIdCtrl, decoration: const InputDecoration(labelText: 'Product ID (UUID) *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Expected Date (YYYY-MM-DD) *', border: OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (orderIdCtrl.text.trim().isEmpty || productIdCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields'), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(ctx);
            try {
              await ApiService.createOrder({
                'idCommandeAchat': orderIdCtrl.text.trim(),
                'productId': productIdCtrl.text.trim(),
                'quantiteCommandee': int.tryParse(qtyCtrl.text) ?? 1,
                'dateReceptionPrevue': dateCtrl.text.trim(),
              });
              _fetch();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }
}
