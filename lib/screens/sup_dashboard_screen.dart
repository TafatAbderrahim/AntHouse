import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  SUPERVISOR DASHBOARD — §7.2 steps 1-2, 4
//  Overview of operations, real-time monitoring:
//  • Receipt, storage, picking, delivery progress
//  • Employee activity
//  • Zone occupancy overview
// ═══════════════════════════════════════════════════════════════

class SupDashboardScreen extends StatefulWidget {
  const SupDashboardScreen({super.key});

  @override
  State<SupDashboardScreen> createState() => _SupDashboardScreenState();
}

class _SupDashboardScreenState extends State<SupDashboardScreen> {
  List<OperationalTask> tasks = [];
  List<Chariot> chariots = [];
  List<LiveWorker> workers = [];
  List<Incident> incidents = [];
  List<AiOperationalDecision> aiDecisions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    tasks = [];
    chariots = [];
    workers = [];
    incidents = [];
    aiDecisions = [];

    // Load live data
    try {
      final monResult = await ApiService.getWarehouseMonitoring();
      if (monResult['success'] == true && monResult['data'] != null) {
        final data = monResult['data'];
        // Update workers from API
        if (data['employees'] is List) {
          final empList = data['employees'] as List;
          workers = empList.map<LiveWorker>((e) => LiveWorker(
            id: e['id']?.toString() ?? '',
            name: e['name'] ?? e['fullName'] ?? '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'.trim(),
            role: (e['role'] ?? 'employee').toString().toLowerCase(),
            floor: e['floor'] ?? 0,
            x: (e['x'] ?? 10.0).toDouble(),
            y: (e['y'] ?? 10.0).toDouble(),
            currentTask: e['currentTask']?.toString() ?? '',
            status: e['status'] ?? 'active',
            color: const Color(0xFF2196F3),
          )).toList();
        }
        // Update chariots from API
        if (data['chariots'] is List) {
          final chrList = data['chariots'] as List;
          chariots = chrList.map<Chariot>((c) => Chariot(
            id: c['id']?.toString() ?? '',
            code: c['code'] ?? '',
            assignedOperation: c['assignedOperation'] ?? '',
            inUse: c['status'] == 'IN_USE' || c['inUse'] == true,
            assignedEmployeeId: c['assignedTo']?.toString() ?? '',
          )).toList();
        }
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

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.status == OpTaskStatus.completed).length;
    final activeTasks = tasks.where((t) => t.status == OpTaskStatus.inProgress).length;
    final pendingTasks = tasks.where((t) => t.status == OpTaskStatus.pending).length;
    final openIncidents = incidents.where((i) => i.status != 'resolved').length;
    final pendingAi = aiDecisions.where((d) => d.status == 'pending').length;
    final activeWorkers = workers.where((w) => w.status == 'active').length;
    final activeChariots = chariots.where((c) => c.inUse).length;

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        // ── Stat Cards ──
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(Icons.task_alt_rounded, 'Completed', '$completedTasks/$totalTasks', AppColors.success),
            _statCard(Icons.play_circle_rounded, 'Active', '$activeTasks', AppColors.aiBlue),
            _statCard(Icons.schedule_rounded, 'Pending', '$pendingTasks', const Color(0xFFFF9800)),
            _statCard(Icons.warning_rounded, 'Incidents', '$openIncidents', AppColors.error),
            _statCard(Icons.psychology_rounded, 'AI Pending', '$pendingAi', const Color(0xFF9C27B0)),
            _statCard(Icons.people_rounded, 'Workers', '$activeWorkers/${workers.length}', AppColors.primaryDark),
            _statCard(Icons.shopping_cart_rounded, 'Chariots', '$activeChariots/${chariots.length}', const Color(0xFFFF9800)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Operations Progress ──
        _sectionTitle('Operations Progress'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _operationRow(OpType.receipt, tasks),
              const SizedBox(height: 12),
              _operationRow(OpType.transfer, tasks),
              const SizedBox(height: 12),
              _operationRow(OpType.picking, tasks),
              const SizedBox(height: 12),
              _operationRow(OpType.delivery, tasks),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Active Workers ──
        _sectionTitle('Active Workers'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: workers.map((w) => _workerTile(w)).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Chariot Status ──
        _sectionTitle('Chariot Status (FR-30 to FR-34)'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: chariots.map((c) => _chariotTile(c)).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Recent AI Decisions ──
        _sectionTitle('AI Decisions Overview'),
        const SizedBox(height: 10),
        ...aiDecisions.map(_aiDecisionCard),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark));
  }

  Widget _operationRow(OpType op, List<OperationalTask> allTasks) {
    final opTasks = allTasks.where((t) => t.operation == op).toList();
    final done = opTasks.where((t) => t.status == OpTaskStatus.completed).length;
    final total = opTasks.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: op.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(op.icon, size: 16, color: op.color),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 70, child: Text(op.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(op.color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$done/$total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: op.color)),
      ],
    );
  }

  Widget _workerTile(LiveWorker w) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: w.color,
        radius: 16,
        child: Text(w.name[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(
        w.currentTask.isNotEmpty ? w.currentTask : 'Idle',
        style: TextStyle(fontSize: 11, color: w.currentTask.isNotEmpty ? AppColors.textMid : AppColors.textLight),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('F${w.floor}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: w.status == 'active' ? AppColors.success : (w.status == 'idle' ? AppColors.textLight : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chariotTile(Chariot c) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (c.inUse ? AppColors.aiBlue : AppColors.textLight).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.shopping_cart_rounded, size: 16, color: c.inUse ? AppColors.aiBlue : AppColors.textLight),
      ),
      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(
        c.inUse ? c.assignedOperation : 'Available',
        style: TextStyle(fontSize: 11, color: c.inUse ? AppColors.textMid : AppColors.textLight),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (c.inUse ? AppColors.aiBlue : AppColors.success).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          c.inUse ? 'In Use · F${c.currentFloor}' : 'Free',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: c.inUse ? AppColors.aiBlue : AppColors.success,
          ),
        ),
      ),
    );
  }

  Widget _aiDecisionCard(AiOperationalDecision d) {
    Color statusColor;
    switch (d.status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'overridden':
        statusColor = AppColors.accent;
        break;
      default:
        statusColor = AppColors.aiBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: d.orderType.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d.orderRef, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: d.orderType.color)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(d.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Confidence: ${(d.confidence * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
          if (d.overrideJustification != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Override: ${d.overrideJustification}', style: const TextStyle(fontSize: 11, color: AppColors.accent))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
