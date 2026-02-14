import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';

// ═══════════════════════════════════════════════════════════════
//  EMPLOYEE DELIVERY EXECUTION — §7.1 step 6
//  • Transport picked products to the expedition track
//  • Confirm delivery placement
//  • Validate task completion (Delivery Validation / Failure)
//  • FR-43: Record Delivery Validation
// ═══════════════════════════════════════════════════════════════

class EmpDeliveryScreen extends StatefulWidget {
  final List<OperationalTask> tasks;
  final VoidCallback onTaskUpdated;

  const EmpDeliveryScreen({super.key, required this.tasks, required this.onTaskUpdated});

  @override
  State<EmpDeliveryScreen> createState() => _EmpDeliveryScreenState();
}

class _EmpDeliveryScreenState extends State<EmpDeliveryScreen> {
  List<OperationalTask> get _deliveryTasks =>
      widget.tasks.where((t) => t.operation == OpType.delivery).toList();

  @override
  Widget build(BuildContext context) {
    final tasks = _deliveryTasks;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OpType.delivery.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(OpType.delivery.icon, color: OpType.delivery.color, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Execution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text('Transport to expedition & confirm delivery', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Info Banner ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_rounded, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transport products to expedition track and confirm delivery.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Task List ──
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No delivery tasks assigned.', style: TextStyle(color: AppColors.textMid)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _buildDeliveryCard(tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(OperationalTask task) {
    final isCompleted = task.status == OpTaskStatus.completed;
    final isFailed = task.status == OpTaskStatus.failed;
    final isActive = task.status == OpTaskStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : isFailed
                  ? AppColors.error.withValues(alpha: 0.3)
                  : isActive
                      ? OpType.delivery.color.withValues(alpha: 0.4)
                      : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OpType.delivery.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.orderRef, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OpType.delivery.color)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: task.status.color)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Product ──
            Text(task.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('${task.sku} · ${task.expectedQuantity} units', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 12),

            // ── Route ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PICKING RACK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shelves, size: 14, color: Color(0xFF6A1B9A)),
                            const SizedBox(width: 4),
                            Text(task.fromLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.textMid),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPEDITION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(task.toLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!isCompleted && !isFailed) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (task.status == OpTaskStatus.pending)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            task.status = OpTaskStatus.inProgress;
                            task.startedAt = DateTime.now();
                          });
                          widget.onTaskUpdated();
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start Delivery'),
                        style: FilledButton.styleFrom(
                          backgroundColor: OpType.delivery.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (task.status == OpTaskStatus.inProgress) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _validateDelivery(task),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Validate Delivery'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _failDelivery(task),
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.error),
                      label: const Text('Fail', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ],
              ),
            ],

            if (isCompleted) ...[
              const SizedBox(height: 10),
              _resultBanner(
                Icons.check_circle_rounded,
                'Delivery validated successfully',
                AppColors.success,
              ),
            ],

            if (isFailed) ...[
              const SizedBox(height: 10),
              _resultBanner(
                Icons.cancel_rounded,
                'Delivery failed${task.discrepancyNote != null ? ': ${task.discrepancyNote}' : ''}',
                AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultBanner(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _validateDelivery(OperationalTask task) {
    setState(() {
      task.status = OpTaskStatus.completed;
      task.completedAt = DateTime.now();
      task.receivedQuantity = task.expectedQuantity;
    });
    widget.onTaskUpdated();

    // Show success dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
        title: const Text('Delivery Validated!'),
        content: Text('${task.orderRef}\n${task.productName}\n${task.expectedQuantity} units delivered to ${task.toLocation}.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _failDelivery(OperationalTask task) {
    showDialog(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Record Delivery Failure'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Failure Reason',
              hintText: 'Describe what went wrong...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  task.status = OpTaskStatus.failed;
                  task.completedAt = DateTime.now();
                  task.discrepancyNote = ctrl.text.isEmpty ? 'Delivery failed' : ctrl.text;
                });
                widget.onTaskUpdated();
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Submit Failure'),
            ),
          ],
        );
      },
    );
  }
}
