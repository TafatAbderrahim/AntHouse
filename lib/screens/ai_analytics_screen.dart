import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';
import '../widgets/mini_charts.dart';

class AiAnalyticsScreen extends StatefulWidget {
  const AiAnalyticsScreen({super.key});
  @override
  State<AiAnalyticsScreen> createState() => _AiAnalyticsScreenState();
}

class _AiAnalyticsScreenState extends State<AiAnalyticsScreen> {
  late List<AiDecision> decisions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDecisions();
  }

  Future<void> _fetchDecisions() async {
    try {
      final list = await ApiService.getAiDecisions();
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          decisions = list.map<AiDecision>((d) => AiDecision(
            id: d['id']?.toString(),
            action: d['decisionType'] ?? d['action'] ?? 'optimize',
            description: d['description'] ?? d['recommendation'] ?? '',
            timestamp: d['createdAt'] != null ? DateTime.tryParse(d['createdAt'].toString()) : null,
            status: (d['status'] ?? 'pending').toString().toLowerCase(),
            confidence: (d['confidence'] ?? 0.85).toDouble(),
            userName: d['userName'] ?? d['createdBy'] ?? 'AI Engine',
          )).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      decisions = [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final approved = decisions.where((d) => d.status == 'approved').length;
    final overridden = decisions.where((d) => d.status == 'overridden').length;
    final pending = decisions.where((d) => d.status == 'pending').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ═══ METRIC CARDS ═══
        _buildMetricCards(decisions, approved, overridden),
        const SizedBox(height: 20),

        // ═══ CHARTS ═══
        LayoutBuilder(builder: (ctx, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccuracyCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildOverrideCard(approved, overridden, pending)),
              ],
            );
          }
          return Column(children: [
            _buildAccuracyCard(),
            const SizedBox(height: 14),
            _buildOverrideCard(approved, overridden, pending),
          ]);
        }),
        const SizedBox(height: 20),

        // ═══ EFFICIENCY GAUGES ═══
        _buildEfficiencyRow(),
        const SizedBox(height: 20),

        // ═══ RECENT DECISIONS TABLE ═══
        _buildDecisionsCard(decisions),
      ],
    );
  }

  // ═══════════════════ METRIC CARDS ═══════════════════

  Widget _buildMetricCards(List<AiDecision> decisions, int approved, int overridden) {
    final total = decisions.length;
    final avgConf = decisions.isEmpty ? 0.0 : decisions.fold<double>(0, (s, d) => s + d.confidence) / total;

    final cards = [
      _MData(Icons.psychology_rounded, 'Forecast Accuracy', '91.2%', AppColors.aiBlue),
      _MData(Icons.route_rounded, 'Avg. Pick Distance', '12.4m', AppColors.primary),
      _MData(Icons.storage_rounded, 'Storage Efficiency', '87.6%', AppColors.success),
      _MData(Icons.compare_arrows_rounded, 'Override Rate', '${total > 0 ? (overridden / total * 100).toStringAsFixed(1) : 0}%', AppColors.accent),
      _MData(Icons.trending_up_rounded, 'Avg. Confidence', '${(avgConf * 100).toStringAsFixed(1)}%', AppColors.primaryDark),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 1000 ? 5 : c.maxWidth > 600 ? 3 : 2;
      return Wrap(
        spacing: 14, runSpacing: 14,
        children: cards.map((m) {
          final w = (c.maxWidth - 14 * (cols - 1)) / cols;
          return SizedBox(width: w, child: _metricCard(m));
        }).toList(),
      );
    });
  }

  Widget _metricCard(_MData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: data.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(data.icon, size: 22, color: data.color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: data.color), overflow: TextOverflow.ellipsis),
          Text(data.label, style: const TextStyle(fontSize: 11, color: AppColors.textLight), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════════ ACCURACY CHART ═══════════════════

  Widget _buildAccuracyCard() {
    final data = [85.0, 87.0, 86.5, 88.0, 89.2, 90.1, 89.5, 91.0, 90.8, 91.5, 91.2, 92.0];
    final labels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.show_chart_rounded, size: 18, color: AppColors.aiBlue),
          SizedBox(width: 8),
          Text('Forecast Accuracy Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        SparkAreaChart(data: data, labels: labels, color: AppColors.aiBlue, height: 180),
      ]),
    );
  }

  // ═══════════════════ OVERRIDE DISTRIBUTION ═══════════════════

  Widget _buildOverrideCard(int approved, int overridden, int pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Decision Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 20),
        Center(
          child: DonutChart(
            segments: [
              DonutSegment('Approved', approved.toDouble(), AppColors.success),
              DonutSegment('Overridden', overridden.toDouble(), AppColors.accent),
              DonutSegment('Pending', pending.toDouble(), AppColors.aiBlue),
            ],
            size: 150,
            centerValue: '${approved + overridden + pending}',
            centerLabel: 'decisions',
          ),
        ),
        const SizedBox(height: 16),
        _legendRow('Approved', approved, AppColors.success),
        _legendRow('Overridden', overridden, AppColors.accent),
        _legendRow('Pending', pending, AppColors.aiBlue),
      ]),
    );
  }

  Widget _legendRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid))),
        Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ═══════════════════ EFFICIENCY GAUGES ═══════════════════

  Widget _buildEfficiencyRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.speed_rounded, size: 18, color: AppColors.success),
          SizedBox(width: 8),
          Text('System Efficiency Metrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (ctx, c) {
          return Wrap(
            spacing: 24, runSpacing: 16,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              ProgressGauge(value: 0.876, color: AppColors.success, size: 110, label: 'Storage'),
              ProgressGauge(value: 0.912, color: AppColors.aiBlue, size: 110, label: 'Forecast'),
              ProgressGauge(value: 0.945, color: AppColors.primary, size: 110, label: 'Picking'),
              ProgressGauge(value: 0.823, color: AppColors.accent, size: 110, label: 'Routing'),
            ],
          );
        }),
      ]),
    );
  }

  // ═══════════════════ DECISIONS TABLE ═══════════════════

  Widget _buildDecisionsCard(List<AiDecision> decisions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.history_rounded, size: 18, color: AppColors.aiBlue),
          SizedBox(width: 8),
          Text('Recent AI Decisions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 14),
        ...decisions.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: d.statusColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: d.statusColor.withValues(alpha: 0.15)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 700;
                  final statusWidgets = [
                    _statusBadge(d.status, d.statusColor),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                      child: Text('${(d.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                    ),
                    if (d.status == 'pending' || d.status == 'approved')
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => _showOverrideDialog(context, d),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Override', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: d.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Icon(_actionIcon(d.action), size: 16, color: d.statusColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.description, style: const TextStyle(fontSize: 12, color: AppColors.textDark), overflow: TextOverflow.ellipsis, maxLines: 2),
                          const SizedBox(height: 3),
                          Text('${d.userName} • ${_fmtTime(d.timestamp)}', style: const TextStyle(fontSize: 10, color: AppColors.textLight), overflow: TextOverflow.ellipsis),
                        ])),
                        if (!narrow) ...[
                          const SizedBox(width: 8),
                          ...statusWidgets
                              .expand((w) => [w, const SizedBox(width: 8)])
                              .toList()
                            ..removeLast(),
                        ],
                      ]),
                      if (narrow) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: statusWidgets,
                        ),
                      ],
                    ],
                  );
                },
              ),
            )),
      ]),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(text[0].toUpperCase() + text.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'reorder': return Icons.refresh_rounded;
      case 'relocate': return Icons.swap_horiz_rounded;
      case 'alert': return Icons.warning_rounded;
      case 'optimize': return Icons.auto_fix_high_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _fmtTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showOverrideDialog(BuildContext context, AiDecision decision) {
    final justificationCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.compare_arrows_rounded, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Override AI Decision'),
        ]),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(decision.description, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('Confidence: ${(decision.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: justificationCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Justification (required — FR-8)',
                  hintText: 'Explain why...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (justificationCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Justification is required'), backgroundColor: AppColors.error),
                );
                return;
              }
              setState(() {
                decision.status = 'overridden';
                decision.userName = ApiService.currentFullName.isNotEmpty ? ApiService.currentFullName : 'Admin';
              });
              // Call API to override decision
              try {
                ApiService.post('/ai-decisions/${decision.id}/override', {
                  'justification': justificationCtrl.text.trim(),
                });
              } catch (_) {}
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Decision overridden successfully'), backgroundColor: AppColors.success),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Override'),
          ),
        ],
      ),
    );
  }
}

class _MData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MData(this.icon, this.label, this.value, this.color);
}
