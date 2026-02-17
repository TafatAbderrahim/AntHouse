import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _range;
  Map<String, dynamic>? _productivity;
  Map<String, dynamic>? _stockMovements;
  bool _loadingProductivity = false;
  bool _loadingStock = false;

  String get _start => _range != null
      ? '${_range!.start.year}-${_range!.start.month.toString().padLeft(2, '0')}-${_range!.start.day.toString().padLeft(2, '0')}'
      : '';
  String get _end => _range != null
      ? '${_range!.end.year}-${_range!.end.month.toString().padLeft(2, '0')}-${_range!.end.day.toString().padLeft(2, '0')}'
      : '';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange:
          _range ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _fetchProductivity() async {
    if (_range == null) {
      _pickRange();
      return;
    }
    setState(() => _loadingProductivity = true);
    try {
      final result = await ApiService.getReportUserProductivity(
        startDate: _start,
        endDate: _end,
      );
      if (result['success'] == true) {
        setState(
          () => _productivity = result['data'] is Map
              ? result['data'] as Map<String, dynamic>
              : {'raw': result['data']},
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _loadingProductivity = false);
  }

  Future<void> _fetchStockMovements() async {
    if (_range == null) {
      _pickRange();
      return;
    }
    setState(() => _loadingStock = true);
    try {
      final result = await ApiService.getReportStockMovements(
        startDate: _start,
        endDate: _end,
      );
      if (result['success'] == true) {
        setState(
          () => _stockMovements = result['data'] is Map
              ? result['data'] as Map<String, dynamic>
              : {'raw': result['data']},
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _loadingStock = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range picker
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _range != null ? '$_start  →  $_end' : 'Select date range',
                  style: TextStyle(
                    fontSize: 14,
                    color: _range != null
                        ? AppColors.textDark
                        : AppColors.textMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Pick Range'),
                onPressed: _pickRange,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // User Productivity
        _buildSection(
          title: 'User Productivity',
          icon: Icons.people_alt_rounded,
          color: AppColors.aiBlue,
          loading: _loadingProductivity,
          data: _productivity,
          onFetch: _fetchProductivity,
        ),
        const SizedBox(height: 16),

        // Stock Movements
        _buildSection(
          title: 'Stock Movements',
          icon: Icons.swap_vert_rounded,
          color: AppColors.accent,
          loading: _loadingStock,
          data: _stockMovements,
          onFetch: _fetchStockMovements,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool loading,
    required Map<String, dynamic>? data,
    required VoidCallback onFetch,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                onPressed: loading ? null : onFetch,
                style: FilledButton.styleFrom(backgroundColor: color),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Generate'),
              ),
            ],
          ),
          if (data != null) ...[
            const Divider(height: 20),
            ..._renderData(data),
          ],
        ],
      ),
    );
  }

  List<Widget> _renderData(Map<String, dynamic> data) {
    final widgets = <Widget>[];
    for (final entry in data.entries) {
      if (entry.value is List) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _formatKey(entry.key),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        );
        for (final item in entry.value as List) {
          if (item is Map) {
            widgets.add(
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (item as Map<String, dynamic>).entries
                      .map(
                        (e) => Text(
                          '${_formatKey(e.key)}: ${e.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMid,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          } else {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(
                  '• $item',
                  style: TextStyle(fontSize: 12, color: AppColors.textMid),
                ),
              ),
            );
          }
        }
      } else if (entry.value is Map) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _formatKey(entry.key),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        );
        widgets.addAll(_renderData(entry.value as Map<String, dynamic>));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatKey(entry.key),
                    style: TextStyle(fontSize: 12, color: AppColors.textMid),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
