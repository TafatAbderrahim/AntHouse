import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  EMPLOYEE RECEIPT — §7.1 step 3
//  • Check whether commanded products have physically arrived
//  • Count received quantities
//  • Record received stock in the system
//  • Flag discrepancies if quantities differ
// ═══════════════════════════════════════════════════════════════

class EmpReceiptScreen extends StatefulWidget {
  final List<OperationalTask> tasks;
  final VoidCallback onTaskUpdated;

  const EmpReceiptScreen({super.key, required this.tasks, required this.onTaskUpdated});

  @override
  State<EmpReceiptScreen> createState() => _EmpReceiptScreenState();
}

class _EmpReceiptScreenState extends State<EmpReceiptScreen> {
  List<OperationalTask> get _receiptTasks =>
      widget.tasks.where((t) => t.operation == OpType.receipt).toList();

  @override
  Widget build(BuildContext context) {
    final tasks = _receiptTasks;

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
                  color: OpType.receipt.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(OpType.receipt.icon, color: OpType.receipt.color, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text('Receive & validate incoming merchandise', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
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
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check products, count quantities, and flag any discrepancies.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Task List ──
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No receipt tasks assigned.', style: TextStyle(color: AppColors.textMid)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _buildTaskCard(tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(OperationalTask task) {
    final isCompleted = task.status == OpTaskStatus.completed;
    final isActive = task.status == OpTaskStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? OpType.receipt.color.withValues(alpha: 0.4)
              : isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.divider,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: OpType.receipt.color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order ref + status ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OpType.receipt.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.orderRef, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OpType.receipt.color)),
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

            // ── Product Info ──
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.textMid),
                const SizedBox(width: 6),
                Text(task.sku, style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(task.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),

            // ── Quantities ──
            Row(
              children: [
                Flexible(child: _infoChip(Icons.arrow_downward_rounded, 'Expected: ${task.expectedQuantity}', const Color(0xFF1565C0))),
                const SizedBox(width: 8),
                Flexible(child: _infoChip(Icons.place_rounded, task.toLocation, const Color(0xFF6A1B9A))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(child: _infoChip(Icons.local_shipping_outlined, 'From: ${task.fromLocation}', AppColors.textMid)),
                const Spacer(),
                if (task.assignedChariotId.isNotEmpty)
                  Flexible(child: _infoChip(Icons.shopping_cart_outlined, task.assignedChariotId, AppColors.textMid)),
              ],
            ),

            if (!isCompleted) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // ── Received quantity input ──
              Row(
                children: [
                  const Flexible(
                    child: Text('Received Qty:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 12),
                  _qtyButton(Icons.remove, () {
                    if (task.receivedQuantity > 0) {
                      setState(() => task.receivedQuantity--);
                      widget.onTaskUpdated();
                    }
                  }),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${task.receivedQuantity}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: task.hasDiscrepancy ? AppColors.error : AppColors.textDark,
                      ),
                    ),
                  ),
                  _qtyButton(Icons.add, () {
                    setState(() => task.receivedQuantity++);
                    widget.onTaskUpdated();
                  }),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        setState(() => task.receivedQuantity = task.expectedQuantity);
                        widget.onTaskUpdated();
                      },
                      child: const Text('= Expected', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),

              if (task.hasDiscrepancy) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Discrepancy: expected ${task.expectedQuantity}, received ${task.receivedQuantity}',
                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ── Action Buttons ──
              Row(
                children: [
                  if (task.status == OpTaskStatus.pending)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          setState(() {
                            task.status = OpTaskStatus.inProgress;
                            task.startedAt = DateTime.now();
                          });
                          widget.onTaskUpdated();
                          try {
                            await ApiService.startOperation({
                              'taskId': task.id,
                              'type': 'RECEIPT',
                            });
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start Receipt'),
                        style: FilledButton.styleFrom(
                          backgroundColor: OpType.receipt.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (task.status == OpTaskStatus.inProgress) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: task.receivedQuantity > 0
                            ? () => _confirmReceipt(task)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Validate Receipt'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.hasDiscrepancy)
                      OutlinedButton.icon(
                        onPressed: () => _flagDiscrepancy(task),
                        icon: const Icon(Icons.flag_rounded, size: 18, color: AppColors.error),
                        label: const Text('Flag', style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ],
              ),
            ],

            if (isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Received ${task.receivedQuantity}/${task.expectedQuantity} units',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                    if (task.discrepancyNote != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.warning_rounded, size: 14, color: AppColors.accent),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
      ),
    );
  }

  void _confirmReceipt(OperationalTask task) async {
    try {
      await ApiService.executeLine({
        'taskId': task.id,
        'productId': task.productId,
        'quantity': task.receivedQuantity,
        'type': 'RECEIPT',
      });
      await ApiService.completeOperation(task.id);
    } catch (_) {}
    setState(() {
      task.status = OpTaskStatus.completed;
      task.completedAt = DateTime.now();
      if (task.hasDiscrepancy) {
        task.status = OpTaskStatus.discrepancy;
        task.discrepancyNote = 'Expected ${task.expectedQuantity}, received ${task.receivedQuantity}';
      }
    });
    widget.onTaskUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt ${task.orderRef} validated — ${task.receivedQuantity} units recorded.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _flagDiscrepancy(OperationalTask task) {
    showDialog(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController(
          text: 'Expected ${task.expectedQuantity}, received ${task.receivedQuantity}',
        );
        return AlertDialog(
          title: const Text('Flag Discrepancy'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Discrepancy Note',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                setState(() {
                  task.discrepancyNote = ctrl.text;
                  task.status = OpTaskStatus.discrepancy;
                  task.completedAt = DateTime.now();
                });
                widget.onTaskUpdated();
                Navigator.pop(context);
                try {
                  await ApiService.reportIssue({
                    'taskId': task.id,
                    'type': 'DISCREPANCY',
                    'description': ctrl.text,
                    'expectedQuantity': task.expectedQuantity,
                    'actualQuantity': task.receivedQuantity,
                  });
                } catch (_) {}
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discrepancy flagged and logged.'), backgroundColor: AppColors.accent),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Submit Flag'),
            ),
          ],
        );
      },
    );
  }
}
