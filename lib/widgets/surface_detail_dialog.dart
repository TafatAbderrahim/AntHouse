import 'dart:math';
import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/warehouse_data.dart';

// ═══════════════════════════════════════════════════════════════
//  SURFACE DETAIL DIALOG — Rich visualization of a single zone
// ═══════════════════════════════════════════════════════════════

class SurfaceDetailDialog extends StatefulWidget {
  final WarehouseFloor floor;
  final StorageZone zone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SurfaceDetailDialog({
    super.key,
    required this.floor,
    required this.zone,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SurfaceDetailDialog> createState() => _SurfaceDetailDialogState();
}

class _SurfaceDetailDialogState extends State<SurfaceDetailDialog>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  late AnimationController _pulse;
  int _detailTab = 0; // 0=overview, 1=rack-view, 2=heatmap, 3=activity

  // Mock analytics data (seeded by zone id)
  late final Random _rng;
  late final int _picksToday;
  late final int _picksWeek;
  late final double _avgPickTime;
  late final double _congestionScore;
  late final List<double> _hourlyPicks;
  late final List<_ActivityEntry> _recentActivity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _rng = Random(widget.zone.id.hashCode);
    _picksToday = _rng.nextInt(120) + 10;
    _picksWeek = _picksToday * 5 + _rng.nextInt(200);
    _avgPickTime = (_rng.nextDouble() * 5 + 1);
    _congestionScore = _rng.nextDouble();
    _hourlyPicks = List.generate(24, (_) => _rng.nextDouble() * 20 + 2);
    _recentActivity = List.generate(8, (i) {
      final types = ['Pick', 'Restock', 'Audit', 'Move', 'Override'];
      final users = ['Ahmed B.', 'Karim M.', 'Youcef S.', 'Nabil T.'];
      return _ActivityEntry(
        type: types[_rng.nextInt(types.length)],
        user: users[_rng.nextInt(users.length)],
        time: DateTime.now().subtract(Duration(minutes: _rng.nextInt(480) + 5)),
        detail: 'Item ${_rng.nextInt(9000) + 1000}',
      );
    })
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isCompact = screenW < 650;
    final dialogW = isCompact ? screenW * 0.95 : (screenW * 0.75).clamp(600.0, 1100.0);
    final dialogH = isCompact ? screenH * 0.90 : screenH * 0.82;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 40,
        vertical: isCompact ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 14 : 20)),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
          opacity: _anim.value,
          child: Transform.scale(
            scale: 0.9 + _anim.value * 0.1,
            child: Container(
              width: dialogW,
              height: dialogH,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
              ),
              child: Column(
                children: [
                  _buildDialogHeader(zone),
                  _buildTabBar(),
                  const Divider(height: 1),
                  Expanded(child: _buildTabContent(zone)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════

  Widget _buildDialogHeader(StorageZone zone) {
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenW < 650;
    final pad = isCompact ? 12.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _typeColor(zone).withValues(alpha: 0.15),
            _typeColor(zone).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(isCompact ? 14 : 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Zone icon
              Container(
                width: isCompact ? 40 : 56,
                height: isCompact ? 40 : 56,
                decoration: BoxDecoration(
                  color: _typeColor(zone),
                  borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: _typeColor(zone).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(zone.type.icon,
                      style: TextStyle(fontSize: isCompact ? 18 : 26)),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 16),
              // Zone info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(zone.label,
                              style: TextStyle(
                                  fontSize: isCompact ? 18 : 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: zone.status.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(zone.status.label,
                              style: TextStyle(
                                  fontSize: isCompact ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: zone.status.color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${zone.type.label} • ${zone.widthM}m × ${zone.heightM}m • ${zone.areaM2.toStringAsFixed(1)}m²${zone.rackLevels > 1 ? ' • ${zone.rackLevels} niveaux → ${zone.totalRacks} racks' : ''} • Section: ${zone.section.isEmpty ? "—" : zone.section}',
                      style: TextStyle(
                          fontSize: isCompact ? 11 : 14, color: AppColors.textMid),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMid),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (!isCompact) ...[
            const SizedBox(height: 10),
            // Quick stats row - desktop
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _quickStat('Picks Today', '$_picksToday', AppColors.aiBlue),
                _quickStat(
                    'Occupancy',
                    '${(zone.occupancyRate * 100).toInt()}%',
                    zone.status.color),
                _quickStat('Avg Time',
                    '${_avgPickTime.toStringAsFixed(1)}min', AppColors.accent),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Quick stats row - compact
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _quickStat('Picks', '$_picksToday', AppColors.aiBlue),
                _quickStat(
                    'Occ.',
                    '${(zone.occupancyRate * 100).toInt()}%',
                    zone.status.color),
                _quickStat('Avg',
                    '${_avgPickTime.toStringAsFixed(1)}m', AppColors.accent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  // ═══════════════════ TAB BAR ═══════════════════

  Widget _buildTabBar() {
    const tabs = [
      (Icons.dashboard_rounded, 'Overview'),
      (Icons.view_in_ar_rounded, 'Rack View'),
      (Icons.thermostat_rounded, 'Heatmap'),
      (Icons.history_rounded, 'Activity'),
    ];
    final isCompact = MediaQuery.of(context).size.width < 650;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: isCompact ? 4 : 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = _detailTab == i;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _detailTab = i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 14,
                    vertical: isCompact ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tabs[i].$1,
                          size: isCompact ? 14 : 16,
                          color: active
                              ? AppColors.primary
                              : AppColors.textMid),
                      SizedBox(width: isCompact ? 4 : 6),
                      Text(tabs[i].$2,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.primary
                                : AppColors.textMid,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════════ TAB CONTENT ═══════════════════

  Widget _buildTabContent(StorageZone zone) {
    switch (_detailTab) {
      case 0:
        return _buildOverviewTab(zone);
      case 1:
        return _buildRackViewTab(zone);
      case 2:
        return _buildHeatmapTab(zone);
      case 3:
        return _buildActivityTab(zone);
      default:
        return _buildOverviewTab(zone);
    }
  }

  // ───────── OVERVIEW TAB ─────────

  Widget _buildOverviewTab(StorageZone zone) {
    final isCompact = MediaQuery.of(context).size.width < 650;
    final pad = isCompact ? 10.0 : 20.0;

    if (isCompact) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            SizedBox(height: 220, child: _buildZoneVisualization(zone)),
            const SizedBox(height: 10),
            _buildPositionInfo(zone),
            const SizedBox(height: 10),
            _buildOccupancyCard(zone),
            const SizedBox(height: 10),
            _buildPicksChart(),
            const SizedBox(height: 10),
            _buildCongestionCard(),
            const SizedBox(height: 10),
            _buildWeeklyStats(),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Row(
        children: [
          // Left — Zone visualization
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(child: _buildZoneVisualization(zone)),
                const SizedBox(height: 12),
                _buildPositionInfo(zone),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right — Stats
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildOccupancyCard(zone),
                  const SizedBox(height: 12),
                  _buildPicksChart(),
                  const SizedBox(height: 12),
                  _buildCongestionCard(),
                  const SizedBox(height: 12),
                  _buildWeeklyStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneVisualization(StorageZone zone) {
    final showRdcLevels = widget.floor.floorNumber == 0 && zone.rackLevels > 1;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ZoneDetailPainter(
              zone: zone,
              showRdcLevels: showRdcLevels,
              animValue: _pulse.value,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionInfo(StorageZone zone) {
    final isCompact = MediaQuery.of(context).size.width < 650;
    final chips = <Widget>[
      _posChip('X', '${zone.x}m', Icons.swap_horiz),
      _posChip('Y', '${zone.y}m', Icons.swap_vert),
      _posChip('W', '${zone.widthM}m', Icons.width_normal),
      _posChip('H', '${zone.heightM}m', Icons.height),
      _posChip('Area', '${zone.areaM2.toStringAsFixed(1)}m²', Icons.square_foot),
      if (zone.rackLevels > 1) ...[
        _posChip('Levels', '${zone.rackLevels}', Icons.layers),
        _posChip('Racks', '${zone.totalRacks}', Icons.view_in_ar),
      ],
    ];

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: isCompact ? 8 : 10,
        runSpacing: isCompact ? 6 : 0,
        children: chips,
      ),
    );
  }

  Widget _posChip(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMid),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textLight)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildOccupancyCard(StorageZone zone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Text('Occupancy',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(zone.occupancyRate * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: zone.status.color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: zone.occupancyRate,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(zone.status.color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Used: ${(zone.areaM2 * zone.occupancyRate).toStringAsFixed(1)}m²',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMid)),
              Text(
                  'Free: ${(zone.areaM2 * (1 - zone.occupancyRate)).toStringAsFixed(1)}m²',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMid)),
            ],
          ),
          if (zone.rackLevels > 1) ...[  
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.layers, size: 14, color: Color(0xFF1565C0)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${zone.rackLevels} niveaux × ${zone.capacityPerLevel} racks/niv = ${zone.totalRacks} racks total',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPicksChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 18, color: AppColors.aiBlue),
              SizedBox(width: 8),
              Text('Picks / Hour (24h)',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: Size.infinite,
              painter: _MiniBarChartPainter(
                  values: _hourlyPicks, color: AppColors.aiBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongestionCard() {
    final level = _congestionScore < 0.3
        ? 'Low'
        : _congestionScore < 0.7
            ? 'Medium'
            : 'High';
    final color = _congestionScore < 0.3
        ? AppColors.success
        : _congestionScore < 0.7
            ? AppColors.accent
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.traffic_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Congestion',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMid)),
              Text(level,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const Spacer(),
          Text('${(_congestionScore * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Summary',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _weekRow('Total Picks', '$_picksWeek', AppColors.aiBlue),
          _weekRow('Restocks', '${_rng.nextInt(30) + 5}', AppColors.success),
          _weekRow('Overrides', '${_rng.nextInt(8)}', AppColors.accent),
          _weekRow(
              'Avg Occupancy',
              '${(widget.zone.occupancyRate * 100).toInt()}%',
              AppColors.primaryDark),
        ],
      ),
    );
  }

  Widget _weekRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMid)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ───────── RACK VIEW TAB ─────────

  Widget _buildRackViewTab(StorageZone zone) {
    // Rack/slot simulation — shows individual storage slots inside the zone
    final isRack = zone.type == ZoneType.rackStorage ||
        zone.type == ZoneType.floorStorage;
    final isRDC = widget.floor.floorNumber == 0 && zone.rackLevels > 1;
    // RDC racks have 3 levels (N1, N2, N3) → show as 3 columns
    final cols = isRDC ? 3 : max(1, (zone.widthM / 1.0).floor());
    final rows = isRDC ? max(1, (zone.heightM / 1.0).floor()) : max(1, (zone.heightM / 1.0).floor());
    final isCompact = MediaQuery.of(context).size.width < 650;
    final pad = isCompact ? 10.0 : 20.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — wrapped for mobile
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                  isRack
                      ? Icons.view_in_ar_rounded
                      : Icons.grid_on_rounded,
                  size: isCompact ? 18 : 24,
                  color: AppColors.primary),
              Text(
                isRDC
                    ? 'Rack Layout — N1, N2, N3 × $rows rows${' = ${zone.totalRacks} racks'}'
                    : isRack
                        ? 'Rack Layout — ${cols}×$rows slots (1m² each)${zone.rackLevels > 1 ? ' × ${zone.rackLevels} levels = ${zone.totalRacks} racks' : ''}'
                        : 'Surface Grid — ${cols}×$rows cells',
                style: TextStyle(
                    fontSize: isCompact ? 13 : 16, fontWeight: FontWeight.bold),
              ),
              _legendDot(AppColors.success, 'Empty'),
              _legendDot(AppColors.accent, 'Partial'),
              _legendDot(AppColors.error, 'Full'),
              _legendDot(Colors.grey.shade400, 'Blocked'),
            ],
          ),
          const SizedBox(height: 16),
          // RDC: Show level column headers
          if (isRDC)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 20), // offset for row labels
                  ...List.generate(3, (i) {
                    return Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'N${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: _RackSlotPainter(
                  zone: zone,
                  cols: cols,
                  rows: rows,
                  rng: _rng,
                  animValue: _pulse.value,
                  isRDC: isRDC,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: AppColors.aiBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.aiBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.aiBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Suggestion: Move high-turnover items to slots near aisle entrance for faster picks.',
                    style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppColors.aiBlue.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
      ],
    );
  }

  // ───────── HEATMAP TAB ─────────

  Widget _buildHeatmapTab(StorageZone zone) {
    final isCompact = MediaQuery.of(context).size.width < 650;
    final pad = isCompact ? 10.0 : 20.0;

    if (isCompact) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: _ZoneHeatmapPainter(
                        zone: zone,
                        rng: _rng,
                        animValue: _pulse.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildHeatmapSidebar(zone),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _ZoneHeatmapPainter(
                      zone: zone,
                      rng: _rng,
                      animValue: _pulse.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: _buildHeatmapSidebar(zone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSidebar(StorageZone zone) {
    return Column(
      children: [
        // Heatmap legend
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pick Frequency Heatmap',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFFFFC107),
                      Color(0xFFFF5722),
                      Color(0xFFD32F2F),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight)),
                  Text('Medium',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight)),
                  Text('High',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Time window selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Time Window',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: ['1h', '24h', '7d', '30d']
                    .map((t) => Chip(
                          label: Text(t,
                              style:
                                  const TextStyle(fontSize: 12)),
                          backgroundColor:
                              t == '24h'
                                  ? AppColors.primary
                                      .withValues(alpha: 0.15)
                                  : AppColors.bg,
                          side: BorderSide(
                              color: t == '24h'
                                  ? AppColors.primary
                                  : AppColors.divider),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Hotspot info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hotspots',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(
                5,
                (i) => _hotspotRow(
                  'Slot ${String.fromCharCode(65 + i)}${i + 1}',
                  _rng.nextInt(40) + 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hotspotRow(String slot, int picks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: picks > 30
                  ? AppColors.error
                  : picks > 20
                      ? AppColors.accent
                      : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(slot,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$picks picks',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMid)),
        ],
      ),
    );
  }

  // ───────── ACTIVITY TAB ─────────

  Widget _buildActivityTab(StorageZone zone) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text('Recent Activity',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_recentActivity.length} events',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _recentActivity.length,
              itemBuilder: (_, i) {
                final a = _recentActivity[i];
                return _activityRow(a);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(_ActivityEntry a) {
    final icon = a.type == 'Pick'
        ? Icons.inventory_2
        : a.type == 'Restock'
            ? Icons.add_box
            : a.type == 'Override'
                ? Icons.gavel
                : a.type == 'Audit'
                    ? Icons.fact_check
                    : Icons.swap_horiz;
    final color = a.type == 'Pick'
        ? AppColors.aiBlue
        : a.type == 'Restock'
            ? AppColors.success
            : a.type == 'Override'
                ? AppColors.accent
                : AppColors.textMid;

    final ago = DateTime.now().difference(a.time);
    final timeStr = ago.inMinutes < 60
        ? '${ago.inMinutes}min ago'
        : '${ago.inHours}h ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.type,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${a.user} • ${a.detail}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMid)),
              ],
            ),
          ),
          Text(timeStr,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Color _typeColor(StorageZone zone) {
    switch (zone.type) {
      case ZoneType.rack:
      case ZoneType.rackStorage:
        return const Color(0xFF4CAF50);
      case ZoneType.floorStorage:
        return const Color(0xFF2196F3);
      case ZoneType.preparation:
        return const Color(0xFF9C27B0);
      case ZoneType.shipping:
      case ZoneType.receiving:
        return const Color(0xFFE91E63);
      case ZoneType.office:
        return const Color(0xFF795548);
      case ZoneType.elevator:
      case ZoneType.freightLift:
      case ZoneType.freightElevator:
        return const Color(0xFF607D8B);
      case ZoneType.bulk:
        return const Color(0xFF673AB7);
      case ZoneType.pillar:
        return const Color(0xFF9E9E9E);
      case ZoneType.aisle:
        return const Color(0xFFBDBDBD);
      case ZoneType.special:
        return const Color(0xFFFF5722);
    }
  }
}

class _ActivityEntry {
  final String type;
  final String user;
  final DateTime time;
  final String detail;
  _ActivityEntry(
      {required this.type,
      required this.user,
      required this.time,
      required this.detail});
}

// ═══════════════════════════════════════════════════════════════
//  ZONE DETAIL PAINTER — Visualization of a single zone
// ═══════════════════════════════════════════════════════════════

class _ZoneDetailPainter extends CustomPainter {
  final StorageZone zone;
  final bool showRdcLevels;
  final double animValue;

  _ZoneDetailPainter({
    required this.zone,
    this.showRdcLevels = false,
    this.animValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 30.0;
    final drawW = size.width - margin * 2;
    final drawH = size.height - margin * 2;
    final sx = drawW / zone.widthM;
    final sy = drawH / zone.heightM;
    final s = sx < sy ? sx : sy;

    final ox = (size.width - zone.widthM * s) / 2;
    final oy = (size.height - zone.heightM * s) / 2;

    // Background grid
    final gridP = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= zone.widthM; x += 1) {
      canvas.drawLine(
          Offset(ox + x * s, oy), Offset(ox + x * s, oy + zone.heightM * s), gridP);
    }
    for (double y = 0; y <= zone.heightM; y += 1) {
      canvas.drawLine(
          Offset(ox, oy + y * s), Offset(ox + zone.widthM * s, oy + y * s), gridP);
    }

    // Main zone rectangle
    final rect =
        Rect.fromLTWH(ox, oy, zone.widthM * s, zone.heightM * s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = _zoneColor().withValues(alpha: 0.3),
    );

    // Occupancy fill
    if (zone.occupancyRate > 0) {
      final occH = zone.heightM * s * zone.occupancyRate;
      final occRect = Rect.fromLTWH(ox, oy + zone.heightM * s - occH, zone.widthM * s, occH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(occRect.intersect(rect), const Radius.circular(6)),
        Paint()..color = zone.status.color.withValues(alpha: 0.25),
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = _zoneColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // RDC multi-level rack view: split into levels and show level labels
    if (showRdcLevels) {
      final levelCount = zone.rackLevels;
      final levelHeight = rect.height / levelCount;
      final racksPerLevel = zone.capacityPerLevel;

      final divider = Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (int i = 1; i < levelCount; i++) {
        final ly = rect.top + levelHeight * i;
        canvas.drawLine(Offset(rect.left, ly), Offset(rect.right, ly), divider);
      }

      for (int i = 0; i < levelCount; i++) {
        final top = rect.top + levelHeight * i;
        final centerY = top + levelHeight / 2;
        final levelIdx = levelCount - i;
        final label = 'N$levelIdx · $racksPerLevel racks';
        _paintText(
          canvas,
          label,
          Offset(rect.left + 8, centerY - 6),
          10,
          const Color(0xFF0D47A1),
          bold: true,
        );
      }
    }

    // Pulse border
    final pulse = 3 + 5 * sin(animValue * 2 * pi).abs();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(pulse), const Radius.circular(10)),
      Paint()
        ..color = _zoneColor().withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dimension labels
    _paintText(canvas, '${zone.widthM}m',
        Offset(ox + zone.widthM * s / 2 - 12, oy + zone.heightM * s + 8),
        12, const Color(0xFF455A64), bold: true);
    // Vertical dimension — rotated would be better but let's place it beside
    _paintText(canvas, '${zone.heightM}m',
        Offset(ox - 28, oy + zone.heightM * s / 2 - 6),
        12, const Color(0xFF455A64), bold: true);

    // Center label
    _paintText(canvas, zone.label,
        Offset(ox + zone.widthM * s / 2 - zone.label.length * 5,
            oy + zone.heightM * s / 2 - 12),
        18, Colors.black87, bold: true);
    _paintText(canvas, '${zone.type.icon} ${zone.type.label}',
        Offset(ox + zone.widthM * s / 2 - 30,
            oy + zone.heightM * s / 2 + 10),
        12, Colors.black54);

    // Area label
    _paintText(canvas, '${zone.areaM2.toStringAsFixed(1)}m²',
        Offset(ox + zone.widthM * s / 2 - 18,
            oy + zone.heightM * s / 2 + 28),
        11, const Color(0xFF1565C0), bold: true);

    // Rack levels info
    if (showRdcLevels) {
      final rackText = '×${zone.rackLevels} niv · ${zone.totalRacks} racks';
      _paintText(canvas, rackText,
          Offset(ox + zone.widthM * s / 2 - rackText.length * 3,
              oy + zone.heightM * s / 2 + 44),
          10, const Color(0xFFE65100), bold: true);
    }
  }

  Color _zoneColor() {
    switch (zone.type) {
      case ZoneType.rackStorage:
        return const Color(0xFF4CAF50);
      case ZoneType.floorStorage:
        return const Color(0xFF2196F3);
      case ZoneType.preparation:
        return const Color(0xFF9C27B0);
      case ZoneType.shipping:
        return const Color(0xFFE91E63);
      case ZoneType.bulk:
        return const Color(0xFF673AB7);
      default:
        return const Color(0xFF607D8B);
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, double size,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color, fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ZoneDetailPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  RACK SLOT PAINTER — Individual slots inside a zone
// ═══════════════════════════════════════════════════════════════

class _RackSlotPainter extends CustomPainter {
  final StorageZone zone;
  final int cols;
  final int rows;
  final Random rng;
  final double animValue;
  final bool isRDC;

  _RackSlotPainter({
    required this.zone,
    required this.cols,
    required this.rows,
    required this.rng,
    this.animValue = 0,
    this.isRDC = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 20.0;
    final drawW = size.width - margin * 2;
    final drawH = size.height - margin * 2;

    // For RDC 3-column layout, use rectangular cells (not square)
    final cellW = drawW / cols;
    final cellH = drawH / rows;
    final double usedCellW;
    final double usedCellH;
    if (isRDC) {
      // Use rectangular cells for the 3-column RDC layout
      usedCellW = cellW;
      usedCellH = cellH;
    } else {
      final cellS = cellW < cellH ? cellW : cellH;
      usedCellW = cellS;
      usedCellH = cellS;
    }

    final ox = (size.width - cols * usedCellW) / 2;
    final oy = (size.height - rows * usedCellH) / 2;

    final slotRng = Random(zone.id.hashCode);

    // For RDC: draw column separators and headers
    if (isRDC) {
      final colDivider = Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.25)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      for (int c = 1; c < cols; c++) {
        final dx = ox + c * usedCellW;
        canvas.drawLine(
          Offset(dx, oy - 4),
          Offset(dx, oy + rows * usedCellH + 4),
          colDivider,
        );
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = ox + c * usedCellW;
        final y = oy + r * usedCellH;
        final rect = Rect.fromLTWH(x + 1, y + 1, usedCellW - 2, usedCellH - 2);

        // Random slot status
        final val = slotRng.nextDouble();
        Color fillColor;
        if (val < 0.15) {
          fillColor = Colors.grey.shade300; // blocked
        } else if (val < 0.4) {
          fillColor = const Color(0xFF4CAF50); // empty
        } else if (val < 0.7) {
          fillColor = const Color(0xFFFFA726); // partial
        } else {
          fillColor = const Color(0xFFEF5350); // full
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = fillColor.withValues(alpha: 0.35),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Slot label
        final minDim = usedCellW < usedCellH ? usedCellW : usedCellH;
        if (minDim > 20) {
          final label = isRDC
              ? 'N${c + 1}-${String.fromCharCode(65 + (r % 26))}'
              : '${String.fromCharCode(65 + (r % 26))}${c + 1}';
          _paintText(
            canvas,
            label,
            Offset(x + usedCellW / 2 - label.length * 3, y + usedCellH / 2 - 5),
            (minDim * 0.22).clamp(6.0, 11.0),
            Colors.black54,
          );
        }
      }
    }

    // Row labels
    for (int r = 0; r < rows; r++) {
      _paintText(canvas, '${String.fromCharCode(65 + (r % 26))}',
          Offset(ox - 16, oy + r * usedCellH + usedCellH / 2 - 5), 10,
          const Color(0xFF455A64), bold: true);
    }
    // Col labels (for non-RDC; RDC has widget-level N1/N2/N3 headers)
    if (!isRDC) {
      for (int c = 0; c < cols; c++) {
        _paintText(canvas, '${c + 1}',
            Offset(ox + c * usedCellW + usedCellW / 2 - 4, oy - 16), 10,
            const Color(0xFF455A64), bold: true);
      }
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, double size,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color, fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RackSlotPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  ZONE HEATMAP PAINTER — Pick frequency heatmap inside a zone
// ═══════════════════════════════════════════════════════════════

class _ZoneHeatmapPainter extends CustomPainter {
  final StorageZone zone;
  final Random rng;
  final double animValue;

  _ZoneHeatmapPainter({
    required this.zone,
    required this.rng,
    this.animValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 20.0;
    final drawW = size.width - margin * 2;
    final drawH = size.height - margin * 2;
    final cols = max(1, (zone.widthM / 1).floor());
    final rows = max(1, (zone.heightM / 1).floor());
    final cellW = drawW / cols;
    final cellH = drawH / rows;
    final cellS = cellW < cellH ? cellW : cellH;

    final ox = (size.width - cols * cellS) / 2;
    final oy = (size.height - rows * cellS) / 2;

    final heatRng = Random(zone.id.hashCode + 42);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = ox + c * cellS;
        final y = oy + r * cellS;
        final rect = Rect.fromLTWH(x, y, cellS, cellS);

        final heat = heatRng.nextDouble();
        final color = Color.lerp(
          const Color(0xFF4CAF50),
          const Color(0xFFD32F2F),
          heat,
        )!;

        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.5));
        canvas.drawRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );

        // Value label
        if (cellS > 25) {
          final val = (heat * 50).toInt();
          _paintText(canvas, '$val',
              Offset(x + cellS / 2 - 6, y + cellS / 2 - 5),
              (cellS * 0.2).clamp(6.0, 11.0), Colors.white, bold: true);
        }
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, cols * cellS, rows * cellS),
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintText(Canvas canvas, String text, Offset offset, double size,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color, fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ZoneHeatmapPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  MINI BAR CHART PAINTER
// ═══════════════════════════════════════════════════════════════

class _MiniBarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _MiniBarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(max);
    if (maxVal == 0) return;

    final barW = size.width / values.length;
    for (int i = 0; i < values.length; i++) {
      final h = (values[i] / maxVal) * size.height * 0.9;
      final rect = Rect.fromLTWH(
          i * barW + 1, size.height - h, barW - 2, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter old) => false;
}
