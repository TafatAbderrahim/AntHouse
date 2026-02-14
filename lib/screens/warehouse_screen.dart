import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/warehouse_data.dart';
import '../widgets/warehouse_painter.dart';
import '../widgets/zone_form_dialog.dart';
import '../widgets/surface_detail_dialog.dart';
import '../services/pathfinding_service.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});
  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with TickerProviderStateMixin {
  late List<WarehouseFloor> floors;
  late List<Employee> _employees;
  late List<WarehouseTask> _tasks;

  int _selectedFloor = 0;
  String? _selectedZoneId;
  String? _selectedEmployeeId;
  String? _selectedTaskId;
  int _panelTab = 1; // 0 zones, 1 users

  final _transformCtrl = TransformationController();
  bool _placementMode = false;
  Offset? _cursorPos;
  double _mouseX = 0, _mouseY = 0;

  NavigationResult? _navResult;
  late AnimationController _navAnim;
  bool _isOnline = true;

  // Cross-floor navigation
  CrossFloorResult? _crossFloorResult;
  int _currentSegmentIndex = 0;

  WarehouseFloor get _floor => floors[_selectedFloor];

  Employee? get _selectedEmployee {
    if (_selectedEmployeeId == null) return null;
    for (final e in _employees) {
      if (e.id == _selectedEmployeeId) return e;
    }
    return null;
  }

  List<Employee> get _floorEmployees =>
      _employees.where((e) => e.currentFloorNumber == _floor.floorNumber).toList();

  List<WarehouseTask> get _selectedEmployeeTasks {
    final emp = _selectedEmployee;
    if (emp == null) return const [];
    return _tasks.where((t) => t.assignedEmployeeId == emp.id).toList();
  }

  @override
  void initState() {
    super.initState();
    floors = WarehouseDataGenerator.generateAllFloors();
    _employees = WarehouseDataGenerator.generateEmployees();
    _tasks = WarehouseDataGenerator.generateTasks(_employees);
    _navAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _navAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 980;
    final isPhone = w < 600;
    final hasCrossNav = _crossFloorResult != null && _crossFloorResult!.isCrossFloor;
    final hasActivePath = hasCrossNav || _navResult != null;
    final pad = isPhone ? 4.0 : 8.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        children: [
          _buildFloorSelector(isPhone),
          SizedBox(height: isPhone ? 4 : 6),
          _buildColorLegend(isPhone),
          SizedBox(height: isPhone ? 4 : 6),
          // Cross-floor instructions banner
          if (hasCrossNav && !isWide)
            _buildCrossFloorInstructions(isPhone),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Expanded(flex: hasActivePath ? 20 : 17, child: _buildMap()),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: (w * (hasActivePath ? 0.16 : 0.18)).clamp(220.0, 340.0),
                        child: _buildRightPanel(isPhone),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      // Map fills the entire area
                      Positioned.fill(child: _buildMap()),
                      // Draggable bottom panel — swipe up to expand
                      Positioned.fill(
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.25,
                          minChildSize: 0.08,
                          maxChildSize: 0.70,
                          snap: true,
                          snapSizes: const [0.08, 0.25, 0.50, 0.70],
                          builder: (ctx, scrollCtrl) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, -3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Drag handle
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppColors.textLight.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Panel content
                                  Expanded(
                                    child: CustomScrollView(
                                      controller: scrollCtrl,
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: 500,
                                            child: _buildRightPanel(isPhone),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ CROSS-FLOOR INSTRUCTIONS BANNER ═══════════════════

  Widget _buildCrossFloorInstructions(bool isPhone) {
    final cfr = _crossFloorResult!;
    final titleSize = isPhone ? 14.0 : 18.0;
    final stepSize = isPhone ? 13.0 : 16.0;
    final iconS = isPhone ? 20.0 : 28.0;

    return Container(
      margin: EdgeInsets.only(bottom: isPhone ? 6 : 10),
      padding: EdgeInsets.all(isPhone ? 10 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D84), Color(0xFF0E93AF)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.white, size: iconS),
              SizedBox(width: isPhone ? 8 : 12),
              Expanded(
                child: Text(
                  'Navigation: ${WarehouseDataGenerator.floorName(cfr.sourceFloor)} -> ${WarehouseDataGenerator.floorName(cfr.targetFloor)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 8 : 12,
                  vertical: isPhone ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cfr.totalDistanceM.toStringAsFixed(0)}m',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: isPhone ? 12 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: isPhone ? 6 : 10),
              InkWell(
                onTap: _clearCrossFloor,
                child: Icon(Icons.close, color: Colors.white70, size: isPhone ? 18 : 22),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 8 : 12),
          // Step-by-step instructions
          ...List.generate(cfr.segments.length, (i) {
            final seg = cfr.segments[i];
            final isCurrentStep = i == _currentSegmentIndex;
            final isCompleted = i < _currentSegmentIndex;

            return GestureDetector(
              onTap: () => _jumpToSegment(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 10 : 14,
                  vertical: isPhone ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentStep
                      ? Colors.white.withValues(alpha: 0.2)
                      : isCompleted
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrentStep
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    // Step number / check
                    Container(
                      width: isPhone ? 26 : 32,
                      height: isPhone ? 26 : 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : isCurrentStep
                                ? AppColors.accent
                                : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: isPhone ? 14 : 18)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isCurrentStep
                                      ? AppColors.primaryDark
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isPhone ? 12 : 14,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: isPhone ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seg.instruction,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: stepSize,
                              fontWeight: isCurrentStep
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (seg.distanceM > 0)
                            Text(
                              '${seg.distanceM.toStringAsFixed(1)}m',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: isPhone ? 11 : 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (seg.isElevatorTransition)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.elevator_rounded,
                            color: AppColors.accent,
                            size: isPhone ? 18 : 24),
                      ),
                  ],
                ),
              ),
            );
          }),
          // Next Step Button
          if (_currentSegmentIndex < cfr.segments.length)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
               child: SizedBox(
                 width: double.infinity,
                 child: ElevatedButton.icon(
                   onPressed: () {
                     if (_currentSegmentIndex < cfr.segments.length - 1) {
                       _jumpToSegment(_currentSegmentIndex + 1);
                     } else {
                       _clearCrossFloor(); // Finish
                     }
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.accent,
                     foregroundColor: AppColors.primaryDark,
                     padding: const EdgeInsets.symmetric(vertical: 12),
                   ),
                   icon: Icon(
                     _currentSegmentIndex < cfr.segments.length - 1
                       ? Icons.arrow_downward_rounded
                       : Icons.check_circle_rounded
                   ),
                   label: Text(
                     _currentSegmentIndex < cfr.segments.length - 1
                       ? "Next Step"
                       : "Arrived",
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }

  void _jumpToSegment(int index) {
    if (_crossFloorResult == null) return;
    if (index < 0 || index >= _crossFloorResult!.segments.length) return;
    
    setState(() {
      _currentSegmentIndex = index;
    });

    final seg = _crossFloorResult!.segments[index];
    
    // Switch to the floor of this segment
    final floorIdx = floors.indexWhere((f) => f.floorNumber == seg.floorNumber);
    if (floorIdx != -1) {
       setState(() => _selectedFloor = floorIdx);
    }

    // Show path for this segment
    if (!seg.isElevatorTransition && seg.path.isNotEmpty) {
      // Create a temporary target zone at the end of the path to ensure the marker is drawn correctly
      // on the current floor, instead of drawing the ultimate target which might be on another floor.
      final endP = seg.path.last;
      
      // We'll use a dummy zone for the marker
      final tempTarget = StorageZone(
        id: 'temp_nav_target',
        label: "Next Step",
        x: endP.x > 2 ? endP.x - 1 : endP.x, // simplistic centering attempt
        y: endP.y > 2 ? endP.y - 1 : endP.y,
        widthM: 2,
        heightM: 2,
        type: ZoneType.aisle, 
      );

      final nav = NavigationResult(
        path: seg.path,
        targetZone: tempTarget, 
        entryPoint: seg.path.first,
        totalDistanceM: seg.distanceM,
      );
      setState(() {
        _navResult = nav;
        _navAnim.forward(from: 0);
      });
    } else {
      // Clear path for elevator transition step (just show floor)
      setState(() {
        _navResult = null;
      });
    }
  }

  void _clearCrossFloor() {
    _clearNav();
    setState(() {
      _crossFloorResult = null;
      _currentSegmentIndex = 0;
    });
  }

  Widget _buildCompactInstructionsCard(bool isPhone) {
    final cfr = _crossFloorResult!;
    final cardPad = isPhone ? 8.0 : 10.0;
    return Container(
      margin: EdgeInsets.fromLTRB(cardPad, cardPad, cardPad, 6),
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D84), Color(0xFF0E93AF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Instructions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${cfr.totalDistanceM.toStringAsFixed(0)}m',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: isPhone ? 11 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(cfr.segments.length, (i) {
            final seg = cfr.segments[i];
            final current = i == _currentSegmentIndex;
            return GestureDetector(
              onTap: () => _jumpToSegment(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: current
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: current ? Border.all(color: AppColors.accent, width: 1.3) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: current ? AppColors.accent : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: current ? AppColors.primaryDark : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        seg.instruction,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════ COLOR LEGEND ═══════════════════

  Widget _buildColorLegend(bool isPhone) {
    final items = <_LegendItem>[
      // Zone types
      _LegendItem('Rack Libre', const Color(0xFF4CAF50)),
      _LegendItem('Rack Partiel', const Color(0xFFFFA726)),
      _LegendItem('Rack Plein', const Color(0xFFEF5350)),
      _LegendItem('Rack Critique', const Color(0xFFD32F2F)),
      _LegendItem('Maintenance', const Color(0xFF78909C)),
      _LegendItem('Ascenseur / MC', const Color(0xFF90CAF9)),
      _LegendItem('Préparation', const Color(0xFFCE93D8)),
      _LegendItem('Expédition', const Color(0xFF80CBC4)),
      _LegendItem('VRAC', const Color(0xFFB39DDB)),
      _LegendItem('Bureau', const Color(0xFFBCAAA4)),
      _LegendItem('Pilier', const Color(0xFFEEEEEE)),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 10 : 16,
        vertical: isPhone ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.palette_outlined,
                size: isPhone ? 14 : 16, color: AppColors.textLight),
            SizedBox(width: isPhone ? 6 : 8),
            Text(
              'Légende',
              style: TextStyle(
                fontSize: isPhone ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(width: isPhone ? 8 : 14),
            ...items.map((item) => Padding(
                  padding: EdgeInsets.only(right: isPhone ? 8 : 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isPhone ? 10 : 12,
                        height: isPhone ? 10 : 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.black26,
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isPhone ? 10 : 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ TOP BAR / FLOOR SELECTOR ═══════════════════

  Widget _buildFloorSelector(bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: isPhone ? _buildFloorSelectorPhone() : _buildFloorSelectorDesktop(),
    );
  }

  Widget _buildFloorSelectorPhone() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(floors.length, (i) => _buildFloorChip(i, true)),
          const SizedBox(width: 8),
          _buildOnlineToggle(true),
        ],
      ),
    );
  }

  Widget _buildFloorSelectorDesktop() {
    return Row(
      children: [
        ...List.generate(floors.length, (i) => _buildFloorChip(i, false)),
        const Spacer(),
        _buildOnlineToggle(false),
      ],
    );
  }

  Widget _buildFloorChip(int i, bool isPhone) {
    final f = floors[i];
    final isActive = i == _selectedFloor;
    final occupancy = f.totalZones > 0 ? f.occupiedZones / f.totalZones : 0.0;
    final people = _employees.where((e) => e.currentFloorNumber == f.floorNumber).length;
    final textSize = isPhone ? 13.0 : 16.0;
    final badgeSize = isPhone ? 10.0 : 12.0;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedFloor = i;
        _selectedZoneId = null;
        _selectedEmployeeId = null;
        _selectedTaskId = null;
        _transformCtrl.value = Matrix4.identity();
        _clearNav();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: isPhone ? 6 : 10),
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 10 : 16,
          vertical: isPhone ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.shortName,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white24 : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$people',
                    style: TextStyle(
                      fontSize: badgeSize,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: occupancy,
                  minHeight: 5,
                  backgroundColor: isActive ? Colors.white30 : AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(
                    isActive ? Colors.white : AppColors.success,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(occupancy * 100).toInt()}%',
              style: TextStyle(
                fontSize: isPhone ? 10 : 12,
                color: isActive ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineToggle(bool isPhone) {
    return GestureDetector(
      onTap: () => setState(() => _isOnline = !_isOnline),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 10 : 14,
          vertical: isPhone ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: (_isOnline ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _isOnline ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: isPhone ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: _isOnline ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddZoneBtn(bool isPhone) {
    return IconButton(
      icon: Icon(
        _placementMode ? Icons.close : Icons.add_location_alt_rounded,
        color: _placementMode ? AppColors.accent : AppColors.textMid,
        size: isPhone ? 22 : 26,
      ),
      tooltip: _placementMode ? 'Cancel Placement' : 'Add Zone',
      onPressed: () => setState(() {
        _placementMode = !_placementMode;
        _cursorPos = null;
      }),
    );
  }

  // ═══════════════════ MAP ═══════════════════

  List<EmployeeMarker> _mapMarkers() {
    final result = <EmployeeMarker>[];
    for (final emp in _floorEmployees) {
      List<PathPoint>? path;
      if (_selectedEmployeeId == emp.id && _selectedTaskId != null) {
        final task = _tasks.where((t) => t.id == _selectedTaskId).cast<WarehouseTask?>().firstOrNull;
        if (task != null && task.targetFloorNumber == _floor.floorNumber) {
          final target = _floor.zones.where((z) => z.label == task.targetZoneLabel).cast<StorageZone?>().firstOrNull;
          if (target != null) {
            final nav = PathfindingService.findPath(_floor, target);
            if (nav != null && nav.path.length > 1) {
              path = [PathPoint(emp.positionX, emp.positionY), ...nav.path.skip(1)];
            }
          }
        }
      }
      result.add(
        EmployeeMarker(
          name: emp.name,
          color: emp.color,
          positionX: emp.positionX,
          positionY: emp.positionY,
          activePath: path,
          isSelected: _selectedEmployeeId == emp.id,
        ),
      );
    }
    return result;
  }

  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.3,
              maxScale: 8.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return MouseRegion(
                    onHover: (e) => _onHover(e.localPosition, constraints),
                    child: GestureDetector(
                      onTapDown: (d) => _onTap(d.localPosition, constraints),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 16),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth - 20, constraints.maxHeight - 16),
                          painter: WarehouseFloorPainter(
                            floor: _floor,
                            selectedZoneId: _selectedZoneId,
                            cursorPosition: _cursorPos,
                            previewW: _placementMode ? 2.0 : null,
                            previewH: _placementMode ? 2.0 : null,
                            navigationResult: _navResult,
                            animationValue: _navAnim.value,
                            employeeMarkers: _mapMarkers(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Floor label
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _floor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_floor.totalWidthM.toInt()}m × ${_floor.totalHeightM.toInt()}m • ${_floor.totalAreaM2.toStringAsFixed(0)}m²',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // Coordinates
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'X:${_mouseX.toStringAsFixed(1)}  Y:${_mouseY.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            // Nav result badge
            if (_navResult != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_navResult!.targetZone.label} • ${_navResult!.totalDistanceM.toStringAsFixed(1)}m',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _clearCrossFloor,
                        child: const Icon(Icons.close, color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            // Zoom controls
            Positioned(
              bottom: 10,
              right: 10,
              child: Column(
                children: [
                  _zoomBtn(Icons.add, () => _zoom(1.4)),
                  const SizedBox(height: 4),
                  _zoomBtn(Icons.remove, () => _zoom(0.7)),
                  const SizedBox(height: 4),
                  _zoomBtn(Icons.fit_screen, () => _transformCtrl.value = Matrix4.identity()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }

  // ═══════════════════ RIGHT PANEL ═══════════════════

  Widget _buildRightPanel(bool isPhone) {
    final hasCrossNav = _crossFloorResult != null && _crossFloorResult!.isCrossFloor;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          if (hasCrossNav) _buildCompactInstructionsCard(isPhone),
          Padding(
            padding: EdgeInsets.all(isPhone ? 8 : 12),
            child: Row(
              children: [
                _tabBtn(0, Icons.grid_view_rounded, 'Zones', isPhone),
                SizedBox(width: isPhone ? 6 : 8),
                _tabBtn(1, Icons.people_alt_rounded, 'Users', isPhone),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _panelTab == 0 ? _buildZonePanel(isPhone) : _buildUsersPanel(isPhone),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label, bool isPhone) {
    final active = _panelTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _panelTab = idx),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isPhone ? 8 : 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isPhone ? 18 : 22, color: active ? AppColors.primary : AppColors.textMid),
              SizedBox(width: isPhone ? 4 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isPhone ? 13 : 16,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersPanel(bool isPhone) {
    if (_selectedEmployee == null) {
      final allEmployees = List<Employee>.from(_employees)
        ..sort((a, b) => a.name.compareTo(b.name));
      return ListView.builder(
        padding: EdgeInsets.all(isPhone ? 8 : 12),
        itemCount: allEmployees.length,
        itemBuilder: (_, i) {
          final e = allEmployees[i];
          final myTasks = _tasks.where((t) => t.assignedEmployeeId == e.id).toList();
          final floorName = WarehouseDataGenerator.floorName(e.currentFloorNumber);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: e.color.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 14, vertical: 4),
              leading: CircleAvatar(
                radius: isPhone ? 18 : 22,
                backgroundColor: e.color,
                child: Text(e.name[0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPhone ? 14 : 16)),
              ),
              title: Text(e.name, style: TextStyle(fontSize: isPhone ? 14 : 17, fontWeight: FontWeight.w700)),
              subtitle: Text('${e.role.label} • ${myTasks.length} tasks • $floorName', style: TextStyle(fontSize: isPhone ? 12 : 14)),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  floorName,
                  style: TextStyle(
                    fontSize: isPhone ? 11 : 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              onTap: () {
                final floorIdx = floors.indexWhere((f) => f.floorNumber == e.currentFloorNumber);
                setState(() {
                  if (floorIdx != -1) _selectedFloor = floorIdx;
                  _selectedEmployeeId = e.id;
                  _selectedTaskId = null;
                  _selectedZoneId = null;
                });
              },
            ),
          );
        },
      );
    }

    final emp = _selectedEmployee!;
    final tasks = _selectedEmployeeTasks;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 14),
          decoration: BoxDecoration(
            color: emp.color.withValues(alpha: 0.08),
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedEmployeeId = null;
                    _selectedTaskId = null;
                    _clearCrossFloor();
                  });
                },
                child: Icon(Icons.arrow_back_rounded, size: isPhone ? 18 : 22),
              ),
              SizedBox(width: isPhone ? 8 : 12),
              CircleAvatar(
                radius: isPhone ? 18 : 22,
                backgroundColor: emp.color,
                child: Text(emp.name[0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPhone ? 14 : 16)),
              ),
              SizedBox(width: isPhone ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp.name, style: TextStyle(fontSize: isPhone ? 14 : 17, fontWeight: FontWeight.w700)),
                    Text('${emp.role.label} • ${tasks.length} tasks • ${WarehouseDataGenerator.floorName(emp.currentFloorNumber)}',
                        style: TextStyle(fontSize: isPhone ? 12 : 14, color: AppColors.textMid)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks for this user',
                    style: TextStyle(fontSize: isPhone ? 14 : 16, color: AppColors.textLight),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 8 : 12),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    final isActive = _selectedTaskId == t.id;
                    final isCrossFloor = emp.currentFloorNumber != t.targetFloorNumber;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.divider,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 14, vertical: 4),
                        title: Text(t.productName,
                            style: TextStyle(fontSize: isPhone ? 13 : 16, fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.orderCode} • ${WarehouseDataGenerator.floorName(t.targetFloorNumber)} • ${t.targetZoneLabel}',
                              style: TextStyle(fontSize: isPhone ? 11 : 13),
                            ),
                            if (isCrossFloor)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.elevator_rounded, size: isPhone ? 12 : 14, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Cross-floor',
                                      style: TextStyle(
                                        fontSize: isPhone ? 10 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: FilledButton(
                          onPressed: () => _showTaskPath(emp, t),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 8 : 12,
                              vertical: isPhone ? 4 : 6,
                            ),
                            textStyle: TextStyle(
                              fontSize: isPhone ? 11 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Show Path'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════ ZONE PANEL ═══════════════════

  Widget _buildZonePanel(bool isPhone) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isPhone ? 10 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: isPhone ? 18 : 22, color: AppColors.primaryDark),
                  SizedBox(width: isPhone ? 6 : 10),
                  Text('Zones',
                      style: TextStyle(fontSize: isPhone ? 16 : 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const Spacer(),
                  Text('${_floor.totalZones} total',
                      style: TextStyle(fontSize: isPhone ? 12 : 14, color: AppColors.textLight)),
                ],
              ),
              SizedBox(height: isPhone ? 8 : 12),
              Row(
                children: [
                  _statChip('Free', '${_floor.freeZones}', AppColors.success, isPhone),
                  const SizedBox(width: 6),
                  _statChip('Occupied', '${_floor.occupiedZones}', AppColors.accent, isPhone),
                  const SizedBox(width: 6),
                  _statChip('Critical', '${_floor.criticalZones}', AppColors.error, isPhone),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _floor.zones.isEmpty
              ? Center(
                  child: Text('No zones on this floor',
                      style: TextStyle(color: AppColors.textLight, fontSize: isPhone ? 13 : 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(isPhone ? 6 : 10),
                  itemCount: _floor.zones.length,
                  itemBuilder: (_, i) => _buildZoneRow(_floor.zones[i], isPhone),
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color, bool isPhone) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 5 : 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: isPhone ? 16 : 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: isPhone ? 10 : 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneRow(StorageZone zone, bool isPhone) {
    final isSelected = zone.id == _selectedZoneId;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity(vertical: isPhone ? -3 : -1),
        contentPadding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 12),
        leading: Container(
          width: isPhone ? 28 : 34,
          height: isPhone ? 28 : 34,
          decoration: BoxDecoration(color: zone.status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(zone.type.icon, style: TextStyle(fontSize: isPhone ? 12 : 15))),
        ),
        title: Text(zone.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isPhone ? 13 : 16)),
        subtitle: Text('${zone.areaM2.toStringAsFixed(1)}m² • ${zone.status.label}',
            style: TextStyle(fontSize: isPhone ? 11 : 13, color: AppColors.textLight)),
        trailing: InkWell(
          onTap: () => _navigateToZone(zone),
          child: Icon(Icons.navigation_rounded, size: isPhone ? 16 : 20, color: AppColors.textLight),
        ),
        onTap: () {
          setState(() => _selectedZoneId = zone.id);
          _navigateToZone(zone);
        },
      ),
    );
  }

  // ═══════════════════ ACTIONS ═══════════════════

  void _showTaskPath(Employee employee, WarehouseTask task) {
    final isCrossFloor = employee.currentFloorNumber != task.targetFloorNumber;

    if (isCrossFloor) {
      // ── CROSS-FLOOR: Use findCrossFloorPath ──
      final targetFloor = floors.firstWhere(
        (f) => f.floorNumber == task.targetFloorNumber,
        orElse: () => floors.first,
      );
      StorageZone? zone;
      for (final z in targetFloor.zones) {
        if (z.label == task.targetZoneLabel) {
          zone = z;
          break;
        }
      }
      if (zone == null) return;

      final crossResult = PathfindingService.findCrossFloorPath(
        floors,
        employee.currentFloorNumber,
        zone,
        task.targetFloorNumber,
      );

      if (crossResult == null) return;

      // Show the first non-elevator segment's floor
      int firstFloorIdx = _selectedFloor;
      NavigationResult? firstNav;
      int firstSegIdx = 0;

      for (int i = 0; i < crossResult.segments.length; i++) {
        final seg = crossResult.segments[i];
        if (!seg.isElevatorTransition && seg.path.isNotEmpty) {
          final flIdx = floors.indexWhere((f) => f.floorNumber == seg.floorNumber);
          if (flIdx != -1) {
            firstFloorIdx = flIdx;
            firstNav = NavigationResult(
              path: seg.path,
              targetZone: zone,
              entryPoint: seg.path.first,
              totalDistanceM: seg.distanceM,
            );
            firstSegIdx = i;
          }
          break;
        }
      }

      setState(() {
        _selectedFloor = firstFloorIdx;
        _selectedEmployeeId = employee.id;
        _selectedTaskId = task.id;
        _selectedZoneId = zone!.id;
        _crossFloorResult = crossResult;
        _currentSegmentIndex = firstSegIdx;
        _navResult = firstNav;
        _transformCtrl.value = Matrix4.identity();
      });
      if (firstNav != null) _navAnim.repeat();
    } else {
      // ── SAME FLOOR: Use findPath ──
      final targetFloorIdx = floors.indexWhere((f) => f.floorNumber == task.targetFloorNumber);
      if (targetFloorIdx == -1) return;

      final targetFloor = floors[targetFloorIdx];
      StorageZone? zone;
      for (final z in targetFloor.zones) {
        if (z.label == task.targetZoneLabel) {
          zone = z;
          break;
        }
      }
      if (zone == null) return;

      final nav = PathfindingService.findPath(targetFloor, zone);
      setState(() {
        _selectedFloor = targetFloorIdx;
        _selectedEmployeeId = employee.id;
        _selectedTaskId = task.id;
        _selectedZoneId = zone!.id;
        _navResult = nav;
        _crossFloorResult = null;
        _currentSegmentIndex = 0;
        _transformCtrl.value = Matrix4.identity();
      });
      if (nav != null) _navAnim.repeat();
    }
  }

  void _navigateToZone(StorageZone zone) {
    final result = PathfindingService.findPath(_floor, zone);
    setState(() {
      _navResult = result;
      _selectedZoneId = zone.id;
      _selectedTaskId = null;
      _crossFloorResult = null;
    });
    if (result != null) _navAnim.repeat();
  }

  void _clearNav() {
    _navAnim.stop();
    _navAnim.reset();
    setState(() => _navResult = null);
  }

  void _onHover(Offset pos, BoxConstraints c) {
    final s = _getScale(c);
    // InteractiveViewer can pan/zoom the child. Convert viewport coordinates
    // to scene (child) coordinates before mapping to meters.
    final scenePos = _transformCtrl.toScene(pos);
    setState(() {
      _mouseX = (scenePos.dx / s).clamp(0.0, _floor.totalWidthM);
      _mouseY = (scenePos.dy / s).clamp(0.0, _floor.totalHeightM);
      if (_placementMode) _cursorPos = scenePos;
    });
  }

  void _onTap(Offset pos, BoxConstraints c) {
    final s = _getScale(c);
    // Convert from viewport to scene coordinates to account for pan/zoom.
    final scenePos = _transformCtrl.toScene(pos);
    final tapX = (scenePos.dx / s).clamp(0.0, _floor.totalWidthM);
    final tapY = (scenePos.dy / s).clamp(0.0, _floor.totalHeightM);

    if (_placementMode) {
      _showAddZone(tapX: tapX, tapY: tapY);
      return;
    }

    for (final emp in _floorEmployees) {
      final dx = tapX - emp.positionX;
      final dy = tapY - emp.positionY;
      if ((dx * dx + dy * dy) <= 4.0) {
        setState(() {
          _selectedEmployeeId = emp.id;
          _selectedTaskId = null;
          _selectedZoneId = null;
          _panelTab = 1;
          _clearNav();
        });
        return;
      }
    }

    StorageZone? found;
    for (var z in _floor.zones) {
      if (tapX >= z.x && tapX <= z.x + z.widthM && tapY >= z.y && tapY <= z.y + z.heightM) {
        found = z;
        break;
      }
    }
    if (found != null) {
      setState(() => _selectedZoneId = found!.id);
      showDialog(
        context: context,
        builder: (_) => SurfaceDetailDialog(floor: _floor, zone: found!),
      );
    }
  }

  double _getScale(BoxConstraints c) {
    final w = c.maxWidth - 20;
    final h = c.maxHeight - 16;
    final sx = w / _floor.totalWidthM;
    final sy = h / _floor.totalHeightM;
    return sx < sy ? sx : sy;
  }

  void _zoom(double factor) {
    final cur = _transformCtrl.value.getMaxScaleOnAxis();
    final ns = (cur * factor).clamp(0.3, 8.0);
    _transformCtrl.value = Matrix4.diagonal3Values(ns, ns, 1.0);
  }

  Future<void> _showAddZone({double? tapX, double? tapY}) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ZoneFormDialog(floor: _floor, tapX: tapX, tapY: tapY),
    );
    if (result is StorageZone) {
      setState(() {
        _floor.addZone(result);
        _selectedZoneId = result.id;
        _placementMode = false;
        _cursorPos = null;
      });
    }
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}
