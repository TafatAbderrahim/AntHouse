import 'dart:ui';
import 'mobai_models.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum ZoneType {
  rack,
  rackStorage,
  floorStorage,
  bulk,
  shipping,
  receiving,
  office,
  elevator,
  freightLift,
  freightElevator,
  aisle,
  pillar,
  special,
  preparation,
}

enum ZoneStatus { empty, low, medium, high, full }

enum OccupancyLevel { empty, low, medium, high, full }

// ── Extensions ─────────────────────────────────────────────────────────────

extension ZoneTypeLabel on ZoneType {
  String get label {
    switch (this) {
      case ZoneType.rack:
      case ZoneType.rackStorage:
        return 'Rack';
      case ZoneType.floorStorage:
        return 'Stockage au sol';
      case ZoneType.bulk:
        return 'Vrac';
      case ZoneType.shipping:
        return 'Expédition';
      case ZoneType.receiving:
        return 'Réception';
      case ZoneType.office:
        return 'Bureau';
      case ZoneType.elevator:
        return 'Ascenseur';
      case ZoneType.freightLift:
      case ZoneType.freightElevator:
        return 'Monte-charge';
      case ZoneType.aisle:
        return 'Allée';
      case ZoneType.pillar:
        return 'Pilier';
      case ZoneType.special:
        return 'Spécial';
      case ZoneType.preparation:
        return 'Préparation';
    }
  }

  String get icon {
    switch (this) {
      case ZoneType.rack:
      case ZoneType.rackStorage:
        return '📦';
      case ZoneType.floorStorage:
        return '🏗️';
      case ZoneType.bulk:
        return '🪣';
      case ZoneType.shipping:
        return '🚚';
      case ZoneType.receiving:
        return '📥';
      case ZoneType.office:
        return '🏢';
      case ZoneType.elevator:
        return '🛗';
      case ZoneType.freightLift:
      case ZoneType.freightElevator:
        return '⬆️';
      case ZoneType.aisle:
        return '🚶';
      case ZoneType.pillar:
        return '🔲';
      case ZoneType.special:
        return '⭐';
      case ZoneType.preparation:
        return '📋';
    }
  }
}

extension ZoneTypeColor on ZoneType {
  Color get color {
    switch (this) {
      case ZoneType.rack:
      case ZoneType.rackStorage:
        return const Color(0xFFE0E0E0);
      case ZoneType.floorStorage:
        return const Color(0xFFD7CCC8);
      case ZoneType.bulk:
        return const Color(0xFFFFF9C4);
      case ZoneType.shipping:
        return const Color(0xFFBBDEFB);
      case ZoneType.receiving:
        return const Color(0xFFC8E6C9);
      case ZoneType.office:
        return const Color(0xFFD1C4E9);
      case ZoneType.elevator:
        return const Color(0xFFB0BEC5);
      case ZoneType.freightLift:
      case ZoneType.freightElevator:
        return const Color(0xFF90A4AE);
      case ZoneType.aisle:
        return const Color(0xFFF5F5F5);
      case ZoneType.pillar:
        return const Color(0xFF9E9E9E);
      case ZoneType.special:
        return const Color(0xFFFFCCBC);
      case ZoneType.preparation:
        return const Color(0xFFFFE0B2);
    }
  }
}

extension ZoneStatusInfo on ZoneStatus {
  Color get color {
    switch (this) {
      case ZoneStatus.empty:
        return const Color(0xFFE0E0E0);
      case ZoneStatus.low:
        return const Color(0xFF81C784);
      case ZoneStatus.medium:
        return const Color(0xFFFFD54F);
      case ZoneStatus.high:
        return const Color(0xFFFF8A65);
      case ZoneStatus.full:
        return const Color(0xFFE57373);
    }
  }

