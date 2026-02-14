import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<Product> _products;
  String _search = '';
  String _categoryFilter = 'all';
  String _statusFilter = 'all';
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _products = MockDataGenerator.generateProducts();
  }

  List<Product> get _filtered {
    return _products.where((p) {
      if (_categoryFilter != 'all' && p.category != _categoryFilter) return false;
      if (_statusFilter != 'all' && p.status != _statusFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return p.sku.toLowerCase().contains(q) || p.name.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<String> get _categories => _products.map((p) => p.category).toSet().toList();

  void _showSnack(String message, {Color color = AppColors.primary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildToolbar(),
          const SizedBox(height: 14),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260, height: 40,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by SKU or name...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true, fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          _filterChip('Category', _categoryFilter, [
            const DropdownMenuItem(value: 'all', child: Text('All Categories')),
            ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ], (v) => setState(() => _categoryFilter = v!)),
          _filterChip('Status', _statusFilter, const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'in-stock', child: Text('In Stock')),
            DropdownMenuItem(value: 'low-stock', child: Text('Low Stock')),
            DropdownMenuItem(value: 'out-of-stock', child: Text('Out of Stock')),
          ], (v) => setState(() => _statusFilter = v!)),
          // Summary chips
          _summaryChip('${_products.length}', 'Products', AppColors.primary),
          _summaryChip('${_products.where((p) => p.status == 'low-stock').length}', 'Low Stock', AppColors.accent),
          _summaryChip('${_products.where((p) => p.status == 'out-of-stock').length}', 'Out', AppColors.error),
          FilledButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }

  Widget _buildProductList() {
    final list = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: list.isEmpty
          ? const Center(child: Text('No products found', style: TextStyle(color: AppColors.textLight)))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _buildProductRow(list[i]),
            ),
    );
  }

  Widget _buildProductRow(Product p) {
    final isExpanded = _expandedId == p.id;
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenW < 700;

    return InkWell(
      onTap: () => setState(() => _expandedId = isExpanded ? null : p.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        color: isExpanded ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact) ...[
              // ── Mobile layout: stacked ──
              Row(children: [
                // SKU badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(p.sku, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMid, fontFamily: 'monospace')),
                ),
                const SizedBox(width: 8),
                _statusBadge(p.statusLabel, p.statusColor),
                const Spacer(),
                Text('${p.quantity}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.statusColor)),
                const SizedBox(width: 2),
                const Text('qty', style: TextStyle(fontSize: 9, color: AppColors.textLight)),
                const SizedBox(width: 6),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.textLight),
              ]),
              const SizedBox(height: 6),
              Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Text(p.category, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textLight),
                const SizedBox(width: 2),
                Text(p.locationLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                const Spacer(),
                InkWell(
                  onTap: () => _showStockDialog(p),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.tune_rounded, size: 16, color: AppColors.textMid)),
                ),
                InkWell(
                  onTap: () => _showProductDialog(existing: p),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textMid)),
                ),
                InkWell(
                  onTap: () => _confirmDeleteProduct(p),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 16, color: AppColors.error)),
                ),
              ]),
            ] else ...[
              // ── Desktop layout: single row ──
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(p.sku, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMid, fontFamily: 'monospace')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                    Text(p.category, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ]),
                ),
                Column(children: [
                  Text('${p.quantity}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.statusColor)),
                  const Text('qty', style: TextStyle(fontSize: 9, color: AppColors.textLight)),
                ]),
                const SizedBox(width: 16),
                _statusBadge(p.statusLabel, p.statusColor),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Text(p.locationLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  ]),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Adjust stock',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showStockDialog(p),
                  icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.textMid),
                ),
                IconButton(
                  tooltip: 'Edit product',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showProductDialog(existing: p),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMid),
                ),
                IconButton(
                  tooltip: 'Delete product',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteProduct(p),
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                ),
                const SizedBox(width: 8),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight),
              ]),
            ],
            // Expanded detail
            if (isExpanded) ...[
              const SizedBox(height: 14),
              _buildExpandedDetail(p),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDetail(Product p) {
    final stockPercent = p.maxStock > 0 ? (p.quantity / p.maxStock).clamp(0.0, 1.0) : 0.0;
    final isCompact = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: isCompact ? 12 : 0,
            runSpacing: 8,
            children: [
              SizedBox(width: isCompact ? null : null, child: _detailItem('Price', '${p.price.toStringAsFixed(0)} DA')),
              SizedBox(width: isCompact ? null : null, child: _detailItem('Min Stock', '${p.minStock}')),
              SizedBox(width: isCompact ? null : null, child: _detailItem('Max Stock', '${p.maxStock}')),
              SizedBox(width: isCompact ? null : null, child: _detailItem('Last Updated', _fmtDate(p.lastUpdated))),
            ],
          ),
          const SizedBox(height: 14),
          // Stock level bar
          Row(children: [
            const Text('Stock Level', style: TextStyle(fontSize: 11, color: AppColors.textMid)),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stockPercent,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(p.statusColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(stockPercent * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.statusColor)),
          ]),
          const SizedBox(height: 14),
          // AI Demand Forecast (mock)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.aiBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.psychology_rounded, size: 16, color: AppColors.aiBlue),
              const SizedBox(width: 8),
              const Expanded(child: Text('AI Forecast: Demand expected to increase 15% next month', style: TextStyle(fontSize: 11, color: AppColors.aiBlue))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.aiBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: const Text('89% conf.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.aiBlue)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showProductDialog({Product? existing}) {
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? 'General');
    final qtyCtrl = TextEditingController(text: '${existing?.quantity ?? 0}');
    final minCtrl = TextEditingController(text: '${existing?.minStock ?? 10}');
    final maxCtrl = TextEditingController(text: '${existing?.maxStock ?? 100}');
    final locationCtrl = TextEditingController(text: existing?.locationLabel ?? 'A-01');
    final priceCtrl = TextEditingController(text: '${existing?.price ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(existing == null ? Icons.inventory_2_outlined : Icons.edit, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(existing == null ? 'New Product' : 'Edit Product'),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Stock'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Stock'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final sku = skuCtrl.text.trim();
              final name = nameCtrl.text.trim();
              final category = categoryCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final minStock = int.tryParse(minCtrl.text.trim()) ?? 0;
              final maxStock = int.tryParse(maxCtrl.text.trim()) ?? 0;
              final location = locationCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

              if (sku.isEmpty || name.isEmpty || category.isEmpty || location.isEmpty) {
                _showSnack('Please fill all required fields', color: AppColors.error);
                return;
              }
              if (maxStock < minStock) {
                _showSnack('Max stock must be >= min stock', color: AppColors.error);
                return;
              }

              setState(() {
                if (existing == null) {
                  _products.add(
                    Product(
                      sku: sku,
                      name: name,
                      category: category,
                      quantity: quantity,
                      minStock: minStock,
                      maxStock: maxStock,
                      locationLabel: location,
                      price: price,
                    ),
                  );
                } else {
                  existing.sku = sku;
                  existing.name = name;
                  existing.category = category;
                  existing.quantity = quantity;
                  existing.minStock = minStock;
                  existing.maxStock = maxStock;
                  existing.locationLabel = location;
                  existing.price = price;
                  existing.lastUpdated = DateTime.now();
                }
              });

              Navigator.pop(ctx);
              _showSnack(existing == null ? 'Product added' : 'Product updated');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showStockDialog(Product p) {
    final ctrl = TextEditingController(text: '${p.quantity}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Adjust Stock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${p.sku} • ${p.name}', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final q = int.tryParse(ctrl.text.trim());
              if (q == null || q < 0) {
                _showSnack('Quantity must be a non-negative integer', color: AppColors.error);
                return;
              }
              setState(() {
                p.quantity = q;
                p.lastUpdated = DateTime.now();
              });
              Navigator.pop(ctx);
              _showSnack('Stock updated');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Product?'),
          ],
        ),
        content: Text('Remove "${p.name}" (${p.sku}) permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _products.removeWhere((x) => x.id == p.id));
              _showSnack('Product deleted', color: AppColors.error);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
