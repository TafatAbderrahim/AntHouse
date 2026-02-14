import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';

// ═══════════════════════════════════════════════════════════════
//  SUPERVISOR INCIDENTS — §7.2 step 5
//  • Handle missing/damaged products
//  • Detect location conflicts
//  • Alert on workflow bottlenecks
//  • Register & resolve incidents (FR-43, FR-46, FR-47)
// ═══════════════════════════════════════════════════════════════

class SupIncidentsScreen extends StatefulWidget {
  const SupIncidentsScreen({super.key});

  @override
  State<SupIncidentsScreen> createState() => _SupIncidentsScreenState();
}

class _SupIncidentsScreenState extends State<SupIncidentsScreen> {
  late final List<Incident> _incidents;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _incidents = MockOperationsData.generateIncidents();
  }

  List<Incident> get _filtered {
    if (_filterType == 'all') return _incidents;
    return _incidents.where((i) => i.type.name == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final open = _incidents.where((i) => i.status == 'open').length;
    final investigating = _incidents.where((i) => i.status == 'investigating').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 24, color: AppColors.error),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incidents & Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('Operational anomalies & conflict resolution (FR-46, FR-47)', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                ],
              ),
            ),
            if (open > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$open open', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Summary cards ──
        Row(
          children: [
            _summaryChip('Open', open, AppColors.error),
            const SizedBox(width: 8),
            _summaryChip('Investigating', investigating, AppColors.accent),
            const SizedBox(width: 8),
            _summaryChip('Resolved', _incidents.length - open - investigating, AppColors.success),
          ],
        ),
        const SizedBox(height: 14),

        // ── Filters ──
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip('All', 'all'),
              _chip('Missing', 'missingProduct'),
              _chip('Damaged', 'damagedProduct'),
              _chip('Conflict', 'locationConflict'),
              _chip('Bottleneck', 'bottleneck'),
              _chip('Other', 'other'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Incidents list ──
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No incidents in this category.', style: TextStyle(color: AppColors.textMid)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _incidentCard(_filtered[i]),
                ),
        ),

        // ── Quick add button ──
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addIncident,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Report Incident'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String type) {
    final sel = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        selectedColor: AppColors.primaryDark,
        labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textMid, fontSize: 11, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        side: BorderSide(color: sel ? AppColors.primaryDark : AppColors.divider),
        onSelected: (_) => setState(() => _filterType = type),
      ),
    );
  }

  Widget _incidentCard(Incident inc) {
    Color statusCol;
    IconData statusIcon;
    switch (inc.status) {
      case 'open':
        statusCol = AppColors.error;
        statusIcon = Icons.error_outline_rounded;
        break;
      case 'investigating':
        statusCol = AppColors.accent;
        statusIcon = Icons.search_rounded;
        break;
      case 'resolved':
        statusCol = AppColors.success;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      default:
        statusCol = Colors.grey;
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inc.status == 'open'
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type & Status ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _typeColor(inc.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(inc.type), size: 18, color: _typeColor(inc.type)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inc.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(_typeLabel(inc.type), style: TextStyle(fontSize: 11, color: _typeColor(inc.type), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusCol),
                      const SizedBox(width: 4),
                      Text(inc.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusCol)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Description ──
            Text(inc.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 8),

            // ── Location & Reporter ──
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded, size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text('${inc.location} (Floor ${inc.floor})', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_rounded, size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(inc.reportedBy, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                ]),
                Text(_timeAgo(inc.reportedAt), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),

            // ── Resolution ──
            if (inc.resolution != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(child: Text(inc.resolution!, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
                  ],
                ),
              ),
            ],

            // ── Actions ──
            if (inc.status != 'resolved') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (inc.status == 'open')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => inc.status = 'investigating'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Investigate', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                      ),
                    ),
                  if (inc.status == 'open') const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _resolveDialog(inc),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(IncidentType t) {
    switch (t) {
      case IncidentType.missingProduct:
        return AppColors.error;
      case IncidentType.damagedProduct:
        return Colors.deepOrange;
      case IncidentType.locationConflict:
        return AppColors.accent;
      case IncidentType.bottleneck:
        return AppColors.aiBlue;
      case IncidentType.other:
        return Colors.red[900]!;
    }
  }

  IconData _typeIcon(IncidentType t) {
    switch (t) {
      case IncidentType.missingProduct:
        return Icons.search_off_rounded;
      case IncidentType.damagedProduct:
        return Icons.broken_image_rounded;
      case IncidentType.locationConflict:
        return Icons.swap_horiz_rounded;
      case IncidentType.bottleneck:
        return Icons.hourglass_top_rounded;
      case IncidentType.other:
        return Icons.report_problem_rounded;
    }
  }

  String _typeLabel(IncidentType t) {
    switch (t) {
      case IncidentType.missingProduct:
        return 'Missing Product';
      case IncidentType.damagedProduct:
        return 'Damaged Product';
      case IncidentType.locationConflict:
        return 'Location Conflict';
      case IncidentType.bottleneck:
        return 'Workflow Bottleneck';
      case IncidentType.other:
        return 'Other';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _resolveDialog(Incident inc) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Incident: ${inc.id}', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution notes',
                hintText: 'Describe how the incident was resolved...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resolution notes are required.'), backgroundColor: AppColors.error),
                );
                return;
              }
              setState(() {
                inc.status = 'resolved';
                inc.resolution = ctrl.text.trim();
                inc.resolvedAt = DateTime.now();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${inc.id} resolved.'), backgroundColor: AppColors.success),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _addIncident() {
    final descCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'A1-03');
    IncidentType selectedType = IncidentType.missingProduct;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Report New Incident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<IncidentType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: IncidentType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(_typeLabel(t), style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (v) => setDlgState(() => selectedType = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: zoneCtrl,
                decoration: const InputDecoration(labelText: 'Zone / Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the incident...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (descCtrl.text.trim().isEmpty) return;
                setState(() {
                  _incidents.insert(
                    0,
                    Incident(
                      id: 'INC-${1000 + _incidents.length}',
                      type: selectedType,
                      description: descCtrl.text.trim(),
                      location: zoneCtrl.text.trim(),
                      floor: 0,
                      reportedBy: 'Supervisor Karim',
                      reportedAt: DateTime.now(),
                      status: 'open',
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incident reported.'), backgroundColor: AppColors.primaryDark),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