  String get label {
    switch (this) {
      case ZoneStatus.empty:
        return 'Vide';
      case ZoneStatus.low:
        return 'Faible';
      case ZoneStatus.medium:
        return 'Moyen';
      case ZoneStatus.high:
        return 'Élevé';
      case ZoneStatus.full:
        return 'Plein';
    }
  }
}

extension OccupancyColor on OccupancyLevel {
  Color get color {
    switch (this) {
      case OccupancyLevel.empty:
        return const Color(0xFFE0E0E0);
      case OccupancyLevel.low:
        return const Color(0xFF81C784);
      case OccupancyLevel.medium:
        return const Color(0xFFFFD54F);
      case OccupancyLevel.high:
        return const Color(0xFFFF8A65);
      case OccupancyLevel.full:
        return const Color(0xFFE57373);
    }
  }

  String get label {
    switch (this) {
      case OccupancyLevel.empty:
        return 'Vide';
      case OccupancyLevel.low:
        return 'Faible';
      case OccupancyLevel.medium:
        return 'Moyen';
      case OccupancyLevel.high:
        return 'Élevé';
      case OccupancyLevel.full:
        return 'Plein';
    }
  }
}

// ── Models ─────────────────────────────────────────────────────────────────

/// Primary zone model used across the codebase.
/// Aliased as both WarehouseZone and StorageZone for backward compatibility.
class StorageZone {
  final String id;
  String label;
  String section;
  String category;
  int pieceCount;
  final ZoneType type;
  final double x, y;
  double widthM, heightM;
  ZoneStatus status;
  double occupancyRate;
  final OccupancyLevel occupancy;
  int currentItems;
  int maxCapacity;
  String description;
  final DateTime createdAt;

  /// Number of rack levels (étages de racks).
  /// RDC picking racks have 3 levels; upper-floor palettes have 1.
  final int rackLevels;

  StorageZone({
    String? id,
    required this.label,
    this.section = '',
    this.category = 'General',
    this.pieceCount = 0,
    required this.type,
    required this.x,
    required this.y,
    required this.widthM,
    required this.heightM,
    this.status = ZoneStatus.empty,
    this.occupancyRate = 0.0,
    this.occupancy = OccupancyLevel.medium,
    this.currentItems = 0,
    this.maxCapacity = 100,
    this.description = '',
    this.rackLevels = 1,
    DateTime? createdAt,
  })  : id = id ?? '${label}_${x}_$y',
        createdAt = createdAt ?? DateTime.now();

  // Convenience getters
  double get width => widthM;
  double get height => heightM;
  double get areaM2 => widthM * heightM;

  /// Total physical rack slots = surface-based positions × rack levels.
  int get totalRacks => (areaM2 * 10).round() * rackLevels;

  /// Items that fit per single level.
  int get capacityPerLevel => (maxCapacity / rackLevels).round();
}

/// Backward-compatible alias
typedef WarehouseZone = StorageZone;

class WarehouseFloor {
  final String name;
  final int floorNumber;
  double totalWidthM;
  double totalHeightM;
  final List<StorageZone> zones;

  WarehouseFloor({
    required this.name,
    required this.floorNumber,
    double? width,
    double? height,
    double? totalWidthM,
    double? totalHeightM,
    List<StorageZone>? zones,
  })  : totalWidthM = totalWidthM ?? width ?? 44.0,
        totalHeightM = totalHeightM ?? height ?? 27.0,
        zones = zones ?? [];

  // Backward-compatible getters
  double get width => totalWidthM;
  double get height => totalHeightM;

  String get shortName {
    if (floorNumber == 0) return 'RDC';
    return '${floorNumber}e';
  }

  double get totalAreaM2 => totalWidthM * totalHeightM;

  double get usedAreaM2 {
    double sum = 0;
    for (final z in zones) {
      if (z.type != ZoneType.pillar && z.type != ZoneType.aisle) {
        sum += z.areaM2;
      }
    }
    return sum;
  }

  void addZone(StorageZone zone) => zones.add(zone);

  void removeZone(String id) => zones.removeWhere((z) => z.id == id);

