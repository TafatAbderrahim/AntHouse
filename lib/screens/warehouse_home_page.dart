import 'package:flutter/material.dart';
import '../models/warehouse_data.dart';
import '../widgets/warehouse_painter.dart';
import '../widgets/zone_form_dialog.dart';
import '../services/pathfinding_service.dart';
import 'delivery_success_screen.dart';

class WarehouseHomePage extends StatefulWidget {
  final Employee currentEmployee;
  final List<Employee> allEmployees;
  final List<WarehouseTask>? sharedTasks;
  final String? initialTaskId;

  const WarehouseHomePage({
    super.key,
    required this.currentEmployee,
    required this.allEmployees,
    this.sharedTasks,
    this.initialTaskId,
  });

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage>
    with TickerProviderStateMixin {
  late List<WarehouseFloor> floors;
  late List<WarehouseTask> tasks;
  int selectedFloorIndex = 0;
  String? selectedZoneId;
  late TabController _tabController;
  final TransformationController _transformController =
      TransformationController();
  bool _placementMode = false;
  Offset? _cursorPos;
  double _mouseX = 0, _mouseY = 0;

  // Navigation
  CrossFloorResult? _crossFloorResult;
  NavigationResult? _activeFloorNav;
  late AnimationController _navAnimController;
  WarehouseTask? _activeTask;
  int _activeStepIndex = 0;

  // Draggable panel controller
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  static const double _sheetCollapsed = 0.16;
  static const double _sheetExpanded = 0.72;

  // ★ Employee selection — supervisor/admin picks one employee to view
  Employee? _selectedEmployeeView;

  UserRole get _role => widget.currentEmployee.role;
  bool get _isEmployee => _role == UserRole.employee;
  bool get _isSupervisor => _role == UserRole.supervisor;
  bool get _isAdmin => _role == UserRole.admin;
  bool get _canManageZones => _isAdmin;
  WarehouseFloor get currentFloor => floors[selectedFloorIndex];

  List<Employee> get _employees =>
      widget.allEmployees.where((e) => e.role == UserRole.employee).toList();

  List<WarehouseTask> get _myTasks => tasks
      .where((t) => t.assignedEmployeeId == widget.currentEmployee.id)
      .toList();

  List<WarehouseTask> get _selectedEmployeeTasks {
    if (_selectedEmployeeView == null) return [];
    return tasks
        .where((t) => t.assignedEmployeeId == _selectedEmployeeView!.id)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    floors = WarehouseDataGenerator.generateAllFloors();
    tasks = widget.sharedTasks ?? WarehouseDataGenerator.generateTasks(widget.allEmployees);
    _tabController = TabController(length: floors.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedFloorIndex = _tabController.index;
          selectedZoneId = null;
          _transformController.value = Matrix4.identity();
          _updateActiveFloorNav();
        });
      }
    });
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() => setState(() {}));

    // Auto-open a task path when coming from scan/detail screen
    if (_isEmployee && widget.initialTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final task = tasks.cast<WarehouseTask?>().firstWhere(
            (t) => t?.id == widget.initialTaskId,
            orElse: () => null);
        if (task != null) {
          _startTask(task);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transformController.dispose();
    _navAnimController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _expandSheet() {
    _setSheetSize(_sheetExpanded);
  }

  void _collapseSheet() {
    _setSheetSize(_sheetCollapsed);
  }

  void _setSheetSize(double target) {
    if (!_sheetController.isAttached) return;
    final clamped = target.clamp(_sheetCollapsed, _sheetExpanded);
    final current = _sheetController.size;
    if ((current - clamped).abs() < 0.001) return;
    _sheetController.jumpTo(clamped);
  }

  void _onSheetHandleDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (!_sheetController.isAttached) return;
    final h = MediaQuery.of(context).size.height;
    if (h <= 0) return;
    final delta = (details.primaryDelta ?? 0) / h;
    _setSheetSize(_sheetController.size - delta);
  }

  void _onSheetHandleDragEnd() {
    if (!_sheetController.isAttached) return;
    final current = _sheetController.size;
    final midpoint = (_sheetCollapsed + _sheetExpanded) / 2;
    _setSheetSize(current >= midpoint ? _sheetExpanded : _sheetCollapsed);
  }

  // ═══════════════════ BUILD ═══════════════════

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(isWide),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      floatingActionButton: _canManageZones
          ? FloatingActionButton.extended(
              onPressed: () => _showAddZoneDialog(),
              backgroundColor: const Color(0xFF1A237E),
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: const Text('Ajouter Zone',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isWide) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A237E),
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: widget.currentEmployee.color,
          child: Text(widget.currentEmployee.name[0],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      title: Row(
        children: [
          SizedBox(
            height: 30,
            width: 30,
            child: ClipRect(
              child: Transform.scale(
                scale: 2.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ANT HOUSE',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${widget.currentEmployee.name} • ${widget.currentEmployee.role.label}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Coordinates — only on wide screens
        if (isWide)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.my_location, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                'X:${_mouseX.toStringAsFixed(1)} Y:${_mouseY.toStringAsFixed(1)}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace'),
              ),
            ]),
          ),
        if (_canManageZones)
          IconButton(
            icon: Icon(_placementMode ? Icons.close : Icons.pin_drop,
                color: _placementMode ? Colors.amber : Colors.white70),
            tooltip: _placementMode ? 'Quitter placement' : 'Mode placement',
            onPressed: () => setState(() {
              _placementMode = !_placementMode;
              _cursorPos = null;
            }),
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          tooltip: 'Déconnexion',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.amber,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        isScrollable: true,
        tabs: floors.map((f) {
          final isTarget = _crossFloorResult != null &&
              f.floorNumber == _crossFloorResult!.targetFloor;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(f.floorNumber == 0 ? Icons.home : Icons.layers,
                    size: 16, color: isTarget ? Colors.amber : null),
                const SizedBox(width: 6),
                Text(f.shortName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isTarget ? FontWeight.bold : FontWeight.normal,
                        color: isTarget ? Colors.amber : null)),
                if (isTarget)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.flag, size: 12, color: Colors.amber),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════ LAYOUTS ═══════════════════

  Widget _buildWideLayout() {
    return Row(children: [
      Expanded(flex: 3, child: _buildMapSection()),
      SizedBox(width: 360, child: _buildSidePanel()),
    ]);
  }

  // ★ MOBILE FIX: full-screen map + draggable bottom panel
  Widget _buildNarrowLayout() {
    return Stack(
      children: [
        // Map fills entire screen
        Positioned.fill(
          child: _buildMapSection(fullScreen: true),
        ),
        // Draggable bottom panel
        DraggableScrollableSheet(
          controller: _sheetController,
          expand: false,
          initialChildSize: _sheetCollapsed,
          minChildSize: _sheetCollapsed,
          maxChildSize: _sheetExpanded,
          snap: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  // Simple controls: drag bar + explicit expand/collapse buttons
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) =>
                        _onSheetHandleDragUpdate(d, context),
                    onVerticalDragEnd: (_) => _onSheetHandleDragEnd(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _collapseSheet,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            tooltip: 'Collapse panel',
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _expandSheet,
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                            tooltip: 'Expand panel',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildStatsHeader(),
                  const Divider(height: 1),
                  if (_isEmployee)
                    ..._myTasks.map((t) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildTaskCard(t, _activeTask?.id == t.id),
                        ))
                  else
                    ..._buildSupervisorItems(),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════ MAP ═══════════════════

  Widget _buildMapSection({bool fullScreen = false}) {
    return Padding(
      padding: fullScreen ? EdgeInsets.zero : const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(fullScreen ? 0 : 16),
          boxShadow: fullScreen
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(fullScreen ? 0 : 16),
          child: Stack(children: [
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.3,
              maxScale: 8.0,
              boundaryMargin: const EdgeInsets.all(80),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return MouseRegion(
                    onHover: (e) =>
                        _onMouseMove(e.localPosition, constraints),
                    child: GestureDetector(
                      onTapDown: (d) =>
                          _onMapTap(d.localPosition, constraints),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(right: 20, bottom: 16),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth - 20,
                              constraints.maxHeight - 16),
                          painter: WarehouseFloorPainter(
                            floor: currentFloor,
                            selectedZoneId: selectedZoneId,
                            cursorPosition: _cursorPos,
                            previewW: _placementMode ? 2.0 : null,
                            previewH: _placementMode ? 2.0 : null,
                            navigationResult: _activeFloorNav,
                            animationValue: _navAnimController.value,
                            // ★ Always pass employee markers
                            employeeMarkers: _buildEmployeeMarkers(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentFloor.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      '${currentFloor.totalWidthM.toInt()}m × ${currentFloor.totalHeightM.toInt()}m',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            // Placement badge
            if (_placementMode)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pin_drop, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Mode Placement',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),

            // Cross-floor steps banner
            if (_crossFloorResult != null && _crossFloorResult!.isCrossFloor)
              Positioned(
                top: 10,
                right: 10,
                child: _buildCrossFloorSteps(),
              ),

            // Nav banner (same floor)
            if (_crossFloorResult != null &&
                !_crossFloorResult!.isCrossFloor &&
                _activeFloorNav != null)
              Positioned(top: 10, right: 10, child: _buildNavBanner()),

            // ★ Selected employee info chip on map
            if (_selectedEmployeeView != null && !_isEmployee)
              Positioned(
                bottom: 60,
                left: 10,
                child: _buildSelectedEmployeeMapChip(),
              ),

            // Employee action button: finish when arrived
            if (_isEmployee && _activeTask != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: _buildEmployeeFinishButton(),
              ),

            // Zoom controls
            Positioned(
              bottom: 10,
              right: 10,
              child: Column(children: [
                _ZoomBtn(Icons.add, () => _zoom(1.4)),
                const SizedBox(height: 4),
                _ZoomBtn(Icons.remove, () => _zoom(0.7)),
                const SizedBox(height: 4),
                _ZoomBtn(Icons.fit_screen,
                    () => _transformController.value = Matrix4.identity()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ★ Floating chip on map showing selected employee
  Widget _buildSelectedEmployeeMapChip() {
    final emp = _selectedEmployeeView!;
    final activeTasks = _selectedEmployeeTasks
        .where((t) => t.status != TaskStatus.completed)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
        border: Border.all(color: emp.color, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: emp.color,
          child: Text(emp.name[0],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emp.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            Text(
                '$activeTasks tâche(s) • ${WarehouseDataGenerator.floorName(emp.currentFloorNumber)}',
                style:
                    TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _selectEmployee(null),
          child:
              Icon(Icons.close, size: 16, color: Colors.grey.shade400),
        ),
      ]),
    );
  }

  Widget _buildEmployeeFinishButton() {
    final task = _activeTask!;
    final onTargetFloor = selectedFloorIndex == task.targetFloorNumber;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _finishEmployeeTask,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: onTargetFloor ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(onTargetFloor ? Icons.check_circle : Icons.navigation, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                onTargetFloor ? 'Terminer' : 'Aller à la zone',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ CROSS-FLOOR STEPS ═══════════════════

  Widget _buildCrossFloorSteps() {
    final segments = _crossFloorResult!.segments;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.route, color: Color(0xFF1A237E), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎯 ${_crossFloorResult!.targetZone.label} (${WarehouseDataGenerator.floorName(_crossFloorResult!.targetFloor)})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF1A237E)),
              ),
            ),
            InkWell(
              onTap: _clearNavigation,
              child: const Icon(Icons.close, size: 16, color: Colors.grey),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Distance: ${_crossFloorResult!.totalDistanceM.toStringAsFixed(1)} m',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          ...List.generate(segments.length, (i) {
            final seg = segments[i];
            final isActive = i == _activeStepIndex;
            return InkWell(
              onTap: () => _goToStep(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE3F2FD)
                      : seg.isElevatorTransition
                          ? const Color(0xFFFFF8E1)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(
                          color: const Color(0xFF1565C0), width: 1.5)
                      : null,
                ),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : seg.isElevatorTransition
                              ? const Color(0xFFFFA726)
                              : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: seg.isElevatorTransition
                          ? const Icon(Icons.elevator,
                              size: 12, color: Colors.white)
                          : Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(seg.instruction,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                        if (seg.distanceM > 0)
                          Text('${seg.distanceM.toStringAsFixed(1)} m',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.arrow_forward_ios,
                        size: 10, color: Color(0xFF1565C0)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF6D00), Color(0xFFFF8F00)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text('To: ${_crossFloorResult!.targetZone.label}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(
                  '${_crossFloorResult!.totalDistanceM.toStringAsFixed(1)} m',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _clearNavigation,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════ SIDE PANEL ═══════════════════

  Widget _buildSidePanel() {
    return Container(
      margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(children: [
        _buildStatsHeader(),
        const Divider(height: 1),
        Expanded(
          child: _isEmployee
              ? _buildTaskList()
              : ListView(
                  padding: const EdgeInsets.all(10),
                  children: _buildSupervisorItems(),
                ),
        ),
      ]),
    );
  }

  Widget _buildStatsHeader() {
    final f = currentFloor;
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          Icon(
            _isEmployee ? Icons.assignment : Icons.analytics_outlined,
            color: const Color(0xFF1A237E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isEmployee ? 'Mes Tâches' : 'Dashboard',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)),
          ),
          const Spacer(),
          Text('${f.totalWidthM.toInt()}×${f.totalHeightM.toInt()}m',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          if (_isAdmin) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showFloorSettingsDialog(),
              child: Tooltip(
                message: 'Modifier surface',
                child:
                    Icon(Icons.edit, size: 13, color: Colors.grey.shade400),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatChip('Zones', '${f.totalZones}', const Color(0xFF5C6BC0)),
          _StatChip('Libres', '${f.freeZones}', const Color(0xFF66BB6A)),
          _StatChip(
              'Pleines', '${f.criticalZones}', const Color(0xFFEF5350)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _AreaChip('${f.usedAreaM2.toStringAsFixed(0)} m²', 'Utilisé',
              const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          _AreaChip('${f.freeAreaM2.toStringAsFixed(0)} m²', 'Disponible',
              Colors.green.shade700),
          const SizedBox(width: 6),
          _AreaChip('${f.totalAreaM2.toStringAsFixed(0)} m²', 'Total',
              const Color(0xFF455A64)),
        ]),
      ]),
    );
  }

  // ═══════════════════ EMPLOYEE TASK LIST ═══════════════════

  Widget _buildTaskList() {
    final myTasks = _myTasks;
    if (myTasks.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          SizedBox(height: 8),
          Text('Aucune tâche en attente',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text('Beau travail ! 🎉',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: myTasks.length,
      itemBuilder: (context, index) {
        final task = myTasks[index];
        return _buildTaskCard(task, _activeTask?.id == task.id);
      },
    );
  }

  Widget _buildTaskCard(WarehouseTask task, bool isActive) {
    final targetFloorName =
        WarehouseDataGenerator.floorName(task.targetFloorNumber);
    final needsCrossFloor =
        task.targetFloorNumber != widget.currentEmployee.currentFloorNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive ? const Color(0xFF1565C0) : Colors.grey.shade200,
            width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startTask(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: task.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(task.status.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: task.status.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(task.status.label,
                            style: TextStyle(
                                fontSize: 9,
                                color: task.status.color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Zone ${task.targetZoneLabel}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(targetFloorName,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (needsCrossFloor)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.elevator,
                                size: 12, color: Colors.orange),
                            const SizedBox(width: 3),
                            Text('-> $targetFloorName',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startTask(task),
                  icon: Icon(
                      isActive ? Icons.visibility : Icons.navigation,
                      size: 16),
                  label: Text(
                    isActive ? 'Voir le chemin' : 'Commencer',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xFFFF6D00)
                        : const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ SUPERVISOR / ADMIN PANEL ═══════════════════

  /// Shared items for both wide side panel and narrow bottom sheet
  List<Widget> _buildSupervisorItems() {
    return [
      // ★ Employee selector
      _buildEmployeeSelector(),
      const SizedBox(height: 6),

      // ★ Selected employee's tasks
      if (_selectedEmployeeView != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: _selectedEmployeeView!.color,
              child: Text(_selectedEmployeeView!.name[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Tâches de ${_selectedEmployeeView!.name}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A237E))),
            ),
            Text('${_selectedEmployeeTasks.length}',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ),
        ..._selectedEmployeeTasks.map((t) => _buildMiniTaskCard(t)),
        if (_selectedEmployeeTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('Aucune tâche assignée',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12)),
            ),
          ),
        const SizedBox(height: 10),
      ],

      // Zone list header
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(children: [
          const Text('📍 Zones',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1A237E))),
          const Spacer(),
          Text('${currentFloor.zones.length} zones',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ]),
      ),
      ...currentFloor.zones.map((zone) => _buildZoneRow(zone)),
      const SizedBox(height: 80),
    ];
  }

  // ★ Horizontal scrollable employee selector
  Widget _buildEmployeeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👥 Sélectionner un employé',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _employees.map((emp) {
                final isSelected = _selectedEmployeeView?.id == emp.id;
                final empTaskCount = tasks
                    .where((t) =>
                        t.assignedEmployeeId == emp.id &&
                        t.status != TaskStatus.completed)
                    .length;
                return GestureDetector(
                  onTap: () =>
                      _selectEmployee(isSelected ? null : emp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? emp.color.withValues(alpha: 0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? emp.color
                            : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color:
                                      emp.color.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: emp.color,
                          child: Text(emp.name[0],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        const SizedBox(height: 6),
                        Text(emp.name,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? emp.color
                                    : Colors.black87)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: emp.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              WarehouseDataGenerator.floorName(
                                  emp.currentFloorNumber),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (empTaskCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  emp.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$empTaskCount tâche(s)',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: emp.color,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ★ Compact task card for supervisor view of employee tasks
  Widget _buildMiniTaskCard(WarehouseTask task) {
    final targetFloorName =
        WarehouseDataGenerator.floorName(task.targetFloorNumber);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Text(task.status.icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              Text('🎯 ${task.targetZoneLabel} • $targetFloorName',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
        InkWell(
          onTap: () =>
              _viewEmployeeTask(task, _selectedEmployeeView!),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation, size: 12, color: Colors.white),
                SizedBox(width: 3),
                Text('Chemin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildZoneRow(StorageZone zone) {
    final isSelected = zone.id == selectedZoneId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF1565C0), width: 1.5)
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: zone.status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
              child: Text(zone.type.icon,
                  style: const TextStyle(fontSize: 12))),
        ),
        title: Text(zone.label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        subtitle: Text(
          '${zone.areaM2.toStringAsFixed(1)}m² • ${zone.status.label}',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          InkWell(
            onTap: () =>
                _navigateToZoneOnFloor(zone, currentFloor.floorNumber),
            child: Icon(Icons.navigation,
                size: 12, color: Colors.grey.shade400),
          ),
          if (_canManageZones) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showEditZoneDialog(zone),
              child:
                  const Icon(Icons.edit, size: 12, color: Colors.grey),
            ),
          ],
        ]),
        onTap: () {
          setState(() => selectedZoneId = zone.id);
          _navigateToZoneOnFloor(zone, currentFloor.floorNumber);
        },
      ),
    );
  }

  // ═══════════════════ ACTIONS ═══════════════════

  void _startTask(WarehouseTask task) {
    final targetFloor =
        floors.firstWhere((f) => f.floorNumber == task.targetFloorNumber);
    final targetZone = targetFloor.zones.cast<StorageZone?>().firstWhere(
        (z) => z!.label == task.targetZoneLabel,
        orElse: () => null);
    if (targetZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Zone "${task.targetZoneLabel}" introuvable au ${WarehouseDataGenerator.floorName(task.targetFloorNumber)}')),
      );
      return;
    }

    task.status = TaskStatus.inProgress;

    final result = PathfindingService.findCrossFloorPath(
      floors,
      widget.currentEmployee.currentFloorNumber,
      targetZone,
      task.targetFloorNumber,
    );

    setState(() {
      _activeTask = task;
      _crossFloorResult = result;
      _activeStepIndex = 0;
    });

    if (result != null) {
      _navAnimController.repeat();
      _updateActiveFloorNav();
      if (result.segments.isNotEmpty) {
        final firstFloor = result.segments.first.floorNumber;
        if (firstFloor >= 0) {
          final idx =
              floors.indexWhere((f) => f.floorNumber == firstFloor);
          if (idx >= 0) _tabController.animateTo(idx);
        }
      }
    }
  }

  void _finishEmployeeTask() {
    final task = _activeTask;
    if (task == null) return;
    final onTargetFloor = selectedFloorIndex == task.targetFloorNumber;
    if (!onTargetFloor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Allez au ${WarehouseDataGenerator.floorName(task.targetFloorNumber)} puis terminez la tâche.'),
        ),
      );
      return;
    }

    task.status = TaskStatus.completed;
    task.completedAt = DateTime.now();
    _clearNavigation();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliverySuccessScreen(task: task),
      ),
    );
  }

  // ★ Supervisor views path for a specific employee's task
  void _viewEmployeeTask(WarehouseTask task, Employee emp) {
    final targetFloor =
        floors.firstWhere((f) => f.floorNumber == task.targetFloorNumber);
    final targetZone = targetFloor.zones.cast<StorageZone?>().firstWhere(
        (z) => z!.label == task.targetZoneLabel,
        orElse: () => null);
    if (targetZone == null) return;

    task.status = TaskStatus.inProgress;

    // Use the EMPLOYEE's floor as source
    final result = PathfindingService.findCrossFloorPath(
      floors,
      emp.currentFloorNumber,
      targetZone,
      task.targetFloorNumber,
    );

    setState(() {
      _activeTask = task;
      _crossFloorResult = result;
      _activeStepIndex = 0;
    });

    if (result != null) {
      _navAnimController.repeat();
      _updateActiveFloorNav();
      if (result.segments.isNotEmpty) {
        final firstFloor = result.segments.first.floorNumber;
        if (firstFloor >= 0) {
          final idx =
              floors.indexWhere((f) => f.floorNumber == firstFloor);
          if (idx >= 0) _tabController.animateTo(idx);
        }
      }
    }
  }

  void _navigateToZoneOnFloor(StorageZone zone, int floorNumber) {
    final result = PathfindingService.findCrossFloorPath(
      floors,
      widget.currentEmployee.currentFloorNumber,
      zone,
      floorNumber,
    );
    setState(() {
      _crossFloorResult = result;
      _activeTask = null;
      _activeStepIndex = 0;
      selectedZoneId = zone.id;
    });
    if (result != null) {
      _navAnimController.repeat();
      _updateActiveFloorNav();
    }
  }

  void _goToStep(int stepIndex) {
    if (_crossFloorResult == null) return;
    final segment = _crossFloorResult!.segments[stepIndex];
    setState(() => _activeStepIndex = stepIndex);

    if (segment.floorNumber >= 0) {
      final idx =
          floors.indexWhere((f) => f.floorNumber == segment.floorNumber);
      if (idx >= 0) _tabController.animateTo(idx);
    } else if (segment.isElevatorTransition) {
      if (stepIndex + 1 < _crossFloorResult!.segments.length) {
        final nextSeg = _crossFloorResult!.segments[stepIndex + 1];
        if (nextSeg.floorNumber >= 0) {
          final idx = floors
              .indexWhere((f) => f.floorNumber == nextSeg.floorNumber);
          if (idx >= 0) _tabController.animateTo(idx);
        }
      }
    }
    _updateActiveFloorNav();
  }

  void _updateActiveFloorNav() {
    if (_crossFloorResult == null) {
      setState(() => _activeFloorNav = null);
      return;
    }
    NavigationResult? nav;
    for (var seg in _crossFloorResult!.segments) {
      if (seg.floorNumber == currentFloor.floorNumber &&
          seg.path.isNotEmpty) {
        nav = NavigationResult(
          path: seg.path,
          targetZone: _crossFloorResult!.targetZone,
          entryPoint: PathPoint(seg.path.first.x, seg.path.first.y),
          totalDistanceM: seg.distanceM,
        );
        break;
      }
    }
    setState(() => _activeFloorNav = nav);
  }

  // ★ Build employee markers — always show dots, paths only for selected
  List<EmployeeMarker> _buildEmployeeMarkers() {
    final markers = <EmployeeMarker>[];

    if (_isEmployee) {
      // Employee sees only themselves on the map
      final me = widget.currentEmployee;
      if (me.currentFloorNumber == currentFloor.floorNumber) {
        markers.add(EmployeeMarker(
          name: me.name,
          color: me.color,
          positionX: me.positionX,
          positionY: me.positionY,
          isSelected: true,
        ));
      }
    } else {
      // Supervisor/Admin: show ALL employees on this floor
      for (var emp in _employees) {
        if (emp.currentFloorNumber != currentFloor.floorNumber) continue;

        final isSelected = _selectedEmployeeView?.id == emp.id;
        List<PathPoint>? path;

        // Only compute path for the SELECTED employee
        if (isSelected) {
          final empTasks = tasks
              .where((t) =>
                  t.assignedEmployeeId == emp.id &&
                  t.status == TaskStatus.inProgress)
              .toList();
          if (empTasks.isNotEmpty) {
            final task = empTasks.first;
            if (task.targetFloorNumber == currentFloor.floorNumber) {
              final targetZone = currentFloor.zones
                  .cast<StorageZone?>()
                  .firstWhere(
                      (z) => z!.label == task.targetZoneLabel,
                      orElse: () => null);
              if (targetZone != null) {
                final result =
                    PathfindingService.findPath(currentFloor, targetZone);
                path = result?.path;
              }
            }
          }
        }

        markers.add(EmployeeMarker(
          name: emp.name,
          color: emp.color,
          positionX: emp.positionX,
          positionY: emp.positionY,
          activePath: path,
          isSelected: isSelected,
        ));
      }
    }
    return markers;
  }

  // ★ Select/deselect an employee
  void _selectEmployee(Employee? emp) {
    setState(() {
      if (emp == null || _selectedEmployeeView?.id == emp.id) {
        _selectedEmployeeView = null;
        _clearNavigation();
      } else {
        _selectedEmployeeView = emp;
        // Auto-switch to employee's floor
        final idx = floors
            .indexWhere((f) => f.floorNumber == emp.currentFloorNumber);
        if (idx >= 0 && idx != selectedFloorIndex) {
          _tabController.animateTo(idx);
        }
        _navAnimController.repeat();
      }
    });
  }

  void _clearNavigation() {
    _navAnimController.stop();
    _navAnimController.reset();
    setState(() {
      _crossFloorResult = null;
      _activeFloorNav = null;
      _activeTask = null;
      _activeStepIndex = 0;
    });
  }

  void _onMouseMove(Offset pos, BoxConstraints constraints) {
    final s = _getScale(constraints);
    setState(() {
      _mouseX =
          (pos.dx / s).clamp(0.0, currentFloor.totalWidthM).toDouble();
      _mouseY =
          (pos.dy / s).clamp(0.0, currentFloor.totalHeightM).toDouble();
      if (_placementMode) _cursorPos = pos;
    });
  }

  void _onMapTap(Offset pos, BoxConstraints constraints) {
    final s = _getScale(constraints);
    final tapX =
        (pos.dx / s).clamp(0.0, currentFloor.totalWidthM).toDouble();
    final tapY =
        (pos.dy / s).clamp(0.0, currentFloor.totalHeightM).toDouble();

    if (_placementMode) {
      _showAddZoneDialog(tapX: tapX, tapY: tapY);
      return;
    }

    // ★ Check employee dot tap (supervisor/admin)
    if (!_isEmployee) {
      for (var emp in _employees) {
        if (emp.currentFloorNumber != currentFloor.floorNumber) continue;
        final dx = tapX - emp.positionX;
        final dy = tapY - emp.positionY;
        if (dx * dx + dy * dy < 4.0) {
          // within ~2m radius
          _selectEmployee(
              _selectedEmployeeView?.id == emp.id ? null : emp);
          return;
        }
      }
    }

    // Check zone tap
    StorageZone? found;
    for (var zone in currentFloor.zones) {
      if (tapX >= zone.x &&
          tapX <= zone.x + zone.widthM &&
          tapY >= zone.y &&
          tapY <= zone.y + zone.heightM) {
        found = zone;
        break;
      }
    }
    if (found != null) {
      setState(() => selectedZoneId = found!.id);
      _navigateToZoneOnFloor(found, currentFloor.floorNumber);
    }
  }

  double _getScale(BoxConstraints constraints) {
    final w = constraints.maxWidth - 20;
    final h = constraints.maxHeight - 16;
    final sx = w / currentFloor.totalWidthM;
    final sy = h / currentFloor.totalHeightM;
    return sx < sy ? sx : sy;
  }

  void _zoom(double factor) {
    final cur = _transformController.value.getMaxScaleOnAxis();
    final ns = (cur * factor).clamp(0.3, 8.0);
    _transformController.value = Matrix4.diagonal3Values(ns, ns, 1.0);
  }

  Future<void> _showFloorSettingsDialog() async {
    final widthCtrl = TextEditingController(
        text: currentFloor.totalWidthM.toStringAsFixed(1));
    final heightCtrl = TextEditingController(
        text: currentFloor.totalHeightM.toStringAsFixed(1));
    final nameCtrl = TextEditingController(text: currentFloor.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.straighten, color: Color(0xFF1A237E)),
          SizedBox(width: 8),
          Text('Surface de l\'étage'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Nom', prefixIcon: Icon(Icons.label)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: widthCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Largeur (m)',
                    prefixIcon: Icon(Icons.swap_horiz)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('×', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: TextField(
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Profondeur (m)',
                    prefixIcon: Icon(Icons.swap_vert)),
              ),
            ),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        currentFloor.name = nameCtrl.text;
        currentFloor.totalWidthM =
            double.tryParse(widthCtrl.text) ?? currentFloor.totalWidthM;
        currentFloor.totalHeightM =
            double.tryParse(heightCtrl.text) ?? currentFloor.totalHeightM;
        _clearNavigation();
      });
    }
  }

  Future<void> _showAddZoneDialog({double? tapX, double? tapY}) async {
    final result = await showDialog(
      context: context,
      builder: (_) =>
          ZoneFormDialog(floor: currentFloor, tapX: tapX, tapY: tapY),
    );
    if (result is StorageZone) {
      setState(() {
        currentFloor.addZone(result);
        selectedZoneId = result.id;
        _placementMode = false;
        _cursorPos = null;
      });
    }
  }

  Future<void> _showEditZoneDialog(StorageZone zone) async {
    final result = await showDialog(
      context: context,
      builder: (_) =>
          ZoneFormDialog(floor: currentFloor, existingZone: zone),
    );
    if (result == 'DELETE') {
      _confirmDelete(zone);
    } else if (result is StorageZone) {
      setState(() {
        currentFloor.updateZone(zone.id, result);
        selectedZoneId = result.id;
      });
    }
  }

  void _confirmDelete(StorageZone zone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Supprimer la zone ?'),
        ]),
        content: Text(
            'Supprimer "${zone.label}" (${zone.areaM2.toStringAsFixed(1)}m²) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                currentFloor.removeZone(zone.id);
                if (selectedZoneId == zone.id) selectedZoneId = null;
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════ HELPER WIDGETS ═══════════════════

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ZoomBtn(this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF37474F)),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: color)),
        ]),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _AreaChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: color)),
        ]),
      ),
    );
  }
}
