import 'dart:math';
import '../models/warehouse_data.dart';

// ═══════════════════════════════════════════════════════════════
//  Pathfinding Service — A* based navigation for warehouse maps
// ═══════════════════════════════════════════════════════════════

class PathPoint {
  final double x;
  final double y;

  const PathPoint(this.x, this.y);

  @override
  String toString() => 'PathPoint($x, $y)';
}

class NavigationResult {
  final List<PathPoint> path;
  final StorageZone targetZone;
  final PathPoint entryPoint;
  final double totalDistanceM;

  NavigationResult({
    required this.path,
    required this.targetZone,
    required this.entryPoint,
    required this.totalDistanceM,
  });
}

class CrossFloorSegment {
  final int floorNumber;
  final List<PathPoint> path;
  final bool isElevatorTransition;
  final double distanceM;
  final String instruction;

  CrossFloorSegment({
    required this.floorNumber,
    required this.path,
    this.isElevatorTransition = false,
    required this.distanceM,
    required this.instruction,
  });
}

class CrossFloorResult {
  final List<CrossFloorSegment> segments;
  final StorageZone targetZone;
  final int sourceFloor;
  final int targetFloor;
  final double totalDistanceM;
  final bool isCrossFloor;

  CrossFloorResult({
    required this.segments,
    required this.targetZone,
    required this.sourceFloor,
    required this.targetFloor,
    required this.totalDistanceM,
    required this.isCrossFloor,
  });
}

// ═══════════════════════════════════════════════════════════════
//  A* Pathfinding on a grid derived from warehouse zones
// ═══════════════════════════════════════════════════════════════

