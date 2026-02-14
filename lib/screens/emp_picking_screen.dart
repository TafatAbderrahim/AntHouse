import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';

// ═══════════════════════════════════════════════════════════════
//  EMPLOYEE PICKING ASSIGNMENT — §7.1 step 5
//  • Receive Picking Orders optimized by AI agent
//  • Instructions specify exact picking rack locations
//  • Retrieve products from storage
//  • Place products into designated picking racks
// ═══════════════════════════════════════════════════════════════

class EmpPickingScreen extends StatefulWidget {
  final List<OperationalTask> tasks;
  final VoidCallback onTaskUpdated;

  const EmpPickingScreen({super.key, required this.tasks, required this.onTaskUpdated});

  @override
  State<EmpPickingScreen> createState() => _EmpPickingScreenState();
}

class _EmpPickingScreenState extends State<EmpPickingScreen> {
  List<OperationalTask> get _pickingTasks =>
      widget.tasks.where((t) => t.operation == OpType.picking).toList();

  @override
  Widget build(BuildContext context) {
    final tasks = _pickingTasks;

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
                  color: OpType.picking.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(OpType.picking.icon, color: OpType.picking.color, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Picking Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text('Pick products & place in designated racks', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── AI Optimized Banner ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.route_rounded, color: Color(0xFF6A1B9A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Routes are AI-optimized for shortest distance to expedition zone.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Task List ──
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No picking tasks assigned.', style: TextStyle(color: AppColors.textMid)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _buildPickingCard(tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingCard(OperationalTask task) {
    final isCompleted = task.status == OpTaskStatus.completed;
    final isActive = task.status == OpTaskStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? OpType.picking.color.withValues(alpha: 0.4)
              : isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
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
                    color: OpType.picking.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.orderRef, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OpType.picking.color)),
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

            // ── Route: Storage → Picking Rack ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _routeStep(Icons.warehouse_rounded, 'Pick from Storage', task.fromLocation, const Color(0xFF6A1B9A)),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Container(width: 2, height: 20, color: AppColors.divider),
                        const SizedBox(width: 12),
                        Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.textLight),
                      ],
                    ),
                  ),
                  _routeStep(Icons.shelves, 'Place in Picking Rack', task.toLocation, AppColors.success),
                ],
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 12),

              // ── Progress ──
              Row(
                children: [
                  Text('Progress: ${task.receivedQuantity}/${task.expectedQuantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(OpType.picking.color),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Qty buttons ──
              Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    if (task.receivedQuantity > 0) {
                      setState(() => task.receivedQuantity -= 10);
                      if (task.receivedQuantity < 0) task.receivedQuantity = 0;
                      widget.onTaskUpdated();
                    }
                  }),
                  const SizedBox(width: 8),
                  _qtyBtn(Icons.add, () {
                    setState(() {
                      task.receivedQuantity += 10;
                      if (task.receivedQuantity > task.expectedQuantity) {
                        task.receivedQuantity = task.expectedQuantity;
                      }
                    });
                    widget.onTaskUpdated();
                  }),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => task.receivedQuantity = task.expectedQuantity);
                      widget.onTaskUpdated();
                    },
                    child: const Text('All picked', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],

            if (!isCompleted) ...[
              const SizedBox(height: 12),
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
                        label: const Text('Start Picking'),
                        style: FilledButton.styleFrom(
                          backgroundColor: OpType.picking.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (task.status == OpTaskStatus.inProgress)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: task.receivedQuantity >= task.expectedQuantity
                            ? () => _completePicking(task)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Complete Picking'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
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
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Products placed in picking rack', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeStep(IconData icon, String title, String location, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18, color: AppColors.primaryDark)),
      ),
    );
  }

  void _completePicking(OperationalTask task) {
    setState(() {
      task.status = OpTaskStatus.completed;
      task.completedAt = DateTime.now();
    });
    widget.onTaskUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Picking ${task.orderRef} completed — ${task.expectedQuantity} placed at ${task.toLocation}.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
