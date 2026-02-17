import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

/// FR-7, FR-46: Admin may override any AI or Supervisor decision.
/// FR-8: Overrides require justification.
/// FR-47: Log overrides separately.
class OverridesScreen extends StatefulWidget {
  const OverridesScreen({super.key});
  @override
  State<OverridesScreen> createState() => _OverridesScreenState();
}

class _OverridesScreenState extends State<OverridesScreen> {
  late List<OverrideRecord> _overrides;
  late List<AiDecision> _pendingDecisions;
  String _typeFilter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _overrides = [];
    _pendingDecisions = [];
    _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    try {
      final aiList = await ApiService.getPendingAiDecisions();
      if (!mounted) return;
      if (aiList.isNotEmpty) {
        setState(() {
          _pendingDecisions = aiList.map<AiDecision>((d) => AiDecision(
            id: d['id']?.toString(),
            action: d['decisionType'] ?? d['action'] ?? 'optimize',
            description: d['description'] ?? '',
            status: (d['status'] ?? 'pending').toString().toLowerCase(),
            confidence: (d['confidence'] ?? 0.85).toDouble(),
            userName: d['userName'] ?? 'AI Engine',
          )).toList();
        });
      }
    } catch (_) {}
  }

  List<OverrideRecord> get _filteredOverrides {
    return _overrides.where((o) {
      if (_typeFilter != 'all' && o.originalType.toLowerCase() != _typeFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return o.description.toLowerCase().contains(q) ||
            o.overriddenBy.toLowerCase().contains(q) ||
            o.justification.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<AiDecision> get _overridablePending =>
      _pendingDecisions.where((d) => d.status == 'pending' || d.status == 'approved').toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverrideHistoryTab(),
                  _buildPendingDecisionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Stats row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _statChip('${_overrides.length}', 'Total Overrides', AppColors.accent),
              _statChip(
                '${_overrides.where((o) => o.overriddenByRole == "admin").length}',
                'Admin Overrides',
                AppColors.primaryDark,
              ),
              _statChip(
                '${_overrides.where((o) => o.overriddenByRole == "supervisor").length}',
                'Supervisor Overrides',
                AppColors.aiBlue,
              ),
              _statChip('${_overridablePending.length}', 'Pending Decisions', AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          // Tabs + search
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              final tabs = const TabBar(
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textMid,
                indicatorColor: AppColors.primary,
                labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Override History'),
                  Tab(text: 'Active Decisions'),
                ],
              );
              final searchField = SizedBox(
                height: 38,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textLight),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              );
              final filterDropdown = Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeFilter,
                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'ai', child: Text('AI Overrides')),
                      DropdownMenuItem(value: 'supervisor', child: Text('Supervisor Overrides')),
                    ],
                    onChanged: (v) => setState(() => _typeFilter = v!),
                  ),
                ),
              );

              if (!narrow) {
                return Row(
                  children: [
                    const Expanded(child: TabBar(
                      labelColor: AppColors.primaryDark,
                      unselectedLabelColor: AppColors.textMid,
                      indicatorColor: AppColors.primary,
                      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: 'Override History'),
                        Tab(text: 'Active Decisions'),
                      ],
                    )),
                    const SizedBox(width: 16),
                    Flexible(flex: 2, child: searchField),
                    const SizedBox(width: 10),
                    filterDropdown,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabs,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 10),
                      filterDropdown,
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  // ═══════════════════ TAB 1: Override History ═══════════════════

  Widget _buildOverrideHistoryTab() {
    final list = _filteredOverrides;
    if (list.isEmpty) {
      return const Center(child: Text('No override records found', style: TextStyle(color: AppColors.textLight)));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) => _buildOverrideCard(list[i]),
      ),
    );
  }

  Widget _buildOverrideCard(OverrideRecord o) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.compare_arrows_rounded, size: 20, color: AppColors.accent),
      ),
      title: Text(o.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _originBadge(o.originalType),
            _roleBadge(o.overriddenByRole),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_outline, size: 12, color: AppColors.textLight),
              const SizedBox(width: 3),
              Text(o.overriddenBy, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time, size: 12, color: AppColors.textLight),
              const SizedBox(width: 3),
              Text(_fmtTime(o.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
            ]),
          ],
        ),
      ),
      children: [
        // Justification
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.description_outlined, size: 14, color: AppColors.accent),
                  SizedBox(width: 6),
                  Text('Justification (FR-8)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 6),
              Text(o.justification, style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4)),
            ],
          ),
        ),
        if (o.originalValues != null || o.newValues != null) ...[
          const SizedBox(height: 10),
          _buildDiffView(o),
        ],
      ],
    );
  }

  Widget _buildDiffView(OverrideRecord o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (o.originalValues != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ORIGINAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ),
                  const SizedBox(height: 8),
                  ...o.originalValues!.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Text('${e.key}: ', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                          Flexible(child: Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error, fontFamily: 'monospace'))),
                        ]),
                      )),
                ],
              ),
            ),
          if (o.originalValues != null && o.newValues != null)
            Container(width: 1, height: 60, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.divider),
          if (o.newValues != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('OVERRIDE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ),
                  const SizedBox(height: 8),
                  ...o.newValues!.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Text('${e.key}: ', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                          Flexible(child: Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'monospace'))),
                        ]),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════ TAB 2: Pending Decisions ═══════════════════

  Widget _buildPendingDecisionsTab() {
    final list = _overridablePending;
    if (list.isEmpty) {
      return const Center(child: Text('No active decisions to override', style: TextStyle(color: AppColors.textLight)));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) => _buildDecisionCard(list[i]),
      ),
    );
  }

  Widget _buildDecisionCard(AiDecision d) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: d.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon(d.action), size: 18, color: d.statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(children: [
                  _statusPill(d.status, d.statusColor),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                    child: Text('${(d.confidence * 100).toStringAsFixed(0)}% conf.', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                  ),
                  const SizedBox(width: 8),
                  Text('${d.userName} • ${_fmtTime(d.timestamp)}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Override button
          OutlinedButton.icon(
            onPressed: () => _showOverrideDialog(d),
            icon: const Icon(Icons.compare_arrows_rounded, size: 16),
            label: const Text('Override'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverrideDialog(AiDecision decision) {
    final justificationCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.compare_arrows_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Override Decision'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decision info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.psychology_rounded, size: 14, color: AppColors.aiBlue),
                      const SizedBox(width: 6),
                      const Text('Original AI Decision', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.aiBlue)),
                    ]),
                    const SizedBox(height: 6),
                    Text(decision.description, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('Confidence: ${(decision.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Justification (required per FR-8)
              TextField(
                controller: justificationCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Justification (required)',
                  hintText: 'Explain why this decision needs to be overridden...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                  SizedBox(width: 6),
                  Expanded(child: Text('FR-8: All overrides require mandatory justification and will be permanently logged.',
                      style: TextStyle(fontSize: 10, color: AppColors.accent))),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (justificationCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Justification is required (FR-8)'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await ApiService.overrideAiDecision(
                  decision.id ?? '',
                  justificationCtrl.text.trim(),
                  'Admin override applied',
                );
                final adminName = ApiService.currentFullName.isNotEmpty ? ApiService.currentFullName : 'Admin Principal';
                final override = OverrideRecord(
                  originalDecisionId: decision.id,
                  originalType: 'AI',
                  originalAction: decision.action,
                  description: 'Admin override: ${decision.description}',
                  justification: justificationCtrl.text.trim(),
                  overriddenBy: adminName,
                  overriddenByRole: 'admin',
                );
                setState(() {
                  decision.status = 'overridden';
                  decision.userName = adminName;
                  _overrides.insert(0, override);
                });
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Decision overridden and logged'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Confirm Override'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HELPERS ═══════════════════

  Widget _originBadge(String type) {
    final color = type == 'AI' ? AppColors.aiBlue : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _roleBadge(String role) {
    final color = role == 'admin' ? AppColors.primaryDark : AppColors.aiBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(role[0].toUpperCase() + role.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
}
