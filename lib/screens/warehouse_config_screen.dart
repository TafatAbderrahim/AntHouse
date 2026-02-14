import 'dart:math';
import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/warehouse_data.dart';
import '../widgets/surface_detail_dialog.dart';
import '../widgets/heatmap_painter.dart';

// ═══════════════════════════════════════════════════════════════
//  WAREHOUSE CONFIG SCREEN — Admin Floor & Surface Management
// ═══════════════════════════════════════════════════════════════

class WarehouseConfigScreen extends StatefulWidget {
  const WarehouseConfigScreen({super.key});
  @override
  State<WarehouseConfigScreen> createState() => _WarehouseConfigScreenState();
}

class _WarehouseConfigScreenState extends State<WarehouseConfigScreen>
    with TickerProviderStateMixin {
  late List<WarehouseFloor> _floors;
  int? _expandedFloorIdx;
  String? _selectedZoneId;
  int _viewMode = 0; // 0=grid, 1=list, 2=heatmap
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _floors = WarehouseDataGenerator.generateAllFloors();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _expandedFloorIdx != null
                ? _buildFloorDetail(_floors[_expandedFloorIdx!])
                : _buildFloorGrid(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════

  Widget _buildHeader() {
    final totalArea = _floors.fold<double>(0, (s, f) => s + f.totalAreaM2);
    final totalZones = _floors.fold<int>(0, (s, f) => s + f.totalZones);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left — Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Warehouse Configuration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_expandedFloorIdx != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _floors[_expandedFloorIdx!].name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage floors, dimensions, surfaces & layout',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Right — Stats + Actions
          Flexible(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _headerStat(Icons.layers_rounded, '${_floors.length}', 'Floors'),
                _headerStat(Icons.grid_view_rounded, '$totalZones', 'Zones'),
                _headerStat(Icons.square_foot_rounded, '${totalArea.toInt()}m²', 'Total'),
                if (_expandedFloorIdx != null)
                  _actionBtn(Icons.arrow_back_rounded, 'Back', () {
                    setState(() {
                      _expandedFloorIdx = null;
                      _selectedZoneId = null;
                    });
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ FLOOR GRID (overview) ═══════════════════

  Widget _buildFloorGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _floors.length,
      itemBuilder: (_, i) => _buildFloorCard(i),
    );
  }

  Widget _buildFloorCard(int idx) {
    final floor = _floors[idx];
    final occupancy = floor.totalZones > 0
        ? floor.occupiedZones / floor.totalZones
        : 0.0;
    final usedPct = floor.totalAreaM2 > 0
        ? (floor.usedAreaM2 / floor.totalAreaM2 * 100).toInt()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Floor header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      floor.shortName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(floor.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${floor.totalWidthM.toInt()}m × ${floor.totalHeightM.toInt()}m • ${floor.totalAreaM2.toInt()}m²',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 20, color: AppColors.textMid),
                  tooltip: 'Open Floor',
                  onPressed: () => setState(() => _expandedFloorIdx = idx),
                ),
              ],
            ),
          ),

          // Mini map preview
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expandedFloorIdx = idx),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MiniFloorPainter(floor: floor),
                ),
              ),
            ),
          ),

          // Stats footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _floorStat('Zones', '${floor.totalZones}', Icons.grid_view,
                    AppColors.primary),
                _floorStat('Free', '${floor.freeZones}', Icons.check_circle,
                    AppColors.success),
                _floorStat('Critical', '${floor.criticalZones}',
                    Icons.warning_rounded, AppColors.error),
                _floorStat(
                    'Used', '$usedPct%', Icons.pie_chart, AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  // ═══════════════════ FLOOR DETAIL VIEW ═══════════════════

  Widget _buildFloorDetail(WarehouseFloor floor) {
    return Row(
      children: [
        // Left — Interactive map with heatmap
        Expanded(
          flex: 5,
          child: _buildFloorMap(floor),
        ),
        const SizedBox(width: 16),
        // Right — Surface list + config
        Expanded(
          flex: 3,
          child: _buildConfigPanel(floor),
        ),
      ],
    );
  }

  Widget _buildFloorMap(WarehouseFloor floor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // View mode toolbar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 640;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${floor.name} — ${floor.totalWidthM.toInt()}m × ${floor.totalHeightM.toInt()}m',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _viewToggle(0, Icons.grid_view_rounded, 'Layout'),
                          const SizedBox(width: 4),
                          _viewToggle(2, Icons.thermostat_rounded, 'Heatmap'),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${floor.name} — ${floor.totalWidthM.toInt()}m × ${floor.totalHeightM.toInt()}m',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    _viewToggle(0, Icons.grid_view_rounded, 'Layout'),
                    const SizedBox(width: 4),
                    _viewToggle(2, Icons.thermostat_rounded, 'Heatmap'),
                  ],
                );
              },
            ),
          ),
          // Map canvas
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                minScale: 0.3,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(60),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return GestureDetector(
                      onTapDown: (d) => _onMapTap(
                          d.localPosition, constraints, floor),
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          return CustomPaint(
                            size: Size(constraints.maxWidth,
                                constraints.maxHeight),
                            painter: _viewMode == 2
                                ? HeatmapFloorPainter(
                                    floor: floor,
                                    selectedZoneId: _selectedZoneId,
                                    animValue: _pulseAnim.value,
                                  )
                                : _ConfigFloorPainter(
                                    floor: floor,
                                    selectedZoneId: _selectedZoneId,
                                    animValue: _pulseAnim.value,
                                    showLabels: true,
                                  ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggle(int mode, IconData icon, String label) {
    final active = _viewMode == mode;
    return Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textMid),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMid,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ CONFIG PANEL (right) ═══════════════════

  Widget _buildConfigPanel(WarehouseFloor floor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Floor config header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 20, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    const Text('Floor Configuration',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                // Dimension display
                Row(
                  children: [
                    _dimChip(Icons.width_normal_rounded,
                        '${floor.totalWidthM}m', 'Width'),
                    const SizedBox(width: 8),
                    _dimChip(Icons.height_rounded,
                        '${floor.totalHeightM}m', 'Height'),
                    const SizedBox(width: 8),
                    _dimChip(Icons.square_foot_rounded,
                        '${floor.totalAreaM2.toInt()}m²', 'Area'),
                  ],
                ),
                const SizedBox(height: 10),
                // Utilization bar
                Row(
                  children: [
                    const Text('Space used:',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMid)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: floor.totalAreaM2 > 0
                              ? floor.usedAreaM2 / floor.totalAreaM2
                              : 0,
                          minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            floor.usedAreaM2 / max(floor.totalAreaM2, 1) > 0.8
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(floor.usedAreaM2 / max(floor.totalAreaM2, 1) * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Surface list
          Expanded(
            child: floor.zones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_off_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        const Text('No surfaces defined',
                            style: TextStyle(color: AppColors.textLight)),
                        const SizedBox(height: 4),
                        const Text('Click "Add Surface" to create one',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: floor.zones.length,
                    itemBuilder: (_, i) =>
                        _buildSurfaceCard(floor, floor.zones[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dimChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ SURFACE CARD ═══════════════════

  Widget _buildSurfaceCard(WarehouseFloor floor, StorageZone zone) {
    final isSelected = zone.id == _selectedZoneId;
    final rng = Random(zone.id.hashCode);
    final picksToday = rng.nextInt(80) + 5;
    final avgTime = (rng.nextDouble() * 4 + 1).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedZoneId = zone.id);
          _showSurfaceDetail(floor, zone);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: zone.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text(zone.type.icon,
                            style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(
                          '${zone.type.label} • ${zone.widthM}×${zone.heightM}m • ${zone.areaM2.toStringAsFixed(1)}m²',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: zone.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      zone.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: zone.status.color),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              const SizedBox(height: 8),
              // Mini stats row
              Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _miniStat(Icons.location_on,
                      'x:${zone.x.toInt()} y:${zone.y.toInt()}',
                      AppColors.textMid),
                  _miniStat(Icons.inventory_2, '$picksToday picks',
                      AppColors.aiBlue),
                  _miniStat(Icons.timer, '${avgTime}min avg',
                      AppColors.accent),
                  // Occupancy bar
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(zone.occupancyRate * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: zone.occupancyRate,
                            minHeight: 4,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation(
                                zone.status.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ═══════════════════ MAP TAP → Surface Detail ═══════════════════

  void _onMapTap(
      Offset pos, BoxConstraints constraints, WarehouseFloor floor) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final sx = w / floor.totalWidthM;
    final sy = h / floor.totalHeightM;
    final s = sx < sy ? sx : sy;

    final tapX = (pos.dx / s).clamp(0.0, floor.totalWidthM);
    final tapY = (pos.dy / s).clamp(0.0, floor.totalHeightM);

    for (var zone in floor.zones) {
      if (tapX >= zone.x &&
          tapX <= zone.x + zone.widthM &&
          tapY >= zone.y &&
          tapY <= zone.y + zone.heightM) {
        setState(() => _selectedZoneId = zone.id);
        _showSurfaceDetail(floor, zone);
        return;
      }
    }
    setState(() => _selectedZoneId = null);
  }

  // ═══════════════════ SHOW SURFACE DETAIL DIALOG ═══════════════════

  void _showSurfaceDetail(WarehouseFloor floor, StorageZone zone) {
    showDialog(
      context: context,
      builder: (_) => SurfaceDetailDialog(
        floor: floor,
        zone: zone,
      ),
    );
  }

  // ═══════════════════ ADD FLOOR DIALOG ═══════════════════

  void _showAddFloorDialog() {
    final nameCtrl = TextEditingController();
    final widthCtrl = TextEditingController(text: '50');
    final heightCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_business_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Add New Floor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Floor Name',
                  hintText: 'e.g. 5ème étage',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Width (m)',
                        prefixIcon: const Icon(Icons.width_normal),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (m)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.aiBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.aiBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.aiBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New floor #${_floors.length} will be added. You can edit dimensions and add surfaces later.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.aiBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final name = nameCtrl.text.isNotEmpty
                  ? nameCtrl.text
                  : WarehouseDataGenerator.floorName(_floors.length);
              final w = double.tryParse(widthCtrl.text) ?? 50;
              final h = double.tryParse(heightCtrl.text) ?? 30;
              setState(() {
                _floors.add(WarehouseFloor(
                  name: name,
                  floorNumber: _floors.length,
                  totalWidthM: w,
                  totalHeightM: h,
                ));
              });
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Floor'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ EDIT FLOOR DIALOG ═══════════════════

  void _showEditFloorDialog(int idx) {
    final floor = _floors[idx];
    final nameCtrl = TextEditingController(text: floor.name);
    final widthCtrl =
        TextEditingController(text: floor.totalWidthM.toString());
    final heightCtrl =
        TextEditingController(text: floor.totalHeightM.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.edit_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Text('Edit ${floor.shortName} Dimensions',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Floor Name',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Width (m)',
                        prefixIcon: const Icon(Icons.width_normal),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (m)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: ${floor.totalWidthM}m × ${floor.totalHeightM}m = ${floor.totalAreaM2.toInt()}m². Zones outside new boundaries may overlap.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMid),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                floor.name = nameCtrl.text;
                floor.totalWidthM =
                    double.tryParse(widthCtrl.text) ?? floor.totalWidthM;
                floor.totalHeightM =
                    double.tryParse(heightCtrl.text) ?? floor.totalHeightM;
              });
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ DELETE FLOOR ═══════════════════

  void _confirmDeleteFloor(int idx) {
    final floor = _floors[idx];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Floor?'),
        content: Text(
          'Are you sure you want to delete "${floor.name}"? This will remove all ${floor.totalZones} surfaces.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _floors.removeAt(idx);
                if (_expandedFloorIdx == idx) _expandedFloorIdx = null;
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ ADD SURFACE DIALOG ═══════════════════

  void _showAddSurfaceDialog(WarehouseFloor floor) {
    final labelCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    final pieceCountCtrl = TextEditingController(text: '0');
    final xCtrl = TextEditingController(text: '0');
    final yCtrl = TextEditingController(text: '0');
    final widthCtrl = TextEditingController(text: '4');
    final heightCtrl = TextEditingController(text: '3');
    ZoneType selectedType = ZoneType.floorStorage;
    ZoneStatus selectedStatus = ZoneStatus.empty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_location_alt,
                    color: AppColors.success),
              ),
              const SizedBox(width: 12),
              const Text('Add Surface',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: TextField(
                            controller: labelCtrl,
                            decoration: InputDecoration(
                              labelText: 'Label',
                              hintText: 'e.g. A5, VRAC, Bureau',
                              prefixIcon: const Icon(Icons.label),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: sectionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: categoryCtrl,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.class_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: pieceCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pieces',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                    const Text('Position (meters)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: xCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'X',
                          prefixIcon: const Icon(Icons.swap_horiz),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: yCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Y',
                          prefixIcon: const Icon(Icons.swap_vert),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                    const Text('Dimensions',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: widthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Width (m)',
                          prefixIcon: const Icon(Icons.width_normal),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (m)',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                    const Text('Type & Status',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ZoneType>(
                          value: selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12),
                          ),
                          items: ZoneType.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                        '${t.icon} ${t.label}',
                                        style: const TextStyle(
                                            fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDlgState(() => selectedType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ZoneStatus>(
                          value: selectedStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12),
                          ),
                          items: ZoneStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Row(children: [
                                      Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: s.color,
                                              shape:
                                                  BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(s.label,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) => setDlgState(
                              () => selectedStatus = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (labelCtrl.text.isEmpty) return;
                final zone = StorageZone(
                  label: labelCtrl.text,
                  section: sectionCtrl.text,
                  category: categoryCtrl.text,
                  pieceCount: int.tryParse(pieceCountCtrl.text) ?? 0,
                  x: double.tryParse(xCtrl.text) ?? 0,
                  y: double.tryParse(yCtrl.text) ?? 0,
                  widthM: double.tryParse(widthCtrl.text) ?? 4,
                  heightM: double.tryParse(heightCtrl.text) ?? 3,
                  type: selectedType,
                  status: selectedStatus,
                );
                setState(() => floor.addZone(zone));
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Surface'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ EDIT SURFACE DIALOG ═══════════════════

  void _showEditSurfaceDialog(WarehouseFloor floor, StorageZone zone) {
    final labelCtrl = TextEditingController(text: zone.label);
    final sectionCtrl = TextEditingController(text: zone.section);
    final categoryCtrl = TextEditingController(text: zone.category);
    final pieceCountCtrl = TextEditingController(text: zone.pieceCount.toString());
    final xCtrl = TextEditingController(text: zone.x.toString());
    final yCtrl = TextEditingController(text: zone.y.toString());
    final widthCtrl = TextEditingController(text: zone.widthM.toString());
    final heightCtrl = TextEditingController(text: zone.heightM.toString());
    final occCtrl = TextEditingController(
        text: (zone.occupancyRate * 100).toStringAsFixed(0));
    ZoneType selectedType = zone.type;
    ZoneStatus selectedStatus = zone.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_location_alt,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Text('Edit "${zone.label}"',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: labelCtrl,
                          decoration: InputDecoration(
                            labelText: 'Label',
                            prefixIcon: const Icon(Icons.label),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: sectionCtrl,
                          decoration: InputDecoration(
                            labelText: 'Section',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: categoryCtrl,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.class_rounded),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: pieceCountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pieces',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: xCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'X (m)',
                            prefixIcon: const Icon(Icons.swap_horiz),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: yCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Y (m)',
                            prefixIcon: const Icon(Icons.swap_vert),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Width (m)',
                            prefixIcon:
                                const Icon(Icons.width_normal),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Height (m)',
                            prefixIcon: const Icon(Icons.height),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ZoneType>(
                          value: selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12),
                          ),
                          items: ZoneType.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                        '${t.icon} ${t.label}',
                                        style: const TextStyle(
                                            fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDlgState(() => selectedType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ZoneStatus>(
                          value: selectedStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12),
                          ),
                          items: ZoneStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Row(children: [
                                      Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: s.color,
                                              shape:
                                                  BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(s.label,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) => setDlgState(
                              () => selectedStatus = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: occCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Occupancy (%)',
                      prefixIcon: const Icon(Icons.battery_std),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  zone.label = labelCtrl.text;
                  zone.section = sectionCtrl.text;
                  zone.category = categoryCtrl.text;
                  zone.pieceCount = int.tryParse(pieceCountCtrl.text) ?? zone.pieceCount;
                  zone.x = double.tryParse(xCtrl.text) ?? zone.x;
                  zone.y = double.tryParse(yCtrl.text) ?? zone.y;
                  zone.widthM =
                      double.tryParse(widthCtrl.text) ?? zone.widthM;
                  zone.heightM =
                      double.tryParse(heightCtrl.text) ?? zone.heightM;
                  zone.type = selectedType;
                  zone.status = selectedStatus;
                  zone.occupancyRate =
                      (double.tryParse(occCtrl.text) ?? 0)
                              .clamp(0, 100) /
                          100;
                });
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ DELETE SURFACE ═══════════════════

  void _confirmDeleteSurface(WarehouseFloor floor, StorageZone zone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Surface?'),
        content: Text(
          'Remove "${zone.label}" (${zone.type.label}, ${zone.areaM2.toStringAsFixed(1)}m²)?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                floor.removeZone(zone.id);
                if (_selectedZoneId == zone.id) _selectedZoneId = null;
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MINI FLOOR PAINTER — For grid-view preview cards
// ═══════════════════════════════════════════════════════════════

class _MiniFloorPainter extends CustomPainter {
  final WarehouseFloor floor;
  _MiniFloorPainter({required this.floor});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / floor.totalWidthM;
    final sy = size.height / floor.totalHeightM;
    final s = sx < sy ? sx : sy;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF0F4F8),
    );

    // Grid
    final gridP = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.4)
      ..strokeWidth = 0.3;
    for (double x = 0; x <= floor.totalWidthM; x += 5) {
      canvas.drawLine(
          Offset(x * s, 0), Offset(x * s, floor.totalHeightM * s), gridP);
    }
    for (double y = 0; y <= floor.totalHeightM; y += 5) {
      canvas.drawLine(
          Offset(0, y * s), Offset(floor.totalWidthM * s, y * s), gridP);
    }

    // Zones
    for (var zone in floor.zones) {
      final rect = Rect.fromLTWH(
          zone.x * s, zone.y * s, zone.widthM * s, zone.heightM * s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = _zoneColor(zone).withValues(alpha: 0.6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = _zoneColor(zone)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(4),
      ),
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Color _zoneColor(StorageZone z) {
    switch (z.type) {
      case ZoneType.elevator:
      case ZoneType.freightElevator:
        return const Color(0xFF90CAF9);
      case ZoneType.preparation:
        return const Color(0xFFCE93D8);
      case ZoneType.shipping:
        return const Color(0xFFF48FB1);
      case ZoneType.office:
        return const Color(0xFFBCAAA4);
      case ZoneType.bulk:
        return const Color(0xFFB39DDB);
      case ZoneType.pillar:
        return const Color(0xFFEF9A9A);
      case ZoneType.aisle:
        return const Color(0xFFE0E0E0);
      default:
        return z.status.color;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniFloorPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  CONFIG FLOOR PAINTER — Full detail with labels, selection & grid
// ═══════════════════════════════════════════════════════════════

class _ConfigFloorPainter extends CustomPainter {
  final WarehouseFloor floor;
  final String? selectedZoneId;
  final double animValue;
  final bool showLabels;

  _ConfigFloorPainter({
    required this.floor,
    this.selectedZoneId,
    this.animValue = 0,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / floor.totalWidthM;
    final sy = size.height / floor.totalHeightM;
    final s = sx < sy ? sx : sy;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFF8F9FA),
    );

    // 1m grid
    final gridP = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    final gridP5 = Paint()
      ..color = const Color(0xFFBDBDBD).withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double x = 0; x <= floor.totalWidthM; x += 1) {
      canvas.drawLine(Offset(x * s, 0), Offset(x * s, floor.totalHeightM * s),
          x % 5 == 0 ? gridP5 : gridP);
    }
    for (double y = 0; y <= floor.totalHeightM; y += 1) {
      canvas.drawLine(Offset(0, y * s), Offset(floor.totalWidthM * s, y * s),
          y % 5 == 0 ? gridP5 : gridP);
    }

    // Zones
    for (var zone in floor.zones) {
      _drawZone(canvas, zone, s);
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(6),
      ),
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Axis labels
    for (double x = 0; x <= floor.totalWidthM; x += 5) {
      _paintText(canvas, '${x.toInt()}m',
          Offset(x * s - 8, floor.totalHeightM * s + 2), 8,
          const Color(0xFF78909C));
    }
    for (double y = 0; y <= floor.totalHeightM; y += 5) {
      _paintText(canvas, '${y.toInt()}m',
          Offset(floor.totalWidthM * s + 2, y * s - 5), 8,
          const Color(0xFF78909C));
    }
  }

  void _drawZone(Canvas canvas, StorageZone zone, double s) {
    final rect = Rect.fromLTWH(
        zone.x * s, zone.y * s, zone.widthM * s, zone.heightM * s);
    final isSelected = zone.id == selectedZoneId;

    Color fill = _zoneColor(zone);

    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = fill.withValues(alpha: isSelected ? 0.9 : 0.65),
    );

    // Occupancy overlay
    if (zone.occupancyRate > 0 && zone.type != ZoneType.elevator && zone.type != ZoneType.freightElevator) {
      final occRect = Rect.fromLTWH(
        zone.x * s,
        zone.y * s + zone.heightM * s * (1 - zone.occupancyRate),
        zone.widthM * s,
        zone.heightM * s * zone.occupancyRate,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            occRect.intersect(rect), const Radius.circular(3)),
        Paint()..color = zone.status.color.withValues(alpha: 0.25),
      );
    }

    // Border
    final borderColor = isSelected
        ? const Color(0xFF1565C0)
        : fill.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.0,
    );

    // Selection pulse
    if (isSelected) {
      final pulse = 2 + 4 * sin(animValue * 2 * pi).abs();
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(pulse), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Label
    if (showLabels && zone.widthM * s > 16 && zone.heightM * s > 10) {
      final fontSize = (s * 0.9).clamp(6.0, 13.0);
      _paintText(
        canvas,
        zone.label,
        Offset(
          zone.x * s + (zone.widthM * s) / 2 - zone.label.length * fontSize * 0.25,
          zone.y * s + (zone.heightM * s) / 2 - fontSize / 2,
        ),
        fontSize,
        Colors.black87,
        bold: true,
      );

      if (zone.heightM * s > 24) {
        final areaText = '${zone.areaM2.toStringAsFixed(1)}m²';
        _paintText(
          canvas,
          areaText,
          Offset(
            zone.x * s + (zone.widthM * s) / 2 - areaText.length * 3,
            zone.y * s + (zone.heightM * s) / 2 + fontSize * 0.6,
          ),
          (fontSize * 0.7).clamp(5.0, 10.0),
          Colors.black54,
        );
      }
    }
  }

  Color _zoneColor(StorageZone z) {
    switch (z.type) {
      case ZoneType.elevator:
      case ZoneType.freightElevator:
        return const Color(0xFF90CAF9);
      case ZoneType.preparation:
        return const Color(0xFFCE93D8);
      case ZoneType.shipping:
        return const Color(0xFFF48FB1);
      case ZoneType.office:
        return const Color(0xFFBCAAA4);
      case ZoneType.bulk:
        return const Color(0xFFB39DDB);
      case ZoneType.pillar:
        return const Color(0xFFEF9A9A);
      case ZoneType.aisle:
        return const Color(0xFFE0E0E0);
      default:
        return z.status.color;
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
  bool shouldRepaint(covariant _ConfigFloorPainter old) => true;
}













