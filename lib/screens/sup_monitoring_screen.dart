import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import 'warehouse_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  SUPERVISOR LIVE MONITORING — §7.2 step 4 (Merged with Warehouse Map)
//  • REAL interactive warehouse map (WarehouseScreen) as the core
//  • Live worker / chariot tracking overlay panels
//  • Summary ribbon with stats
// ═══════════════════════════════════════════════════════════════

class SupMonitoringScreen extends StatefulWidget {
  const SupMonitoringScreen({super.key});

  @override
  State<SupMonitoringScreen> createState() => _SupMonitoringScreenState();
}

class _SupMonitoringScreenState extends State<SupMonitoringScreen> {
  late final List<LiveWorker> _workers;
  late final List<Chariot> _chariots;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _workers = MockOperationsData.generateLiveWorkers();
    _chariots = MockOperationsData.generateChariots();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 1100;
    final activeWorkers = _workers.where((w) => w.status == 'active').length;
    final busyChariots = _chariots.where((c) => c.inUse).length;

    return Column(
      children: [
        // ── Summary ribbon ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.primaryDark.withValues(alpha: 0.04),
          child: Row(
            children: [
              const Icon(Icons.satellite_alt_rounded, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Live Map — Real-time Warehouse View',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
              Flexible(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _statChip('Workers', '$activeWorkers/${_workers.length}', AppColors.primary, Icons.people_rounded),
                  const SizedBox(width: 10),
                  _statChip('Chariots', '$busyChariots/${_chariots.length}', AppColors.accent, Icons.local_shipping_rounded),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                        const SizedBox(width: 5),
                        const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_showPanel ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left, size: 20),
                    tooltip: _showPanel ? 'Hide panel' : 'Show panel',
                    onPressed: () => setState(() => _showPanel = !_showPanel),
                  ),
                ]),
              )),
            ],
          ),
        ),

        // ── Main content: Warehouse map + side panel ──
        Expanded(
          child: isWide
              ? Row(
                  children: [
                    // Full interactive warehouse map
                    Expanded(
                      flex: _showPanel ? 3 : 1,
                      child: const WarehouseScreen(),
                    ),
                    // Side panel: workers + chariots
                    if (_showPanel)
                      SizedBox(
                        width: 340,
                        child: _buildSidePanel(),
                      ),
                  ],
                )
              : Column(
                  children: [
                    // Warehouse map takes most of the space
                    const Expanded(
                      flex: 3,
                      child: WarehouseScreen(),
                    ),
                    // Bottom panel: workers + chariots
                    if (_showPanel)
                      SizedBox(
                        height: 240,
                        child: _buildSidePanel(),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
        ],
      ),
    );
  }

  // ── Side Panel: Workers + Chariots lists ──
  Widget _buildSidePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
            ),
            child: const Row(
              children: [
                Icon(Icons.groups_rounded, size: 18, color: AppColors.primaryDark),
                SizedBox(width: 8),
                Text('Live Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
          ),
          // Workers section
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.people_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text('Active Workers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const Spacer(),
                      Text('${_workers.where((w) => w.status == 'active').length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _workers.length,
                    itemBuilder: (_, i) => _workerTile(_workers[i]),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          // Chariots section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      const Text('Chariot Fleet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const Spacer(),
                      Text('${_chariots.where((c) => c.inUse).length} in use',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _chariots.length,
                    itemBuilder: (_, i) => _chariotTile(_chariots[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact worker tile ──
  Widget _workerTile(LiveWorker w) {
    final isActive = w.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.04) : AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar with status dot
          Stack(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(w.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.success : Colors.grey,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 10, color: AppColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(width: 2),
                    Text('${w.floor == 0 ? 'RDC' : 'Ét.${w.floor}'} · X:${w.x.toInt()} Y:${w.y.toInt()}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _taskColor(w.currentTask).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(w.currentTask, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _taskColor(w.currentTask))),
          ),
        ],
      ),
    );
  }

  // ── Compact chariot tile ──
  Widget _chariotTile(Chariot c) {
    final statusCol = c.inUse ? AppColors.success : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, size: 16, color: statusCol),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text(
                  '${c.currentFloor == 0 ? 'RDC' : 'Ét.${c.currentFloor}'}${c.assignedEmployeeId.isNotEmpty ? ' · ${c.assignedEmployeeId}' : ''}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMid),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusCol.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              c.inUse ? 'IN USE' : 'IDLE',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusCol),
            ),
          ),
        ],
      ),
    );
  }

  Color _taskColor(String task) {
    switch (task.toLowerCase()) {
      case 'picking': return Colors.deepOrange;
      case 'receipt': return AppColors.primary;
      case 'transfer': return AppColors.aiBlue;
      case 'delivery': return AppColors.success;
      case 'idle': return Colors.grey;
      default: return AppColors.textMid;
    }
  }
}
