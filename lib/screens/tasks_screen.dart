import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getAdminTasks();
      if (result['success'] == true && result['data'] != null) {
        final content = result['data']['content'] ?? result['data'];
        if (content is List) {
          setState(() {
            _tasks = content.cast<Map<String, dynamic>>();
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
    return _tasks.where((t) {
      if (_statusFilter != 'all' && (t['status'] ?? '').toString().toUpperCase() != _statusFilter) return false;
      if (_typeFilter != 'all' && (t['type'] ?? '').toString().toUpperCase() != _typeFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _showCreateDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No tasks found', style: TextStyle(color: AppColors.textMid, fontSize: 15)))),
            ...filtered.map(_buildTaskCard),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('All', 'all', _statusFilter, (v) => setState(() => _statusFilter = v)),
        _chip('Pending', 'PENDING', _statusFilter, (v) => setState(() => _statusFilter = v)),
        _chip('In Progress', 'IN_PROGRESS', _statusFilter, (v) => setState(() => _statusFilter = v)),
        _chip('Completed', 'COMPLETED', _statusFilter, (v) => setState(() => _statusFilter = v)),
        const SizedBox(width: 12),
        _chip('All Types', 'all', _typeFilter, (v) => setState(() => _typeFilter = v)),
        _chip('Receipt', 'RECEIPT', _typeFilter, (v) => setState(() => _typeFilter = v)),
        _chip('Picking', 'PICKING', _typeFilter, (v) => setState(() => _typeFilter = v)),
        _chip('Transfer', 'TRANSFER', _typeFilter, (v) => setState(() => _typeFilter = v)),
        _chip('Delivery', 'DELIVERY', _typeFilter, (v) => setState(() => _typeFilter = v)),
      ],
    );
  }

  Widget _chip(String label, String value, String current, ValueChanged<String> onTap) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? Colors.white : AppColors.textDark)),
      selected: selected,
      selectedColor: AppColors.primaryDark,
      backgroundColor: AppColors.card,
      onSelected: (_) => onTap(value),
      side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.divider),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> t) {
    final status = (t['status'] ?? 'PENDING').toString().toUpperCase();
    final type = (t['type'] ?? '').toString();
    final statusColor = status == 'COMPLETED' ? AppColors.success : status == 'IN_PROGRESS' ? AppColors.aiBlue : status == 'FAILED' ? AppColors.error : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(type, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600))),
            const Spacer(),
            Text(t['id']?.toString().substring(0, 8) ?? '', style: TextStyle(fontSize: 11, color: AppColors.textMid)),
          ]),
          const SizedBox(height: 8),
          if (t['description'] != null) Text(t['description'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppColors.textMid),
            const SizedBox(width: 4),
            Text(t['assignedTo']?['fullName'] ?? t['assignedToName'] ?? 'Unassigned', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
            const Spacer(),
            if (t['createdAt'] != null) Text(_formatDate(t['createdAt'].toString()), style: TextStyle(fontSize: 11, color: AppColors.textMid)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(icon: const Icon(Icons.person_add_outlined, size: 16), label: const Text('Assign', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.aiBlue, padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _showAssignDialog(t)),
            TextButton.icon(icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _showUpdateDialog(t)),
            TextButton.icon(icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _deleteTask(t['id']?.toString() ?? '')),
          ]),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String id) async {
    if (id.isEmpty) return;
    try {
      await ApiService.adminDeleteTask(id);
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreateDialog() {
    final typeCtrl = ValueNotifier('RECEIPT');
    final priorityCtrl = ValueNotifier('MEDIUM');
    final notesCtrl = TextEditingController();
    final productIdCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Task'),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<String>(
            valueListenable: typeCtrl,
            builder: (_, val, __) => DropdownButtonFormField<String>(
              initialValue: val,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['RECEIPT', 'TRANSFER', 'PICKING', 'DELIVERY', 'ADJUSTMENT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => typeCtrl.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: priorityCtrl,
            builder: (_, val, __) => DropdownButtonFormField<String>(
              initialValue: val,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => priorityCtrl.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: productIdCtrl, decoration: const InputDecoration(labelText: 'Product ID (UUID)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (productIdCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product ID is required'), backgroundColor: AppColors.error));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.adminCreateTask({
                  'type': typeCtrl.value,
                  'priority': priorityCtrl.value,
                  'notes': notesCtrl.text,
                  'lines': [{'productId': productIdCtrl.text.trim(), 'quantity': int.tryParse(qtyCtrl.text) ?? 1}],
                });
                _fetch();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> t) {
    final userIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Task'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Task: ${t['id']?.toString().substring(0, 8) ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 12),
            TextField(controller: userIdCtrl, decoration: const InputDecoration(labelText: 'User ID (UUID)', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (userIdCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID required'), backgroundColor: AppColors.error));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.assignTask(t['id'].toString(), userIdCtrl.text.trim());
                _fetch();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task assigned'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(Map<String, dynamic> t) {
    final statusCtrl = ValueNotifier(t['status']?.toString() ?? 'PENDING');
    final priorityCtrl = ValueNotifier(t['priority']?.toString() ?? 'MEDIUM');
    final notesCtrl = TextEditingController(text: t['notes']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Task'),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<String>(
            valueListenable: statusCtrl,
            builder: (_, val, __) => DropdownButtonFormField<String>(
              value: val,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => statusCtrl.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: priorityCtrl,
            builder: (_, val, __) => DropdownButtonFormField<String>(
              value: val,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => priorityCtrl.value = v!,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.adminUpdateTask(t['id'].toString(), {
                  'status': statusCtrl.value,
                  'priority': priorityCtrl.value,
                  'notes': notesCtrl.text,
                });
                _fetch();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
