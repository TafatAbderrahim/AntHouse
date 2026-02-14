import 'dart:math';
import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/mobai_models.dart';

// ═══════════════════════════════════════════════════════════════
//  OPERATIONS — Full warehouse map with workers displayed on it.
//  Tap a worker dot to see their info card + path.
// ═══════════════════════════════════════════════════════════════

class OperationsOverviewScreen extends StatefulWidget {
  const OperationsOverviewScreen({super.key});

  @override
  State<OperationsOverviewScreen> createState() =>
      _OperationsOverviewScreenState();
}

class _OperationsOverviewScreenState extends State<OperationsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final List<_WorkerInfo> _workers;
  late AnimationController _pulseCtrl;
  _WorkerInfo? _selected;

  @override
  void initState() {
    super.initState();
    final tasks = MobAiMock.generateTasks();
    _workers = _MockWorkers.generate(tasks);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Hit-test: find worker near tap ──
  _WorkerInfo? _hitTest(Offset tapLocal, Size mapSize) {
    const hitRadius = 22.0;
    for (final w in _workers.reversed) {
      final wx = w.mapPosition.dx * mapSize.width;
      final wy = w.mapPosition.dy * mapSize.height;
      if ((tapLocal - Offset(wx, wy)).distance <= hitRadius) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header bar ──
          _buildHeader(),
          // ── Map + overlay ──
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (ctx, box) {
                  final mapSize = Size(box.maxWidth, box.maxHeight);
                  return Stack(
                    children: [
                      // ── THE MAP ── (tap to select / deselect)
                      GestureDetector(
                        onTapUp: (details) {
                          final hit =
                              _hitTest(details.localPosition, mapSize);
                          setState(() =>
                              _selected = hit?.id == _selected?.id ? null : hit);
                        },
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => CustomPaint(
                            painter: _WarehouseMapPainter(
                              workers: _workers,
                              selectedId: _selected?.id,
                              pulse: _pulseCtrl.value,
                            ),
                            size: mapSize,
                          ),
                        ),
                      ),

                      // ── Worker info card overlay ──
                      if (_selected != null)
                        _buildInfoCard(_selected!, mapSize),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════

  Widget _buildHeader() {
    final active = _workers.where((w) => w.status == 'active').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warehouse_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'B7 Warehouse — Live Operations',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          // Worker count + legend (scrollable on narrow screens)
          Flexible(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _miniStat(Icons.people, '$active/${_workers.length}', AppColors.success),
              const SizedBox(width: 12),
              // Legend dots
              _legendDot('Supv', AppColors.aiBlue),
              const SizedBox(width: 8),
              _legendDot('Emp', const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              _legendDot('Oper', AppColors.accent),
              const SizedBox(width: 12),
              // LIVE badge
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withValues(alpha: 0.06 + _pulseCtrl.value * 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.5 + _pulseCtrl.value * 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          )),
                    ],
                  ),
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
      ],
    );
  }

  // ═══════════════════ INFO CARD OVERLAY ═══════════════════

  Widget _buildInfoCard(_WorkerInfo w, Size mapSize) {
    // Position card near the worker but keep it on screen
    final wx = w.mapPosition.dx * mapSize.width;
    final wy = w.mapPosition.dy * mapSize.height;
    const cardW = 280.0;
    const cardH = 195.0;
    // Prefer right side of worker; flip left if too close to edge
    double left = wx + 25;
    if (left + cardW > mapSize.width - 12) left = wx - cardW - 25;
    left = left.clamp(8.0, mapSize.width - cardW - 8);
    double top = wy - cardH / 2;
    top = top.clamp(8.0, mapSize.height - cardH - 8);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: cardW,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: w.color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: w.color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header ──
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.06),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: w.color,
                      child: Text(w.name[0],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(w.role.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: w.color,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: w.status == 'active'
                            ? AppColors.success.withValues(alpha: 0.12)
                            : w.status == 'idle'
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : AppColors.archived.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: w.status == 'active'
                                  ? AppColors.success
                                  : w.status == 'idle'
                                      ? AppColors.accent
                                      : AppColors.archived,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            w.status[0].toUpperCase() + w.status.substring(1),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: w.status == 'active'
                                  ? AppColors.success
                                  : w.status == 'idle'
                                      ? AppColors.accent
                                      : AppColors.archived,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selected = null),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: AppColors.textLight),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Location ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: w.color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(w.currentLocation,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),

              // ── Current task ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
                child: w.currentTask != null
                    ? Row(
                        children: [
                          Icon(_opIcon(w.currentTask!.operation),
                              size: 14, color: w.currentTask!.statusColor),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${MobAiMock.operationLabel(w.currentTask!.operation)}: ${w.currentTask!.orderRef}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: w.currentTask!.statusColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        w.status == 'offline'
                            ? '⊘ Offline'
                            : '— No task assigned',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic),
                      ),
              ),

              // ── Path breadcrumb ──
              if (w.pathSteps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: SizedBox(
                    height: 24,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: w.pathSteps.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(Icons.chevron_right,
                            size: 12, color: w.color.withValues(alpha: 0.4)),
                      ),
                      itemBuilder: (_, j) {
                        final isCurrent = j == w.currentPathIndex;
                        final isPast = j < w.currentPathIndex;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? w.color.withValues(alpha: 0.12)
                                : isPast
                                    ? AppColors.success.withValues(alpha: 0.08)
                                    : AppColors.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: isCurrent
                                ? Border.all(color: w.color, width: 1)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPast)
                                const Padding(
                                  padding: EdgeInsets.only(right: 3),
                                  child: Icon(Icons.check_circle,
                                      size: 10, color: AppColors.success),
                                ),
                              if (isCurrent)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(Icons.radio_button_checked,
                                      size: 10, color: w.color),
                                ),
                              Text(
                                w.pathSteps[j],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? w.color
                                      : isPast
                                          ? AppColors.success
                                          : AppColors.textMid,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  IconData _opIcon(OperationType op) {
    return switch (op) {
      OperationType.receipt => Icons.call_received_rounded,
      OperationType.transfer => Icons.swap_horiz_rounded,
      OperationType.preparation => Icons.assignment_rounded,
      OperationType.picking => Icons.shopping_basket_rounded,
      OperationType.delivery => Icons.local_shipping_rounded,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
//  WORKER DATA MODEL
// ═══════════════════════════════════════════════════════════════

class _WorkerInfo {
  final String id;
  final String name;
  final String role;
  final Color color;
  final String currentLocation;
  final String status;
  final ValidationTask? currentTask;
  final List<String> pathSteps;
  final int currentPathIndex;
  final List<Offset> mapPath;

  Offset get mapPosition => mapPath.isNotEmpty
      ? mapPath[currentPathIndex.clamp(0, mapPath.length - 1)]
      : const Offset(0.5, 0.5);

  _WorkerInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.color,
    required this.currentLocation,
    required this.status,
    this.currentTask,
    required this.pathSteps,
    required this.currentPathIndex,
    required this.mapPath,
  });
}

class _MockWorkers {
  static List<_WorkerInfo> generate(List<ValidationTask> tasks) {
    return [
      _WorkerInfo(
        id: 'w1',
        name: 'A. Benali',
        role: 'supervisor',
        color: const Color(0xFF2196F3),
        currentLocation: 'B7-0A (Supervision Zone)',
        status: 'active',
        currentTask: null,
        pathSteps: ['Office', 'B7-0A', 'B7-0B', 'Expedition'],
        currentPathIndex: 1,
        mapPath: [
          const Offset(0.88, 0.10),
          const Offset(0.36, 0.34),
          const Offset(0.45, 0.44),
          const Offset(0.12, 0.82),
        ],
      ),
      _WorkerInfo(
        id: 'w2',
        name: 'K. Medjani',
        role: 'employee',
        color: const Color(0xFF4CAF50),
        currentLocation: 'B7-0B-01-02',
        status: 'active',
        currentTask: tasks.isNotEmpty ? tasks[0] : null,
        pathSteps: ['RECEIVING', 'B7-N1-C7', 'B7-0B-01-02'],
        currentPathIndex: 2,
        mapPath: [
          const Offset(0.12, 0.14),
          const Offset(0.35, 0.22),
          const Offset(0.40, 0.44),
        ],
      ),
      _WorkerInfo(
        id: 'w3',
        name: 'S. Hamdi',
        role: 'employee',
        color: const Color(0xFFFF9800),
        currentLocation: 'B7-0C-01-01',
        status: 'active',
        currentTask: tasks.length > 1 ? tasks[1] : null,
        pathSteps: ['B7-N2-C3', 'ELEVATOR', 'B7-0C-01-01'],
        currentPathIndex: 2,
        mapPath: [
          const Offset(0.50, 0.18),
          const Offset(0.50, 0.07),
          const Offset(0.55, 0.55),
        ],
      ),
      _WorkerInfo(
        id: 'w4',
        name: 'M. Boudia',
        role: 'employee',
        color: const Color(0xFF9C27B0),
        currentLocation: 'B7-0D-01-01',
        status: 'active',
        currentTask: tasks.length > 3 ? tasks[3] : null,
        pathSteps: ['B7-N3-D8', 'ELEVATOR', 'B7-0D-01-01', 'B7-0B-01-01'],
        currentPathIndex: 2,
        mapPath: [
          const Offset(0.60, 0.18),
          const Offset(0.50, 0.07),
          const Offset(0.65, 0.65),
          const Offset(0.45, 0.44),
        ],
      ),
      _WorkerInfo(
        id: 'w5',
        name: 'R. Talbi',
        role: 'supervisor',
        color: const Color(0xFFE91E63),
        currentLocation: 'Bureau (Office)',
        status: 'active',
        currentTask: null,
        pathSteps: ['Bureau'],
        currentPathIndex: 0,
        mapPath: [const Offset(0.88, 0.12)],
      ),
      _WorkerInfo(
        id: 'w6',
        name: 'N. Ferhat',
        role: 'employee',
        color: const Color(0xFF00BCD4),
        currentLocation: 'Zone Expédition',
        status: 'active',
        currentTask: tasks.length > 4 ? tasks[4] : null,
        pathSteps: ['B7-0B-01-01', 'B7-0E', 'Zone Expédition'],
        currentPathIndex: 2,
        mapPath: [
          const Offset(0.45, 0.44),
          const Offset(0.35, 0.75),
          const Offset(0.12, 0.83),
        ],
      ),
      _WorkerInfo(
        id: 'w7',
        name: 'Y. Charef',
        role: 'employee',
        color: const Color(0xFF795548),
        currentLocation: 'B7-N1-C2 (Storage)',
        status: 'idle',
        currentTask: null,
        pathSteps: [],
        currentPathIndex: 0,
        mapPath: [const Offset(0.48, 0.20)],
      ),
      _WorkerInfo(
        id: 'w8',
        name: 'L. Amrani',
        role: 'employee',
        color: const Color(0xFF607D8B),
        currentLocation: 'Offline',
        status: 'offline',
        currentTask: null,
        pathSteps: [],
        currentPathIndex: 0,
        mapPath: [const Offset(0.92, 0.90)],
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════
//  WAREHOUSE MAP PAINTER
// ═══════════════════════════════════════════════════════════════

class _WarehouseMapPainter extends CustomPainter {
  final List<_WorkerInfo> workers;
  final String? selectedId;
  final double pulse;

  _WarehouseMapPainter({
    required this.workers,
    this.selectedId,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    _drawZones(canvas, size);
    _drawRackRows(canvas, size);
    _drawPaths(canvas, size);
    _drawWorkers(canvas, size);
    _drawLabels(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8FAFB),
        const Color(0xFFEFF3F6),
        const Color(0xFFE8EEF2),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = grad.createShader(rect));
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE2E8ED)
      ..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawZones(Canvas canvas, Size size) {
    _zone(canvas, size, 0.02, 0.72, 0.24, 0.96,
        const Color(0xFFE8F5E9), const Color(0xFF4CAF50));
    _zone(canvas, size, 0.80, 0.02, 0.98, 0.22,
        const Color(0xFFFFF8E1), const Color(0xFFFFC107));
    _zone(canvas, size, 0.02, 0.02, 0.24, 0.26,
        const Color(0xFFE3F2FD), const Color(0xFF2196F3));
    _zone(canvas, size, 0.44, 0.01, 0.56, 0.13,
        const Color(0xFFEDE7F6), const Color(0xFF9C27B0));
    // Main aisle
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.25, size.height * 0.28,
          size.width * 0.78, size.height * 0.30),
      Paint()..color = const Color(0xFFE0E0E0).withValues(alpha: 0.3),
    );
  }

  void _zone(Canvas canvas, Size size, double l, double t, double r,
      double b, Color fill, Color stroke) {
    final rr = RRect.fromLTRBR(
        size.width * l, size.height * t, size.width * r, size.height * b,
        const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawRackRows(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFD5DDE3);
    final border = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final div = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 6; i++) {
      final y = size.height * (0.31 + i * 0.105);
      final rr = RRect.fromLTRBR(
          size.width * 0.27, y, size.width * 0.77,
          y + size.height * 0.065, const Radius.circular(4));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, border);
      final sw = (size.width * 0.50) / 10;
      for (int s = 1; s < 10; s++) {
        final sx = size.width * 0.27 + s * sw;
        canvas.drawLine(
            Offset(sx, y + 2), Offset(sx, y + size.height * 0.065 - 2), div);
      }
    }
  }

  // ── Draw paths (only selected worker's path is highlighted) ──
  void _drawPaths(Canvas canvas, Size size) {
    // Faded paths for non-selected
    for (final w in workers) {
      if (w.id == selectedId || w.mapPath.length < 2 || w.status == 'offline') {
        continue;
      }
      _drawPath(canvas, size, w, false);
    }
    // Bold path for selected
    if (selectedId != null) {
      final sel = workers.where((w) => w.id == selectedId).firstOrNull;
      if (sel != null && sel.mapPath.length >= 2 && sel.status != 'offline') {
        _drawPath(canvas, size, sel, true);
      }
    }
  }

  void _drawPath(Canvas canvas, Size size, _WorkerInfo w, bool selected) {
    final pts =
        w.mapPath.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    // Completed segments → solid
    for (int i = 0; i < w.currentPathIndex && i < pts.length - 1; i++) {
      canvas.drawLine(
          pts[i],
          pts[i + 1],
          Paint()
            ..color = selected
                ? w.color.withValues(alpha: 0.8)
                : w.color.withValues(alpha: 0.12)
            ..strokeWidth = selected ? 4 : 1.5
            ..strokeCap = StrokeCap.round);
      if (selected) {
        canvas.drawCircle(pts[i], 5, Paint()..color = Colors.white);
        canvas.drawCircle(pts[i], 4, Paint()..color = w.color.withValues(alpha: 0.5));
        canvas.drawCircle(
            pts[i],
            5,
            Paint()
              ..color = w.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
    // Future segments → dashed
    for (int i = w.currentPathIndex; i < pts.length - 1; i++) {
      _dash(
          canvas,
          pts[i],
          pts[i + 1],
          Paint()
            ..color = selected
                ? w.color.withValues(alpha: 0.35)
                : w.color.withValues(alpha: 0.06)
            ..strokeWidth = selected ? 3 : 1
            ..strokeCap = StrokeCap.round);
      if (selected && i + 1 < pts.length) {
        canvas.drawCircle(pts[i + 1], 5, Paint()..color = Colors.white);
        canvas.drawCircle(
            pts[i + 1],
            5,
            Paint()
              ..color = w.color.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
    // Arrow heads for selected
    if (selected) {
      for (int i = 0; i < pts.length - 1; i++) {
        _arrow(canvas, pts[i], pts[i + 1],
            w.color.withValues(alpha: i < w.currentPathIndex ? 0.7 : 0.3));
      }
    }
  }

  void _dash(Canvas c, Offset a, Offset b, Paint p,
      {double on = 8, double off = 5}) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = dx / len, ny = dy / len;
    double d = 0;
    while (d < len) {
      c.drawLine(
          Offset(a.dx + nx * d, a.dy + ny * d),
          Offset(a.dx + nx * min(d + on, len), a.dy + ny * min(d + on, len)),
          p);
      d += on + off;
    }
  }

  void _arrow(Canvas c, Offset from, Offset to, Color color) {
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 30) return;
    final mid = Offset(from.dx + dx * 0.55, from.dy + dy * 0.55);
    final a = atan2(dy, dx);
    const s = 9.0, ha = 0.5;
    c.drawPath(
        Path()
          ..moveTo(mid.dx, mid.dy)
          ..lineTo(mid.dx - cos(a - ha) * s, mid.dy - sin(a - ha) * s)
          ..lineTo(mid.dx - cos(a + ha) * s, mid.dy - sin(a + ha) * s)
          ..close(),
        Paint()..color = color);
  }

  // ── Draw worker dots ──
  void _drawWorkers(Canvas canvas, Size size) {
    final sorted = [...workers]..sort((a, b) {
        if (a.id == selectedId) return 1;
        if (b.id == selectedId) return -1;
        return 0;
      });

    for (final w in sorted) {
      final x = w.mapPosition.dx * size.width;
      final y = w.mapPosition.dy * size.height;
      final sel = w.id == selectedId;

      // Pulse ring
      if (sel && w.status == 'active') {
        final pr = 22 + pulse * 16;
        canvas.drawCircle(Offset(x, y), pr,
            Paint()..color = w.color.withValues(alpha: 0.1 * (1 - pulse)));
        canvas.drawCircle(
            Offset(x, y),
            pr,
            Paint()
              ..color = w.color.withValues(alpha: 0.2 * (1 - pulse))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }

      // Glow
      if (sel) {
        canvas.drawCircle(
            Offset(x, y), 22, Paint()..color = w.color.withValues(alpha: 0.12));
      }

      // Shadow
      canvas.drawCircle(Offset(x + 1, y + 2), sel ? 16 : 12,
          Paint()..color = Colors.black.withValues(alpha: 0.08));

      // Outer white ring
      final r = sel ? 16.0 : 12.0;
      canvas.drawCircle(Offset(x, y), r, Paint()..color = Colors.white);

      // Colored fill
      canvas.drawCircle(
          Offset(x, y),
          r - 2.5,
          Paint()
            ..color =
                w.status == 'offline' ? const Color(0xFF9E9E9E) : w.color);

      // Initial
      final tp = TextPainter(
        text: TextSpan(
            text: w.name[0],
            style: TextStyle(
                fontSize: sel ? 13 : 10,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));

      // Active green dot
      if (w.status == 'active') {
        canvas.drawCircle(Offset(x + r * 0.6, y - r * 0.6), 4.5,
            Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x + r * 0.6, y - r * 0.6), 3,
            Paint()..color = const Color(0xFF4CAF50));
      }

      // Name label
      if (w.status != 'offline') {
        final ntp = TextPainter(
          text: TextSpan(
              text: w.name,
              style: TextStyle(
                  fontSize: sel ? 11 : 8,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? w.color : const Color(0xFF546E7A))),
          textDirection: TextDirection.ltr,
        )..layout();
        final nr = RRect.fromLTRBR(
            x - ntp.width / 2 - 5, y + r + 3, x + ntp.width / 2 + 5,
            y + r + 3 + ntp.height + 5, const Radius.circular(4));
        canvas.drawRRect(
            nr, Paint()..color = Colors.white.withValues(alpha: 0.92));
        if (sel) {
          canvas.drawRRect(
              nr,
              Paint()
                ..color = w.color.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
        ntp.paint(canvas, Offset(x - ntp.width / 2, y + r + 5.5));
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    void lbl(String t, double nx, double ny, Color c,
        {double fs = 10, FontWeight fw = FontWeight.w700}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(fontSize: fs, fontWeight: fw, color: c)),
        textDirection: TextDirection.ltr,
      )..layout();
      final r = RRect.fromLTRBR(
          nx * size.width - 3, ny * size.height - 2,
          nx * size.width + tp.width + 3, ny * size.height + tp.height + 2,
          const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.8));
      tp.paint(canvas, Offset(nx * size.width, ny * size.height));
    }

    lbl('Expédition', 0.05, 0.74, const Color(0xFF388E3C));
    lbl('Bureau', 0.84, 0.05, const Color(0xFFF57F17));
    lbl('VRAC', 0.06, 0.05, const Color(0xFF1565C0));
    lbl('Ascenseur', 0.46, 0.04, const Color(0xFF7B1FA2));
    for (int i = 0; i < 6; i++) {
      lbl('Row 0${String.fromCharCode(65 + i)}', 0.78, 0.32 + i * 0.105,
          const Color(0xFF546E7A),
          fs: 8, fw: FontWeight.w600);
    }
  }

  @override
  bool shouldRepaint(covariant _WarehouseMapPainter old) => true;
}
