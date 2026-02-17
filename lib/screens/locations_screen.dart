import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String _zoneFilter = 'ALL';

  static const _zones = ['ALL', 'RECEIVING', 'STORAGE', 'PICKING', 'EXPEDITION', 'QC', 'DAMAGED'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getAdminLocations();
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final content = data is List ? data : (data['content'] ?? []);
        if (content is List) {
          setState(() {
            _locations = content.cast<Map<String, dynamic>>();
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
    if (_zoneFilter == 'ALL') return _locations;
    return _locations.where((l) {
      final z = (l['zone'] ?? l['type'] ?? '').toString().toUpperCase();
      return z.contains(_zoneFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Add Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _zones.map((z) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(z, style: TextStyle(fontSize: 12, color: _zoneFilter == z ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w500)),
                  selected: _zoneFilter == z,
                  onSelected: (_) => setState(() => _zoneFilter = z),
                  selectedColor: AppColors.primaryDark,
                  backgroundColor: AppColors.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )).toList()),
            ),
            const SizedBox(height: 6),
            Text('${_filtered.length} locations', style: TextStyle(fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 10),
            if (_filtered.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No locations found', style: TextStyle(color: AppColors.textMid)))),
            ..._filtered.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> loc) {
    final id = loc['idEmplacement']?.toString() ?? loc['id']?.toString() ?? '';
    final zone = (loc['zone'] ?? loc['type'] ?? '').toString();
    final code = loc['code']?.toString() ?? loc['codeEmplacement']?.toString() ?? '';
    final capacity = loc['capaciteMax']?.toString() ?? '';
    final occupied = loc['quantiteActuelle']?.toString() ?? loc['currentQuantity']?.toString() ?? '';
    final warehouse = loc['warehouseId']?.toString() ?? loc['entrepotId']?.toString() ?? '';

    final zoneColor = zone.toUpperCase().contains('STORAGE') ? AppColors.primary
        : zone.toUpperCase().contains('RECEIV') ? AppColors.aiBlue
        : zone.toUpperCase().contains('PICK') ? AppColors.accent
        : zone.toUpperCase().contains('EXPED') ? AppColors.success
        : zone.toUpperCase().contains('QC') ? const Color(0xFF9C27B0)
        : zone.toUpperCase().contains('DAMAGED') ? AppColors.error
        : AppColors.textMid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.place_rounded, color: zoneColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(code.isNotEmpty ? code : 'Location #$id', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(zone, style: TextStyle(color: zoneColor, fontSize: 10, fontWeight: FontWeight.w600))),
            if (warehouse.isNotEmpty) ...[const SizedBox(width: 8), Text('WH: $warehouse', style: TextStyle(fontSize: 12, color: AppColors.textMid))],
          ]),
          if (capacity.isNotEmpty || occupied.isNotEmpty)
            Text('${occupied.isNotEmpty ? occupied : "0"} / ${capacity.isNotEmpty ? capacity : "—"}', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
        ])),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.textMid, size: 18),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) async {
            if (v == 'delete') {
              try { await ApiService.deleteLocation(id); _fetch(); } catch (e) {
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
    final warehouseIdCtrl = TextEditingController();
    final zoneCtrl = TextEditingController();
    final typeCtrl = ValueNotifier('STORAGE');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Location'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Location Code * (e.g. A-01-01)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: typeCtrl,
            builder: (_, val, __) => DropdownButtonFormField<String>(
              initialValue: val,
              decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
              items: ['RECEIVING', 'STORAGE', 'PICKING', 'EXPEDITION', 'QC', 'DAMAGED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => typeCtrl.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: warehouseIdCtrl, decoration: const InputDecoration(labelText: 'Warehouse ID * (UUID)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: zoneCtrl, decoration: const InputDecoration(labelText: 'Zone (optional)', border: OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (codeCtrl.text.trim().isEmpty || warehouseIdCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code and Warehouse ID are required'), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(ctx);
            try {
              await ApiService.createLocation({
                'code': codeCtrl.text.trim(),
                'type': typeCtrl.value,
                'warehouseId': warehouseIdCtrl.text.trim(),
                if (zoneCtrl.text.trim().isNotEmpty) 'zone': zoneCtrl.text.trim(),
              });
              _fetch();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location added'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }
}
