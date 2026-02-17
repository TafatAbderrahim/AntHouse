import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/operations_data.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  SUPERVISOR AI REVIEW — §7.2 step 3
//  • Review AI-generated Preparation Orders, storage
//    assignments, and picking routes
//  • May approve or override AI decisions
//  • Provides justification (FR-8)
//  • Assigns alternative locations or routes (FR-44, FR-45)
// ═══════════════════════════════════════════════════════════════

class SupAiReviewScreen extends StatefulWidget {
  const SupAiReviewScreen({super.key});

  @override
  State<SupAiReviewScreen> createState() => _SupAiReviewScreenState();
}

class _SupAiReviewScreenState extends State<SupAiReviewScreen>
    with SingleTickerProviderStateMixin {
  late final List<AiOperationalDecision> _decisions;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _decisions = [];
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    try {
      final list = await ApiService.getAiDecisions();
      if (!mounted || list.isEmpty) return;
      setState(() {
        _decisions = list.map<AiOperationalDecision>((d) => AiOperationalDecision(
          id: d['id']?.toString() ?? '',
          orderType: OrderType.preparation,
          orderRef: d['reference'] ?? d['orderRef'] ?? '',
          description: d['description'] ?? d['recommendation'] ?? '',
          suggestedAction: d['suggestedAction'] ?? d['decision'] ?? '',
          fromLocation: d['fromLocation'] ?? '',
          toLocation: d['toLocation'] ?? '',
          confidence: (d['confidence'] ?? 0.85).toDouble(),
          reasoning: d['reasoning'] ?? d['explanation'] ?? '',
          status: (d['status'] ?? 'pending').toString().toLowerCase(),
          overrideJustification: d['overrideReason'],
          overriddenBy: d['overriddenBy'],
        )).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AiOperationalDecision> _filtered(String status) {
    if (status == 'all') return _decisions;
    return _decisions.where((d) => d.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _decisions.where((d) => d.status == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            const Icon(Icons.psychology_alt_rounded, size: 24, color: AppColors.aiBlue),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Decision Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('Validate or override AI outputs (FR-5, FR-7, FR-8)', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                ],
              ),
            ),
            if (pending > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$pending pending', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Tabs ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TabBar(
            controller: _tabCtrl,
            tabs: [
              Tab(text: 'Pending ($pending)'),
              const Tab(text: 'Approved'),
              const Tab(text: 'Overridden'),
            ],
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textMid,
            indicatorColor: AppColors.primaryDark,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // ── Tab Content ──
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildList(_filtered('pending')),
              _buildList(_filtered('approved')),
              _buildList(_filtered('overridden')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<AiOperationalDecision> decisions) {
    if (decisions.isEmpty) {
      return const Center(child: Text('No decisions in this category.', style: TextStyle(color: AppColors.textMid)));
    }
    return ListView.builder(
      itemCount: decisions.length,
      itemBuilder: (_, i) => _buildDecisionCard(decisions[i]),
    );
  }

  Widget _buildDecisionCard(AiOperationalDecision d) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: d.status == 'pending'
              ? AppColors.aiBlue.withValues(alpha: 0.3)
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: d.orderType.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(d.orderType.icon, size: 18, color: d.orderType.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.orderRef, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(d.orderType.label, style: TextStyle(fontSize: 11, color: d.orderType.color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),

            // ── Description ──
            Text(d.description, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 8),

            // ── Suggested Action ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.aiBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.aiBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Suggestion', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.aiBlue)),
                        const SizedBox(height: 2),
                        Text(d.suggestedAction, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Route ──
            Row(
              children: [
                _infoChip(Icons.location_on_rounded, d.fromLocation, AppColors.error),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight),
                ),
                _infoChip(Icons.location_on_rounded, d.toLocation, AppColors.success),
                const Spacer(),
                _infoChip(Icons.speed_rounded, '${(d.confidence * 100).toInt()}%', AppColors.aiBlue),
              ],
            ),

            // ── Reasoning ──
            if (d.reasoning.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                title: const Text('AI Reasoning', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(d.reasoning, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                  ),
                ],
              ),
            ],

            // ── Override info ──
            if (d.overrideJustification != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text('Overridden by ${d.overriddenBy ?? 'Unknown'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(d.overrideJustification!, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                  ],
                ),
              ),
            ],

            // ── Action buttons (for pending only) ──
            if (d.status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(d),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _override(d),
                      icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.accent),
                      label: const Text('Override', style: TextStyle(color: AppColors.accent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
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

  void _approve(AiOperationalDecision d) async {
    try {
      await ApiService.approveAiDecision(d.id);
      setState(() => d.status = 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${d.orderRef} approved.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _override(AiOperationalDecision d) {
    showDialog(
      context: context,
      builder: (_) {
        final justCtrl = TextEditingController();
        final altLocCtrl = TextEditingController(text: d.toLocation);
        return AlertDialog(
          title: const Text('Override AI Decision'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Overrides require mandatory justification (FR-8).\nAll overrides are logged separately (FR-47).',
                style: TextStyle(fontSize: 12, color: AppColors.textMid),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: altLocCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alternative Location / Route',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: justCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Justification (required)',
                  hintText: 'Explain why the AI output is overridden...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final text = justCtrl.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Justification is required.'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                final newDecision = altLocCtrl.text.trim() != d.toLocation
                    ? 'Relocate to ${altLocCtrl.text.trim()}'
                    : 'Override applied';
                try {
                  await ApiService.overrideAiDecision(d.id, text, newDecision);
                  setState(() {
                    d.status = 'overridden';
                    d.overrideJustification = text;
                    d.overriddenBy = ApiService.currentFullName.isNotEmpty ? ApiService.currentFullName : 'Supervisor';
                    d.overriddenAt = DateTime.now();
                    if (altLocCtrl.text.trim() != d.toLocation) {
                      d.overrideJustification = '$text\nNew location: ${altLocCtrl.text.trim()}';
                    }
                  });
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${d.orderRef} overridden — logged.'), backgroundColor: AppColors.accent),
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
        );
      },
    );
  }
}