class PathfindingService {
  /// Find a path on a single floor to the target zone.
  static NavigationResult? findPath(WarehouseFloor floor, StorageZone target) {
    // Build a walkable grid from the floor
    final gridW = floor.totalWidthM.ceil();
    final gridH = floor.totalHeightM.ceil();
    if (gridW <= 0 || gridH <= 0) return null;

    final blocked = List.generate(gridH, (_) => List.filled(gridW, false));

    // Mark zone interiors as blocked (except aisles and target zone)
    for (final zone in floor.zones) {
      if (zone.id == target.id) continue;
      if (zone.type == ZoneType.aisle) continue;
      final x0 = zone.x.floor().clamp(0, gridW - 1);
      final y0 = zone.y.floor().clamp(0, gridH - 1);
      final x1 = (zone.x + zone.widthM).ceil().clamp(0, gridW);
      final y1 = (zone.y + zone.heightM).ceil().clamp(0, gridH);
      for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
          blocked[y][x] = true;
        }
      }
    }

    // Start point: center of floor entrance (or 0,0)
    final startX = (gridW ~/ 2).clamp(0, gridW - 1);
    final startY = 0;
    // End point: front-center of target zone
    final endX = (target.x + target.widthM / 2).floor().clamp(0, gridW - 1);
    final endY = target.y.floor().clamp(0, gridH - 1);

    final path = _astar(blocked, gridW, gridH, startX, startY, endX, endY);
    if (path == null || path.isEmpty) {
      // Fallback: straight line
      final fallback = [PathPoint(startX.toDouble(), startY.toDouble()), PathPoint(endX.toDouble(), endY.toDouble())];
      final dist = sqrt(pow(endX - startX, 2) + pow(endY - startY, 2));
      return NavigationResult(
        path: fallback,
        targetZone: target,
        entryPoint: fallback.first,
        totalDistanceM: dist,
      );
    }

    double dist = 0;
    for (int i = 1; i < path.length; i++) {
      dist += sqrt(pow(path[i].x - path[i - 1].x, 2) + pow(path[i].y - path[i - 1].y, 2));
    }

    return NavigationResult(
      path: path,
      targetZone: target,
      entryPoint: path.first,
      totalDistanceM: dist,
    );
  }

  /// Find a cross-floor path (may include elevator transitions).
  static CrossFloorResult? findCrossFloorPath(
    List<WarehouseFloor> floors,
    int sourceFloorNumber,
    StorageZone targetZone,
    int targetFloorNumber,
  ) {
    final segments = <CrossFloorSegment>[];

    if (sourceFloorNumber == targetFloorNumber) {
      // Same floor navigation
      final floor = floors.firstWhere((f) => f.floorNumber == targetFloorNumber,
          orElse: () => floors.first);
      final nav = findPath(floor, targetZone);
      if (nav == null) return null;

      segments.add(CrossFloorSegment(
        floorNumber: targetFloorNumber,
        path: nav.path,
        distanceM: nav.totalDistanceM,
        instruction: 'Navigate to ${targetZone.label}',
      ));

      return CrossFloorResult(
        segments: segments,
        targetZone: targetZone,
        sourceFloor: sourceFloorNumber,
        targetFloor: targetFloorNumber,
        totalDistanceM: nav.totalDistanceM,
        isCrossFloor: false,
      );
    }

    // Cross-floor: source floor → elevator → target floor → zone
    final sourceFloor = floors.cast<WarehouseFloor?>().firstWhere(
        (f) => f!.floorNumber == sourceFloorNumber,
        orElse: () => null);
    final destFloor = floors.cast<WarehouseFloor?>().firstWhere(
        (f) => f!.floorNumber == targetFloorNumber,
        orElse: () => null);

    if (sourceFloor == null || destFloor == null) return null;

    // Find elevator/freight lift zone on source floor
    StorageZone? sourceElevator;
    for (final z in sourceFloor.zones) {
      if (z.type == ZoneType.elevator ||
          z.type == ZoneType.freightLift ||
          z.type == ZoneType.freightElevator) {
        sourceElevator = z;
        break;
      }
    }

    double totalDist = 0;

    // Segment 1: walk to elevator on source floor
    if (sourceElevator != null) {
      final navToElevator = findPath(sourceFloor, sourceElevator);
      final elevPath = navToElevator?.path ?? [
        PathPoint(sourceFloor.totalWidthM / 2, 0),
        PathPoint(sourceElevator.x + sourceElevator.widthM / 2,
            sourceElevator.y + sourceElevator.heightM / 2),
      ];
      final dist = navToElevator?.totalDistanceM ?? 5.0;
      totalDist += dist;

      segments.add(CrossFloorSegment(
        floorNumber: sourceFloorNumber,
        path: elevPath,
        distanceM: dist,
        instruction: 'Walk to elevator on ${_floorLabel(sourceFloorNumber)}',
      ));
    }

    // Segment 2: elevator transition
    segments.add(CrossFloorSegment(
      floorNumber: -1,
      path: [],
      isElevatorTransition: true,
      distanceM: 0,
      instruction: 'Take elevator to ${_floorLabel(targetFloorNumber)}',
    ));

    // Segment 3: walk from elevator to target on destination floor
    final navToTarget = findPath(destFloor, targetZone);
    final targetPath = navToTarget?.path ?? [
      PathPoint(destFloor.totalWidthM / 2, 0),
      PathPoint(targetZone.x + targetZone.widthM / 2,
          targetZone.y + targetZone.heightM / 2),
    ];
    final targetDist = navToTarget?.totalDistanceM ?? 8.0;
    totalDist += targetDist;

    segments.add(CrossFloorSegment(
      floorNumber: targetFloorNumber,
      path: targetPath,
      distanceM: targetDist,
      instruction: 'Navigate to ${targetZone.label} on ${_floorLabel(targetFloorNumber)}',
    ));

    return CrossFloorResult(
      segments: segments,
      targetZone: targetZone,
      sourceFloor: sourceFloorNumber,
      targetFloor: targetFloorNumber,
      totalDistanceM: totalDist,
      isCrossFloor: true,
    );
  }

  static String _floorLabel(int n) {
    if (n == 0) return 'Ground Floor';
    if (n < 0) return 'Basement ${n.abs()}';
    return 'Floor $n';
  }

  // ── A* implementation ──

  static List<PathPoint>? _astar(
    List<List<bool>> blocked,
    int w,
    int h,
    int sx,
    int sy,
    int ex,
    int ey,
  ) {
    if (sx == ex && sy == ey) return [PathPoint(sx.toDouble(), sy.toDouble())];

    final open = <_Node>[];
    final closed = <int>{};
    final cameFrom = <int, int>{};
    final gScore = <int, double>{};

    int key(int x, int y) => y * w + x;
    double heuristic(int x, int y) => sqrt(pow(x - ex, 2) + pow(y - ey, 2));

    final startKey = key(sx, sy);
    gScore[startKey] = 0;
    open.add(_Node(sx, sy, heuristic(sx, sy)));

    const dirs = [
      [0, -1], [0, 1], [-1, 0], [1, 0],
      [-1, -1], [-1, 1], [1, -1], [1, 1],
    ];

    while (open.isNotEmpty) {
      open.sort((a, b) => a.f.compareTo(b.f));
      final current = open.removeAt(0);
      final ck = key(current.x, current.y);

      if (current.x == ex && current.y == ey) {
        // Reconstruct path
        final path = <PathPoint>[];
        int? k = ck;
        while (k != null) {
          path.add(PathPoint((k % w).toDouble(), (k ~/ w).toDouble()));
          k = cameFrom[k];
        }
        return path.reversed.toList();
      }

      if (closed.contains(ck)) continue;
      closed.add(ck);

      for (final d in dirs) {
        final nx = current.x + d[0];
        final ny = current.y + d[1];
        if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
        final nk = key(nx, ny);
        if (closed.contains(nk)) continue;

        // Allow walking on blocked cells if it's the destination
        if (blocked[ny][nx] && !(nx == ex && ny == ey)) continue;

        final isDiag = d[0] != 0 && d[1] != 0;
        final tentG = (gScore[ck] ?? double.infinity) + (isDiag ? 1.414 : 1.0);

        if (tentG < (gScore[nk] ?? double.infinity)) {
          gScore[nk] = tentG;
          cameFrom[nk] = ck;
          open.add(_Node(nx, ny, tentG + heuristic(nx, ny)));
        }
      }
    }

    return null; // No path found
  }
}

class _Node {
  final int x, y;
  final double f;
  _Node(this.x, this.y, this.f);
}