  bool fitsInFloor(double x, double y, double w, double h) {
    return x >= 0 && y >= 0 && x + w <= totalWidthM && y + h <= totalHeightM;
  }

  bool hasOverlap(double x, double y, double w, double h, {String? excludeId}) {
    for (final z in zones) {
      if (excludeId != null && z.id == excludeId) continue;
      if (z.type == ZoneType.pillar || z.type == ZoneType.aisle) continue;
      if (x < z.x + z.widthM && x + w > z.x && y < z.y + z.heightM && y + h > z.y) {
        return true;
      }
    }
    return false;
  }

  int get totalZones =>
      zones.where((z) => z.type != ZoneType.pillar && z.type != ZoneType.aisle).length;

  int get occupiedZones =>
      zones.where((z) => z.type != ZoneType.pillar && z.type != ZoneType.aisle && z.occupancyRate > 0).length;

  int get freeZones => totalZones - occupiedZones;

  int get criticalZones =>
      zones.where((z) => z.occupancyRate > 0.85).length;

  double get freeAreaM2 => totalAreaM2 - usedAreaM2;
}

// ── Employee ──────────────────────────────────────────────────────────────

class Employee {
  final String id;
  final String name;
  final Color color;
  final UserRole role;
  int currentFloorNumber;
  double positionX;
  double positionY;

  Employee({
    required this.id,
    required this.name,
    required this.color,
    required this.role,
    required this.currentFloorNumber,
    required this.positionX,
    required this.positionY,
  });
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.supervisor:
        return 'Superviseur';
      case UserRole.employee:
        return 'Employé';
    }
  }
}

// ── WarehouseTask ─────────────────────────────────────────────────────────

class WarehouseTask {
  final String id;
  final String description;
  final String targetZoneLabel;
  final int targetFloor;
  final int targetFloorNumber;
  final String orderCode;
  final String productName;
  final String assignedEmployeeId;
  TaskStatus status;
  final TaskPriority priority;
  DateTime? startedAt;
  DateTime? completedAt;
  final DateTime createdAt;

  WarehouseTask({
    required this.id,
    required this.description,
    required this.targetZoneLabel,
    required this.targetFloor,
    int? targetFloorNumber,
    this.orderCode = '',
    this.productName = '',
    this.assignedEmployeeId = '',
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.startedAt,
    this.completedAt,
    DateTime? createdAt,
  })  : targetFloorNumber = targetFloorNumber ?? targetFloor,
        createdAt = createdAt ?? DateTime.now();
}

enum TaskStatus { pending, inProgress, completed }

enum TaskPriority { low, medium, high, urgent }

extension TaskStatusInfo on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.completed:
        return 'Terminée';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return const Color(0xFFFF9800);
      case TaskStatus.inProgress:
        return const Color(0xFF2196F3);
      case TaskStatus.completed:
        return const Color(0xFF4CAF50);
    }
  }

  String get icon {
    switch (this) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.inProgress:
        return '🔄';
      case TaskStatus.completed:
        return '✅';
    }
  }
}

extension TaskPriorityInfo on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Basse';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Haute';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF4CAF50);
      case TaskPriority.medium:
        return const Color(0xFF2196F3);
      case TaskPriority.high:
        return const Color(0xFFFF9800);
      case TaskPriority.urgent:
        return const Color(0xFFF44336);
    }
  }
}

// ── Occupancy helper ───────────────────────────────────────────────────────

ZoneStatus _statusFromPercent(double pct) {
  if (pct <= 0) return ZoneStatus.empty;
  if (pct <= 0.30) return ZoneStatus.low;
  if (pct <= 0.60) return ZoneStatus.medium;
  if (pct <= 0.85) return ZoneStatus.high;
  return ZoneStatus.full;
}

