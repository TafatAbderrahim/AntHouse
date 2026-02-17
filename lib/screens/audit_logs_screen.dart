import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

/// Section 7.3 item 5: Reviews audit logs — Stock movements, Overrides, Operational validations.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});
  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late List<AuditLogEntry> _logs;
  late List<StockMovement> _movements;
  late List<OverrideRecord> _overrides;
  late List<Transaction> _transactions;
  String _actionFilter = 'all';
  String _movementFilter = 'all';
  String _search = '';
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _logs = [];
    _movements = [];
    _overrides = [];
    _transactions = [];
    _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    try {
      final result = await ApiService.getAuditLogs();
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final content = result['data']['content'] ?? result['data'];
        final list = (content is List) ? content : [];
        setState(() {
          _logs = list.map<AuditLogEntry>((l) => AuditLogEntry(
            id: l['id']?.toString(),
            action: l['action'] ?? '',
            description: l['description'] ?? l['details'] ?? '',
            userName: l['performedBy'] ?? l['userId']?.toString() ?? '',
            timestamp: l['timestamp'] != null ? DateTime.tryParse(l['timestamp'].toString()) : DateTime.now(),
          )).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AuditLogEntry> get _filteredLogs {
    return _logs.where((l) {
      if (_actionFilter != 'all' && l.action != _actionFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return l.description.toLowerCase().contains(q) || l.userName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<StockMovement> get _filteredMovements {
    return _movements.where((m) {
      if (_movementFilter != 'all' && m.type != _movementFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return m.sku.toLowerCase().contains(q) ||
            m.productName.toLowerCase().contains(q) ||
            m.performedBy.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildToolbar(),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLogList(),
                _buildStockMovementsTab(),
                _buildOverridesTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        // Tab bar
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMid,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          isScrollable: true,
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.receipt_long_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('All Actions'),
              const SizedBox(width: 6),
              _countBadge(_logs.length, AppColors.primary),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.swap_vert_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Stock Movements'),
              const SizedBox(width: 6),
              _countBadge(_movements.length, AppColors.aiBlue),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.compare_arrows_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Overrides'),
              const SizedBox(width: 6),
              _countBadge(_overrides.length, AppColors.accent),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.description_outlined, size: 16),
              const SizedBox(width: 6),
              const Text('Transactions'),
              const SizedBox(width: 6),
              _countBadge(_transactions.length, AppColors.success),
            ])),
          ],
        ),
        const SizedBox(height: 10),
        // Search + filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            SizedBox(
              width: 260, height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textLight),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _actionFilter,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Actions')),
                    DropdownMenuItem(value: 'create', child: Text('Create')),
                    DropdownMenuItem(value: 'update', child: Text('Update')),
                    DropdownMenuItem(value: 'delete', child: Text('Delete')),
                    DropdownMenuItem(value: 'override', child: Text('Override')),
                    DropdownMenuItem(value: 'login', child: Text('Login')),
                  ],
                  onChanged: (v) => setState(() => _actionFilter = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _movementFilter,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Movements')),
                    DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'pick', child: Text('Pick')),
                    DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                  ],
                  onChanged: (v) => setState(() => _movementFilter = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${_filteredLogs.length + _filteredMovements.length + _overrides.length + _transactions.length} entries',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ]),
        ),
      ]),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildLogList() {
    final list = _filteredLogs;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: list.isEmpty
          ? const Center(child: Text('No logs found', style: TextStyle(color: AppColors.textLight)))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _buildLogEntry(list[i]),
            ),
    );
  }

  Widget _buildLogEntry(AuditLogEntry log) {
    final isExpanded = _expandedIds.contains(log.id);
    final hasData = log.beforeData != null || log.afterData != null;

    return InkWell(
      onTap: hasData ? () => setState(() {
        if (isExpanded) {
          _expandedIds.remove(log.id);
        } else {
          _expandedIds.add(log.id);
        }
      }) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        color: isExpanded ? log.actionColor.withValues(alpha: 0.04) : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Action icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: log.actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_actionIcon(log.action), size: 18, color: log.actionColor),
              ),
              const SizedBox(width: 12),
              // Main content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.person_outline, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(log.userName, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(_fmtDate(log.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  if (log.ipAddress != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.language, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(log.ipAddress!, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  ],
                ]),
              ])),
              // Action badge
              _actionBadge(log.action, log.actionColor),
              if (hasData) ...[
                const SizedBox(width: 8),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.textLight),
              ],
            ]),

            // Expanded: Before/After diff
            if (isExpanded && hasData) ...[
              const SizedBox(height: 14),
              _buildDiffView(log),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiffView(AuditLogEntry log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.beforeData != null)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('BEFORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error)),
                ),
                const SizedBox(height: 8),
                ...log.beforeData!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Text('${e.key}: ', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Flexible(child: Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
              ]),
            ),
          if (log.beforeData != null && log.afterData != null)
            Container(
              width: 1, height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.divider,
            ),
          if (log.afterData != null)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('AFTER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
                const SizedBox(height: 8),
                ...log.afterData!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Text('${e.key}: ', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Flexible(child: Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _actionBadge(String action, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(action[0].toUpperCase() + action.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'override': return Icons.compare_arrows_rounded;
      case 'login': return Icons.login_rounded;
      default: return Icons.info_outline;
    }
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════════ TAB 2: STOCK MOVEMENTS (FR-25) ═══════════════════

  Widget _buildStockMovementsTab() {
    final list = _filteredMovements;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: list.isEmpty
          ? const Center(child: Text('No movements found', style: TextStyle(color: AppColors.textLight)))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _buildMovementRow(list[i]),
            ),
    );
  }

  Widget _buildMovementRow(StockMovement m) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: m.typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(m.typeIcon, size: 18, color: m.typeColor),
          ),
          const SizedBox(width: 14),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(4)),
                    child: Text(m.sku, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMid, fontFamily: 'monospace')),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(m.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                ]),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text('${m.fromLocation}', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward, size: 10, color: AppColors.textLight),
                      ),
                      Text(m.toLocation, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_outline, size: 12, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(m.performedBy, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: m.typeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    m.quantity > 0 ? '+${m.quantity}' : '${m.quantity}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: m.typeColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: m.typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(m.type[0].toUpperCase() + m.type.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: m.typeColor)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (m.transactionRef != null)
                      Text(m.transactionRef!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMid, fontFamily: 'monospace')),
                    Text(_fmtDate(m.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ TAB 3: OVERRIDES (FR-47) ═══════════════════

  Widget _buildOverridesTab() {
    if (_overrides.isEmpty) {
      return const Center(child: Text('No overrides recorded', style: TextStyle(color: AppColors.textLight)));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _overrides.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) => _buildOverrideRow(_overrides[i]),
      ),
    );
  }

  Widget _buildOverrideRow(OverrideRecord o) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.accent),
      ),
      title: Text(o.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: o.roleColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(o.overriddenByRole, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: o.roleColor)),
          ),
          const SizedBox(width: 6),
          Text('${o.overriddenBy} • ${_fmtDate(o.timestamp)}', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
        ]),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Justification:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
              const SizedBox(height: 4),
              Text(o.justification, style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════ TAB 4: TRANSACTIONS (Operational Validations) ═══════════════════

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found', style: TextStyle(color: AppColors.textLight)));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) => _buildTransactionRow(_transactions[i]),
      ),
    );
  }

  Widget _buildTransactionRow(Transaction t) {
    final typeIcon = _txTypeIcon(t.typeTransaction);
    final typeColor = _txTypeColor(t.typeTransaction);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(typeIcon, size: 18, color: typeColor),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(4)),
          child: Text(t.referenceTransaction, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMid, fontFamily: 'monospace')),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(t.typeTransaction, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: t.statutColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(t.statut, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.statutColor)),
        ),
      ]),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Text('${t.lines.length} line(s)', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
          const SizedBox(width: 12),
          Text(_fmtDate(t.creeLe), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          if (t.notes.isNotEmpty) ...[
            const SizedBox(width: 12),
            Flexible(child: Text(t.notes, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
          ],
        ]),
      ),
      children: [
        if (t.lines.isNotEmpty)
          ...t.lines.map((line) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('#${line.noLigne}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMid)),
                  Text('Product: ${line.idProduit}', style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('Qty: ${line.quantite}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  if (line.emplacementSource != null) Text('From: ${line.emplacementSource}', style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
                  if (line.emplacementSource != null && line.emplacementDestination != null)
                    const Icon(Icons.arrow_forward, size: 10, color: AppColors.textLight),
                  if (line.emplacementDestination != null) Text('To: ${line.emplacementDestination}', style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
                  if (line.codeMotif != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(line.codeMotif!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ),
                  if (line.lotSerie != null)
                    Text('Lot: ${line.lotSerie}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                ]),
              )),
        if (t.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No line items', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
          ),
      ],
    );
  }

  IconData _txTypeIcon(String type) {
    switch (type) {
      case 'RECEIPT': return Icons.download_rounded;
      case 'MOVE': return Icons.swap_horiz_rounded;
      case 'PICK': return Icons.shopping_basket_rounded;
      case 'ADJUSTMENT': return Icons.tune_rounded;
      default: return Icons.receipt_outlined;
    }
  }

  Color _txTypeColor(String type) {
    switch (type) {
      case 'RECEIPT': return AppColors.success;
      case 'MOVE': return AppColors.aiBlue;
      case 'PICK': return AppColors.primary;
      case 'ADJUSTMENT': return AppColors.accent;
      default: return AppColors.archived;
    }
  }
}
