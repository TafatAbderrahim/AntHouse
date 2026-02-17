import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  EMPLOYEE DASHBOARD — §7.1 steps 1-2
//  Shows assigned operational tasks for the day.
//  Employee does NOT see AI logic or overrides (FR-6).
// ═══════════════════════════════════════════════════════════════

class EmpDashboardScreen extends StatelessWidget {
  final List<OperationalTask> tasks;
  final bool isOnline;
  final void Function(int) onNavigate;

  const EmpDashboardScreen({
    super.key,
    required this.tasks,
    required this.isOnline,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.status == OpTaskStatus.completed).length;
    final inProgress = tasks.where((t) => t.status == OpTaskStatus.inProgress).length;
    final pending = tasks.where((t) => t.status == OpTaskStatus.pending).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_greeting()}, ${ApiService.currentFirstName ?? 'Employee'}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(DateTime.now())} · Depot B7',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMid),
                  ),
                ],
              ),
            ),
            _onlineBadge(isOnline),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.textMid),
              onPressed: () {
                ApiService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── FR-6 Banner ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You see validated orders only (FR-6). All tasks are final.',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Progress Card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF006D84), Color(0xFF0E93AF)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today\'s Progress', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFAC460)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completed completed · $inProgress active · $pending pending',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Operations Summary Cards ──
        const Text('Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _opCard(OpType.receipt, 1)),
            const SizedBox(width: 10),
            Expanded(child: _opCard(OpType.transfer, 2)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _opCard(OpType.picking, 3)),
            const SizedBox(width: 10),
            Expanded(child: _opCard(OpType.delivery, 4)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Active Tasks ──
        const Text('Active Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        ...tasks
            .where((t) => t.status == OpTaskStatus.inProgress)
            .map((t) => _activeTaskCard(t)),
        if (tasks.where((t) => t.status == OpTaskStatus.inProgress).isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text('No active tasks. Start from the operation tabs.', style: TextStyle(color: AppColors.textMid)),
            ),
          ),
      ],
    );
  }

  Widget _opCard(OpType op, int navIndex) {
    final opTasks = tasks.where((t) => t.operation == op).toList();
    final done = opTasks.where((t) => t.status == OpTaskStatus.completed).length;
    final total = opTasks.length;

    return GestureDetector(
      onTap: () => onNavigate(navIndex),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: op.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(op.icon, size: 22, color: op.color),
            ),
            const SizedBox(height: 12),
            Text(op.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('$done / $total completed', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 4,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(op.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeTaskCard(OperationalTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: task.operation.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: task.operation.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(task.operation.icon, color: task.operation.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.orderRef, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(task.productName, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${task.receivedQuantity}/${task.expectedQuantity}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: task.operation.color)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progress,
                          minHeight: 4,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(task.operation.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _onlineBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isOnline ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isOnline ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? AppColors.success : AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