OccupancyLevel _occupancyFromPercent(double pct) {
  if (pct <= 0) return OccupancyLevel.empty;
  if (pct <= 0.30) return OccupancyLevel.low;
  if (pct <= 0.60) return OccupancyLevel.medium;
  if (pct <= 0.85) return OccupancyLevel.high;
  return OccupancyLevel.full;
}

// ════════════════════════════════════════════════════════════════════════════
// DATA GENERATOR  –  architectural-plan faithful layout
// ════════════════════════════════════════════════════════════════════════════

class WarehouseDataGenerator {
  static const double _w = 44.0; // warehouse width  (m)
  static const double _h = 27.0; // warehouse height (m)

  // ── static floor name helper ────────────────────────────────────────────
  static String floorName(int floor) {
    switch (floor) {
      case 0:
        return 'RDC';
      case 1:
        return '1er Étage';
      case 2:
        return '2ème Étage';
      case 3:
        return '3ème Étage';
      case 4:
        return '4ème Étage';
      default:
        return '${floor}e Étage';
    }
  }

  // ── public entry point ──────────────────────────────────────────────────
  static List<WarehouseFloor> generateAllFloors() {
    return [
      _generateRDC(),
      _buildUpperFloorLayout('1er Étage', 1),
      _buildUpperFloorLayout('2ème Étage', 2),
      _build3rd4thFloorLayout('3ème Étage', 3),
      _build3rd4thFloorLayout('4ème Étage', 4),
    ];
  }

  // ── helper: quick rack builder ──────────────────────────────────────────
  static StorageZone _rack(
    String label,
    double x,
    double y,
    double w,
    double h, {
    double occ = 0.5,
    ZoneType type = ZoneType.rack,
    int rackLevels = 1,
  }) {
    final cap = (w * h * 10).round() * rackLevels;
    final cur = (cap * occ).round();
    return StorageZone(
      id: '${label}_${x}_$y',
      label: label,
      type: type,
      x: x,
      y: y,
      widthM: w,
      heightM: h,
      status: _statusFromPercent(occ),
      occupancyRate: occ,
      occupancy: _occupancyFromPercent(occ),
      currentItems: cur,
      maxCapacity: cap,
      rackLevels: rackLevels,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RDC  (floor 0)
  // ══════════════════════════════════════════════════════════════════════════
  static WarehouseFloor _generateRDC() {
    final zones = <StorageZone>[];

    // — Ascenseur (top-left) —
    zones.add(_rack('Ascenseur', 1.5, 3.5, 5.0, 3.0,
        type: ZoneType.elevator, occ: 0));

    // — VRAC (top-right corner, 2 zones) —
    zones.add(_rack('VRAC', 30.0, 0.3, 13.5, 4.0,
        type: ZoneType.bulk, occ: 0.7));
    zones.add(_rack('VRAC', 38.0, 4.8, 5.5, 3.5,
        type: ZoneType.bulk, occ: 0.5));

    // — Monte-charges —
    zones.add(_rack('MC2', 30.5, 5.0, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));
    zones.add(_rack('MC1', 34.5, 5.0, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));

    // — Zone Expédition (right side, 2 zones) —
    zones.add(_rack('Zone expédition', 36.0, 10.0, 7.5, 5.0,
        type: ZoneType.shipping, occ: 0.4));
    zones.add(_rack('Zone expédition', 36.0, 15.5, 7.5, 5.0,
        type: ZoneType.shipping, occ: 0.3));

    // — Bureau (bottom-right) —
    zones.add(_rack('Bureau', 30.0, 22.0, 13.5, 4.5,
        type: ZoneType.office, occ: 0));

    // — W rack (left-side, tall vertical) —
    zones.add(_rack('W', 0.5, 7.5, 1.5, 18.5, occ: 0.6));

    // — X rack (top-center, wide horizontal) —
    zones.add(_rack('X', 9.0, 0.3, 15.0, 6.0, occ: 0.55));

    // — Rack pairs (architectural plan order) —
    const double rW = 2.0, rH = 5.0;

    // Row 1  y = 7.0, height = 7.0  — 3 rack levels per slot
    zones.add(_rack('T', 3.0, 9.0, rW, 7.0, occ: 0.45, rackLevels: 3));
    zones.add(_rack('V', 5.5, 9.0, rW, 7.0, occ: 0.50, rackLevels: 3));
    zones.add(_rack('P', 9.0, 9.0, rW, 7.0, occ: 0.70, rackLevels: 3));
    zones.add(_rack('Q', 11.5,9.0, rW, 7.0, occ: 0.65, rackLevels: 3));
    zones.add(_rack('I', 15.0, 9.0, rW, 7.0, occ: 0.40, rackLevels: 3));
    zones.add(_rack('K', 17.5, 9.0, rW, 7.0, occ: 0.55, rackLevels: 3));
    zones.add(_rack('E', 21.0, 9.0, rW, 7.0, occ: 0.80, rackLevels: 3));
    zones.add(_rack('C', 23.5, 9.0, rW, 7.0, occ: 0.35, rackLevels: 3));
    zones.add(_rack('A', 27.0, 9.0, rW, 7.0, occ: 0.60, rackLevels: 3));

    // Row 2  y = 14.5, height = 10.0  — 3 rack levels per slot
    zones.add(_rack('R', 3.0, 16.5, rW, 10.0, occ: 0.50, rackLevels: 3));
    zones.add(_rack('S', 5.5, 16.5, rW, 10.0, occ: 0.55, rackLevels: 3));
    zones.add(_rack('M', 9.0, 16.5, rW, 10.0, occ: 0.65, rackLevels: 3));
    zones.add(_rack('N', 11.5, 16.5, rW, 10.0, occ: 0.70, rackLevels: 3));
    zones.add(_rack('G', 15.0, 16.5, rW, 10.0, occ: 0.45, rackLevels: 3));
    zones.add(_rack('H', 17.5, 16.5, rW, 10.0, occ: 0.60, rackLevels: 3));
    zones.add(_rack('D', 21.0, 16.5, rW, 10.0, occ: 0.75, rackLevels: 3));
    zones.add(_rack('F', 23.5, 16.5, rW, 10.0, occ: 0.40, rackLevels: 3));
    zones.add(_rack('B', 27.0, 16.5, rW, 10.0, occ: 0.50, rackLevels: 3));

    // — Pillars RDC —
    _addPillarsRDC(zones);

    return WarehouseFloor(
      name: 'RDC',
      floorNumber: 0,
      totalWidthM: _w,
      totalHeightM: _h,
      zones: zones,
    );
  }

  static void _addPillarsRDC(List<StorageZone> z) {
    const s = 0.4;
    const rows = [7.5, 13.5, 20.0];
    const cols = [4.5, 11.0, 17.5, 24.0, 30.5];
    for (final py in rows) {
      for (final px in cols) {
        z.add(_rack('Pilier', px, py, s, s, type: ZoneType.pillar, occ: 0));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  1er & 2ème Étage  (floors 1, 2)
  // ══════════════════════════════════════════════════════════════════════════
  static WarehouseFloor _buildUpperFloorLayout(String name, int floor) {
    final zones = <StorageZone>[];

    // — Ascenseur —
    zones.add(_rack('Ascenseur', 3.8, 4.5, 7.6, 2.9,
        type: ZoneType.elevator, occ: 0));

    // — Monte-charges —
    zones.add(_rack('MC2', 29.2, 4.8, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));
    zones.add(_rack('MC1', 31.9, 4.8, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));

    // ── A-row (right side, top) — floor slots ──
    zones.add(_rack('A1', 41.5, 1.0, 2.0, 7.0, occ: 0.6, type: ZoneType.floorStorage));
    zones.add(_rack('A2', 39.2, 1.0, 2.0, 7.0, occ: 0.5, type: ZoneType.floorStorage));
    zones.add(_rack('A3', 36.9, 1.0, 2.0, 7.0, occ: 0.4, type: ZoneType.floorStorage));
    zones.add(_rack('A4', 34.5, 1.0, 1.8, 2.6, occ: 0.35, type: ZoneType.floorStorage));
    zones.add(_rack('A5', 29.2, 3.0, 2.5, 1.5, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('A6', 31.9, 3.0, 2.5, 1.5, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('A7', 34.5, 3.0, 2.5, 1.5, occ: 0.45, type: ZoneType.floorStorage));
    zones.add(_rack('A8', 25.0, 1.0, 2.0, 7.0, occ: 0.65, type: ZoneType.floorStorage));

    // ── B-row (left side, top) — floor slots ──
    zones.add(_rack('B6', 3.8, 1.0, 7.6, 1.3, occ: 0.40, type: ZoneType.floorStorage));
    zones.add(_rack('B7', 0.8, 1.0, 1.0, 7.0, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('B5', 12.1, 1.0, 1.0, 7.0, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('B4', 14.4, 1.0, 2.0, 7.0, occ: 0.60, type: ZoneType.floorStorage));
    zones.add(_rack('B3', 16.7, 1.0, 2.0, 7.0, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('B2', 19.0, 1.0, 2.0, 7.0, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('B1', 21.3, 1.0, 2.0, 7.0, occ: 0.45, type: ZoneType.floorStorage));

    // ── D-row (middle-left band, y = 9.5) — floor slots ──
    for (int i = 8; i >= 1; i--) {
      final x = 1.0 + (8 - i) * 2.5;
      zones.add(_rack('D$i', x, 9.5, 2.0, 7.0, occ: 0.3 + i * 0.05, type: ZoneType.floorStorage));
    }

    // ── C-row (middle-right band, y = 9.5) — floor slots ──
    for (int i = 9; i >= 1; i--) {
      final x = 22.0 + (9 - i) * 2.5;
      zones.add(_rack('C$i', x, 9.5, 2.0, 7.0, occ: 0.3 + i * 0.04, type: ZoneType.floorStorage));
    }

    // ── E-row (bottom band, y = 19.5) — floor slots ──
    for (int i = 18; i >= 1; i--) {
      final x = 1.0 + (18 - i) * 2.35;
      zones.add(_rack('E$i', x, 19.5, 2.0, 7.0, occ: 0.25 + i * 0.03, type: ZoneType.floorStorage));
    }

    // — Pillars —
    _addPillars12(zones);

    return WarehouseFloor(
      name: name,
      floorNumber: floor,
      totalWidthM: _w,
      totalHeightM: _h,
      zones: zones,
    );
  }

  static void _addPillars12(List<StorageZone> z) {
    const s = 0.4;
    const cols = [3.5, 11.5, 18.0, 24.5, 31.0, 38.0];
    const rows = [8.5, 18.5];
    for (final py in rows) {
      for (final px in cols) {
        z.add(_rack('Pilier', px, py, s, s, type: ZoneType.pillar, occ: 0));
      }
    }

    // Additional row requested for 1er/2ème étage
    const row16Cols = [2.0, 6.5, 12.0, 19.0, 20.0, 27.0, 33.5, 42.0];
    for (final px in row16Cols) {
      z.add(_rack('Pilier', px, 16.0, s, s, type: ZoneType.pillar, occ: 0));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  3ème & 4ème Étage  (floors 3, 4)
  // ══════════════════════════════════════════════════════════════════════════
  static WarehouseFloor _build3rd4thFloorLayout(String name, int floor) {
    final zones = <StorageZone>[];

    // — Ascenseur (larger on 3-4) —
    zones.add(_rack('Ascenseur', 3.8, 5.1, 7.6, 4.2,
        type: ZoneType.elevator, occ: 0));

    // — Monte-charges —
    zones.add(_rack('MC2', 29.2, 6.1, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));
    zones.add(_rack('MC1', 31.9, 6.1, 2.0, 2.0,
        type: ZoneType.freightLift, occ: 0));

    // ── A-row (right side) — floor slots ──
    zones.add(_rack('A1', 41.5, 1.0, 2.0, 8.0, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('A2', 38.5, 1.0, 2.0, 8.0, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('A3', 36.2, 1.0, 2.0, 8.0, occ: 0.45, type: ZoneType.floorStorage));
    zones.add(_rack('A4', 29.2, 3.2, 3.8, 1.9, occ: 0.40, type: ZoneType.floorStorage));
    zones.add(_rack('A5', 27.3, 1.3, 6.1, 1.6, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('A6', 24.3, 1.0, 2.0, 8.0, occ: 0.60, type: ZoneType.floorStorage));

    // ── B-row (left side) — floor slots ──
    zones.add(_rack('B5', 3.8, 1.0, 7.6, 1.3, occ: 0.40, type: ZoneType.floorStorage));
    zones.add(_rack('B6', 0.8, 1.0, 1.0, 8.0, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('B4', 12.1, 1.0, 2.0, 8.0, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('B3', 14.4, 1.0, 2.0, 8.0, occ: 0.55, type: ZoneType.floorStorage));
    zones.add(_rack('B2', 17.1, 1.0, 2.0, 8.0, occ: 0.50, type: ZoneType.floorStorage));
    zones.add(_rack('B1', 19.7, 1.0, 2.0, 8.0, occ: 0.45, type: ZoneType.floorStorage));

    // ── D-row upper (y = 10.5, short slots) — floor slots ──
    for (int i = 7; i >= 1; i--) {
      final x = 1.0 + (7 - i) * 2.6;
      zones.add(_rack('D$i', x, 10.5, 2.0, 3.5, occ: 0.35 + i * 0.05, type: ZoneType.floorStorage));
    }

    // ── C-row upper (y = 10.5) — floor slots ──
    for (int i = 6; i >= 1; i--) {
      final x = 22.0 + (6 - i) * 2.6;
      zones.add(_rack('C$i', x, 10.5, 2.0, 3.5, occ: 0.30 + i * 0.06, type: ZoneType.floorStorage));
    }

    // ── D-row lower (y = 14.5, taller slots) — floor slots ──
    for (int i = 14; i >= 8; i--) {
      final x = 1.0 + (14 - i) * 2.6;
      zones.add(_rack('D$i', x, 14.5, 2.0, 4.5, occ: 0.30 + (i - 7) * 0.04, type: ZoneType.floorStorage));
    }

    // ── C-row lower (y = 14.5) — floor slots ──
    for (int i = 12; i >= 7; i--) {
      final x = 22.0 + (12 - i) * 2.6;
      zones.add(_rack('C$i', x, 14.5, 2.0, 4.5, occ: 0.30 + (i - 6) * 0.04, type: ZoneType.floorStorage));
    }

    // ── E-row (bottom band, y = 20.5) — floor slots ──
    for (int i = 17; i >= 1; i--) {
      final x = 1.0 + (17 - i) * 2.5;
      zones.add(_rack('E$i', x, 20.5, 2.0, 5.5, occ: 0.25 + i * 0.03, type: ZoneType.floorStorage));
    }

    // — Pillars —
    _addPillars34(zones);

    return WarehouseFloor(
      name: name,
      floorNumber: floor,
      totalWidthM: _w,
      totalHeightM: _h,
      zones: zones,
    );
  }

  static void _addPillars34(List<StorageZone> z) {
    const s = 0.4;
    const cols = [3.5, 11.5, 18.0, 24.5, 31.0, 38.0];
    const rows = [9.8, 14.0, 19.5];
    for (final py in rows) {
      for (final px in cols) {
        z.add(_rack('Pilier', px, py, s, s, type: ZoneType.pillar, occ: 0));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Sample Tasks
  // ══════════════════════════════════════════════════════════════════════════
  static List<WarehouseTask> generateSampleTasks() {
    return [
      WarehouseTask(
        id: 'T001',
        description: 'Réapprovisionner le rack A3 – 1er étage',
        targetZoneLabel: 'A3',
        targetFloor: 1,
        orderCode: 'ORD-001',
        productName: 'Produit Alpha',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
      WarehouseTask(
        id: 'T002',
        description: 'Inventaire rack C2 – 3ème étage',
        targetZoneLabel: 'C2',
        targetFloor: 3,
        orderCode: 'ORD-002',
        productName: 'Produit Beta',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
      ),
      WarehouseTask(
        id: 'T003',
        description: 'Transfert palette B4 – 2ème étage',
        targetZoneLabel: 'B4',
        targetFloor: 2,
        orderCode: 'ORD-003',
        productName: 'Produit Gamma',
        status: TaskStatus.pending,
        priority: TaskPriority.urgent,
      ),
      WarehouseTask(
        id: 'T004',
        description: 'Picking rack T – RDC',
        targetZoneLabel: 'T',
        targetFloor: 0,
        orderCode: 'ORD-004',
        productName: 'Produit Delta',
        status: TaskStatus.completed,
        priority: TaskPriority.low,
      ),
      WarehouseTask(
        id: 'T005',
        description: 'Vérification rack A2 – 4ème étage',
        targetZoneLabel: 'A2',
        targetFloor: 4,
        orderCode: 'ORD-005',
        productName: 'Produit Epsilon',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
      ),
      WarehouseTask(
        id: 'T006',
        description: 'Expédition depuis E9 – 3ème étage',
        targetZoneLabel: 'E9',
        targetFloor: 3,
        orderCode: 'ORD-006',
        productName: 'Produit Zeta',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Employees & Tasks with assignment
  // ══════════════════════════════════════════════════════════════════════════
  static List<Employee> generateEmployees() {
    return [
      Employee(
        id: 'EMP001',
        name: 'Ahmed Ben Salah',
        color: const Color(0xFF1E88E5),
        role: UserRole.supervisor,
        currentFloorNumber: 0,
        positionX: 10.0,
        positionY: 12.0,
      ),
      Employee(
        id: 'EMP002',
        name: 'Mohamed Trabelsi',
        color: const Color(0xFF43A047),
        role: UserRole.employee,
        currentFloorNumber: 1,
        positionX: 15.0,
        positionY: 8.0,
      ),
      Employee(
        id: 'EMP003',
        name: 'Fatma Bouazizi',
        color: const Color(0xFFE53935),
        role: UserRole.employee,
        currentFloorNumber: 2,
        positionX: 20.0,
        positionY: 14.0,
      ),
      Employee(
        id: 'EMP004',
        name: 'Sami Jelassi',
        color: const Color(0xFFFF9800),
        role: UserRole.employee,
        currentFloorNumber: 3,
        positionX: 8.0,
        positionY: 18.0,
      ),
      Employee(
        id: 'EMP005',
        name: 'Leila Hamdi',
        color: const Color(0xFF8E24AA),
        role: UserRole.admin,
        currentFloorNumber: 0,
        positionX: 32.0,
        positionY: 23.0,
      ),
    ];
  }

  static List<WarehouseTask> generateTasks(List<Employee> employees) {
    final tasks = generateSampleTasks();
    // Assign employees round-robin
    for (int i = 0; i < tasks.length; i++) {
      if (employees.isNotEmpty) {
        final emp = employees[i % employees.length];
        tasks[i] = WarehouseTask(
          id: tasks[i].id,
          description: tasks[i].description,
          targetZoneLabel: tasks[i].targetZoneLabel,
          targetFloor: tasks[i].targetFloor,
          orderCode: tasks[i].orderCode,
          productName: tasks[i].productName,
          assignedEmployeeId: emp.id,
          status: tasks[i].status,
          priority: tasks[i].priority,
        );
      }
    }
    return tasks;
  }
}
