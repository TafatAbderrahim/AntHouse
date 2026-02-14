import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Icons, IconData, Color, Colors;

// ═══════════════════════════════════════════════════════════════
//  OPERATIONAL DATA MODELS — §7.1, §7.2, §3
//  Shared between Employee & Supervisor interfaces
// ═══════════════════════════════════════════════════════════════

final _rng = Random(42);

// ── Order Types (§2) ───────────────────────────────────────────

enum OrderType { command, preparation, picking, delivery }

extension OrderTypeInfo on OrderType {
  String get label {
    switch (this) {
      case OrderType.command:
        return 'Command Order';
      case OrderType.preparation:
        return 'Preparation Order';
      case OrderType.picking:
        return 'Picking Order';
      case OrderType.delivery:
        return 'Delivery Order';
    }
  }

  String get shortLabel {
    switch (this) {
      case OrderType.command:
        return 'CMD';
      case OrderType.preparation:
        return 'PREP';
      case OrderType.picking:
        return 'PICK';
      case OrderType.delivery:
        return 'DLV';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.command:
        return Icons.receipt_long_rounded;
      case OrderType.preparation:
        return Icons.assignment_rounded;
      case OrderType.picking:
        return Icons.shopping_cart_rounded;
      case OrderType.delivery:
        return Icons.local_shipping_rounded;
    }
  }

  Color get color {
    switch (this) {
      case OrderType.command:
        return const Color(0xFF2196F3);
      case OrderType.preparation:
        return const Color(0xFFFF9800);
      case OrderType.picking:
        return const Color(0xFF9C27B0);
      case OrderType.delivery:
        return const Color(0xFF4CAF50);
    }
  }
}

// ── Operation Types (§3.6) ─────────────────────────────────────

enum OpType { receipt, transfer, picking, delivery }

extension OpTypeInfo on OpType {
  String get label {
    switch (this) {
      case OpType.receipt:
        return 'Receipt';
      case OpType.transfer:
        return 'Transfer';
      case OpType.picking:
        return 'Picking';
      case OpType.delivery:
        return 'Delivery';
    }
  }

  IconData get icon {
    switch (this) {
      case OpType.receipt:
        return Icons.inventory_rounded;
      case OpType.transfer:
        return Icons.swap_horiz_rounded;
      case OpType.picking:
        return Icons.shopping_basket_rounded;
      case OpType.delivery:
        return Icons.local_shipping_rounded;
    }
  }

  Color get color {
    switch (this) {
      case OpType.receipt:
        return const Color(0xFF2196F3);
      case OpType.transfer:
        return const Color(0xFFFF9800);
      case OpType.picking:
        return const Color(0xFF9C27B0);
      case OpType.delivery:
        return const Color(0xFF4CAF50);
    }
  }
}

// ── Task Status ────────────────────────────────────────────────

enum OpTaskStatus { pending, inProgress, completed, failed, discrepancy }

extension OpTaskStatusInfo on OpTaskStatus {
  String get label {
    switch (this) {
      case OpTaskStatus.pending:
        return 'Pending';
      case OpTaskStatus.inProgress:
        return 'In Progress';
      case OpTaskStatus.completed:
        return 'Completed';
      case OpTaskStatus.failed:
        return 'Failed';
      case OpTaskStatus.discrepancy:
        return 'Discrepancy';
    }
  }

  Color get color {
    switch (this) {
      case OpTaskStatus.pending:
        return const Color(0xFFFF9800);
      case OpTaskStatus.inProgress:
        return const Color(0xFF2196F3);
      case OpTaskStatus.completed:
        return const Color(0xFF4CAF50);
      case OpTaskStatus.failed:
        return const Color(0xFFF44336);
      case OpTaskStatus.discrepancy:
        return const Color(0xFFE91E63);
    }
  }

  IconData get icon {
    switch (this) {
      case OpTaskStatus.pending:
        return Icons.schedule_rounded;
      case OpTaskStatus.inProgress:
        return Icons.play_circle_rounded;
      case OpTaskStatus.completed:
        return Icons.check_circle_rounded;
      case OpTaskStatus.failed:
        return Icons.cancel_rounded;
      case OpTaskStatus.discrepancy:
        return Icons.warning_rounded;
    }
  }
}

// ── Operational Task (Employee works with these) ───────────────

class OperationalTask {
  final String id;
  final String orderRef;
  final OpType operation;
  final OrderType orderType;
  final String sku;
  final String productName;
  final int expectedQuantity;
  int receivedQuantity;
  final String fromLocation;
  final String toLocation;
  final int targetFloor;
  OpTaskStatus status;
  final bool aiGenerated;
  final double aiConfidence;
  final String assignedEmployeeId;
  final String assignedChariotId;
  String? discrepancyNote;
  DateTime? startedAt;
  DateTime? completedAt;
  final DateTime createdAt;
  final DateTime dueDate;

  OperationalTask({
    required this.id,
    required this.orderRef,
    required this.operation,
    required this.orderType,
    required this.sku,
    required this.productName,
    required this.expectedQuantity,
    this.receivedQuantity = 0,
    required this.fromLocation,
    required this.toLocation,
    required this.targetFloor,
    this.status = OpTaskStatus.pending,
    this.aiGenerated = true,
    this.aiConfidence = 0.9,
    this.assignedEmployeeId = '',
    this.assignedChariotId = '',
    this.discrepancyNote,
    this.startedAt,
    this.completedAt,
    DateTime? createdAt,
    DateTime? dueDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(hours: 8));

  bool get hasDiscrepancy =>
      receivedQuantity != expectedQuantity && receivedQuantity > 0;

  double get progress {
    if (status == OpTaskStatus.completed) return 1.0;
    if (status == OpTaskStatus.pending) return 0.0;
    if (expectedQuantity == 0) return 0.0;
    return (receivedQuantity / expectedQuantity).clamp(0.0, 1.0);
  }
}

// ── Chariot (§3.4 FR-30 to FR-34) ─────────────────────────────

class Chariot {
  final String id;
  final String code;
  String assignedOperation;
  int currentFloor;
  double posX;
  double posY;
  bool inUse;
  final String assignedEmployeeId;

  Chariot({
    required this.id,
    required this.code,
    this.assignedOperation = '',
    this.currentFloor = 0,
    this.posX = 5.0,
    this.posY = 5.0,
    this.inUse = false,
    this.assignedEmployeeId = '',
  });
}

// ── AI Decision (for Supervisor review) ────────────────────────

class AiOperationalDecision {
  final String id;
  final OrderType orderType;
  final String orderRef;
  final String description;
  final String suggestedAction;
  final String fromLocation;
  final String toLocation;
  final double confidence;
  final String reasoning;
  String status; // 'pending', 'approved', 'overridden'
  String? overrideJustification;
  String? overriddenBy;
  DateTime? overriddenAt;
  final DateTime createdAt;

  AiOperationalDecision({
    required this.id,
    required this.orderType,
    required this.orderRef,
    required this.description,
    required this.suggestedAction,
    required this.fromLocation,
    required this.toLocation,
    this.confidence = 0.9,
    this.reasoning = '',
    this.status = 'pending',
    this.overrideJustification,
    this.overriddenBy,
    this.overriddenAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ── Incident (§7.2 item 5) ─────────────────────────────────────

enum IncidentType { missingProduct, damagedProduct, locationConflict, bottleneck, other }

extension IncidentTypeInfo on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.missingProduct:
        return 'Missing Product';
      case IncidentType.damagedProduct:
        return 'Damaged Product';
      case IncidentType.locationConflict:
        return 'Location Conflict';
      case IncidentType.bottleneck:
        return 'Workflow Bottleneck';
      case IncidentType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.missingProduct:
        return Icons.search_off_rounded;
      case IncidentType.damagedProduct:
        return Icons.broken_image_rounded;
      case IncidentType.locationConflict:
        return Icons.wrong_location_rounded;
      case IncidentType.bottleneck:
        return Icons.traffic_rounded;
      case IncidentType.other:
        return Icons.report_problem_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.missingProduct:
        return const Color(0xFFF44336);
      case IncidentType.damagedProduct:
        return const Color(0xFFE91E63);
      case IncidentType.locationConflict:
        return const Color(0xFFFF9800);
      case IncidentType.bottleneck:
        return const Color(0xFF9C27B0);
      case IncidentType.other:
        return const Color(0xFF607D8B);
    }
  }
}

class Incident {
  final String id;
  final IncidentType type;
  final String description;
  final String location;
  final int floor;
  String status; // 'open', 'investigating', 'resolved'
  final String reportedBy;
  String? resolvedBy;
  String? resolution;
  final DateTime reportedAt;
  DateTime? resolvedAt;

  Incident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.floor,
    this.status = 'open',
    required this.reportedBy,
    this.resolvedBy,
    this.resolution,
    DateTime? reportedAt,
    this.resolvedAt,
  }) : reportedAt = reportedAt ?? DateTime.now();
}

// ── Live Worker Position (§7.2 item 4) ─────────────────────────

class LiveWorker {
  final String id;
  final String name;
  final String role;
  int floor;
  double x;
  double y;
  String currentTask;
  String status; // 'active', 'idle', 'break'
  final Color color;

  LiveWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.floor,
    required this.x,
    required this.y,
    this.currentTask = '',
    this.status = 'active',
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════
//  MOCK DATA GENERATOR
// ═══════════════════════════════════════════════════════════════

class MockOperationsData {
  static final _now = DateTime.now();

  // ── Employee tasks (§7.1) ────────────────────────────────────

  static List<OperationalTask> generateEmployeeTasks(String employeeId) {
    return [
      // Receipt tasks (§7.1 step 3)
      OperationalTask(
        id: 'OT-001',
        orderRef: 'CMD-2026-0214-001',
        operation: OpType.receipt,
        orderType: OrderType.command,
        sku: 'SKU-31334',
        productName: 'Câble cuivre 16mm²',
        expectedQuantity: 120,
        fromLocation: 'SUPPLIER',
        toLocation: 'B7-RDC-RECEPTION',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-01',
        aiConfidence: 0.94,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 2)),
      ),
      OperationalTask(
        id: 'OT-002',
        orderRef: 'CMD-2026-0214-002',
        operation: OpType.receipt,
        orderType: OrderType.command,
        sku: 'SKU-31335',
        productName: 'Disjoncteur 32A',
        expectedQuantity: 60,
        fromLocation: 'SUPPLIER',
        toLocation: 'B7-RDC-RECEPTION',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-01',
        aiConfidence: 0.91,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 2)),
      ),

      // Transfer / Storage tasks (§7.1 step 4)
      OperationalTask(
        id: 'OT-003',
        orderRef: 'TRF-2026-0214-001',
        operation: OpType.transfer,
        orderType: OrderType.command,
        sku: 'SKU-31334',
        productName: 'Câble cuivre 16mm²',
        expectedQuantity: 120,
        fromLocation: 'B7-RDC-RECEPTION',
        toLocation: 'B7-N1-C7',
        targetFloor: 1,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-02',
        aiConfidence: 0.88,
        aiGenerated: true,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 4)),
      ),
      OperationalTask(
        id: 'OT-004',
        orderRef: 'TRF-2026-0214-002',
        operation: OpType.transfer,
        orderType: OrderType.command,
        sku: 'SKU-31336',
        productName: 'Tableau électrique 12 modules',
        expectedQuantity: 40,
        fromLocation: 'B7-RDC-RECEPTION',
        toLocation: 'B7-N2-D3',
        targetFloor: 2,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-02',
        aiConfidence: 0.85,
        aiGenerated: true,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 4)),
      ),

      // Picking tasks (§7.1 step 5)
      OperationalTask(
        id: 'OT-005',
        orderRef: 'PICK-2026-0214-001',
        operation: OpType.picking,
        orderType: OrderType.picking,
        sku: 'SKU-31337',
        productName: 'Prise murale 2P+T',
        expectedQuantity: 200,
        fromLocation: 'B7-N1-A3',
        toLocation: 'B7-0A-02-01',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-03',
        aiConfidence: 0.92,
        aiGenerated: true,
        status: OpTaskStatus.inProgress,
        startedAt: _now.subtract(const Duration(minutes: 30)),
        receivedQuantity: 140,
        dueDate: _now.add(const Duration(hours: 3)),
      ),
      OperationalTask(
        id: 'OT-006',
        orderRef: 'PICK-2026-0214-002',
        operation: OpType.picking,
        orderType: OrderType.picking,
        sku: 'SKU-31338',
        productName: 'Interrupteur différentiel 30mA',
        expectedQuantity: 80,
        fromLocation: 'B7-N3-D8',
        toLocation: 'B7-0A-03-02',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-03',
        aiConfidence: 0.87,
        aiGenerated: true,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 5)),
      ),

      // Delivery tasks (§7.1 step 6)
      OperationalTask(
        id: 'OT-007',
        orderRef: 'DLV-2026-0214-001',
        operation: OpType.delivery,
        orderType: OrderType.delivery,
        sku: 'SKU-31339',
        productName: 'Gaine ICTA 20mm',
        expectedQuantity: 500,
        fromLocation: 'B7-0A-01-03',
        toLocation: 'EXPEDITION',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-04',
        aiConfidence: 0.95,
        status: OpTaskStatus.completed,
        startedAt: _now.subtract(const Duration(hours: 2)),
        completedAt: _now.subtract(const Duration(hours: 1)),
        receivedQuantity: 500,
        dueDate: _now,
      ),
      OperationalTask(
        id: 'OT-008',
        orderRef: 'DLV-2026-0214-002',
        operation: OpType.delivery,
        orderType: OrderType.delivery,
        sku: 'SKU-31340',
        productName: 'Boîte de dérivation IP55',
        expectedQuantity: 150,
        fromLocation: 'B7-0A-04-01',
        toLocation: 'EXPEDITION',
        targetFloor: 0,
        assignedEmployeeId: employeeId,
        assignedChariotId: 'CHR-04',
        aiConfidence: 0.90,
        status: OpTaskStatus.pending,
        dueDate: _now.add(const Duration(hours: 6)),
      ),
    ];
  }

  // ── Chariots (§3.4) ─────────────────────────────────────────

  static List<Chariot> generateChariots() {
    return [
      Chariot(id: 'CHR-01', code: 'Chariot A', assignedOperation: 'Receipt', currentFloor: 0, posX: 8.0, posY: 22.0, inUse: true, assignedEmployeeId: 'EMP002'),
      Chariot(id: 'CHR-02', code: 'Chariot B', assignedOperation: 'Transfer', currentFloor: 1, posX: 15.0, posY: 10.0, inUse: true, assignedEmployeeId: 'EMP003'),
      Chariot(id: 'CHR-03', code: 'Chariot C', assignedOperation: 'Picking', currentFloor: 0, posX: 20.0, posY: 6.0, inUse: true, assignedEmployeeId: 'EMP004'),
      Chariot(id: 'CHR-04', code: 'Chariot D', assignedOperation: '', currentFloor: 0, posX: 36.0, posY: 12.0, inUse: false, assignedEmployeeId: ''),
      Chariot(id: 'CHR-05', code: 'Chariot E', assignedOperation: '', currentFloor: 0, posX: 38.0, posY: 20.0, inUse: false, assignedEmployeeId: ''),
    ];
  }

  // ── AI Decisions for Supervisor review (§7.2) ───────────────

  static List<AiOperationalDecision> generateAiDecisions() {
    return [
      AiOperationalDecision(
        id: 'AID-001',
        orderType: OrderType.preparation,
        orderRef: 'PREP-2026-0215-001',
        description: 'AI forecasted demand for Câble cuivre 16mm² — prepare 120 units',
        suggestedAction: 'Prepare 120 units from B7-N1-C7 to picking rack B7-0A-02-01',
        fromLocation: 'B7-N1-C7',
        toLocation: 'B7-0A-02-01',
        confidence: 0.92,
        reasoning: 'Based on 30-day demand pattern: avg 115 units/day, +4.3% trend. Seasonal peak expected.',
        status: 'pending',
        createdAt: _now.subtract(const Duration(hours: 1)),
      ),
      AiOperationalDecision(
        id: 'AID-002',
        orderType: OrderType.preparation,
        orderRef: 'PREP-2026-0215-002',
        description: 'AI forecasted demand for Disjoncteur 32A — prepare 45 units',
        suggestedAction: 'Prepare 45 units from B7-N2-D3 to picking rack B7-0A-03-02',
        fromLocation: 'B7-N2-D3',
        toLocation: 'B7-0A-03-02',
        confidence: 0.85,
        reasoning: 'Historical average: 42 units/day. Slight uptick in recent orders.',
        status: 'approved',
        createdAt: _now.subtract(const Duration(hours: 3)),
      ),
      AiOperationalDecision(
        id: 'AID-003',
        orderType: OrderType.picking,
        orderRef: 'PICK-2026-0214-003',
        description: 'Optimized picking route for Prise murale 2P+T — shortest path via MC1',
        suggestedAction: 'Pick from B7-N1-A3 → MC1 → B7-0A-02-01 (distance: 47m)',
        fromLocation: 'B7-N1-A3',
        toLocation: 'B7-0A-02-01',
        confidence: 0.94,
        reasoning: 'Route via MC1 saves 12m vs MC2. No congestion predicted in next 30min.',
        status: 'pending',
        createdAt: _now.subtract(const Duration(minutes: 45)),
      ),
      AiOperationalDecision(
        id: 'AID-004',
        orderType: OrderType.picking,
        orderRef: 'PICK-2026-0214-004',
        description: 'Storage placement for new batch: Gaine ICTA 20mm — assign to B7-N1-B4',
        suggestedAction: 'Store at B7-N1-B4 (high demand SKU, close to MC1, 65% slot available)',
        fromLocation: 'B7-RDC-RECEPTION',
        toLocation: 'B7-N1-B4',
        confidence: 0.88,
        reasoning: 'Weight: 2.3kg/unit (ground OK). Demand freq: top 15%. Slot B4 has 65% capacity.',
        status: 'pending',
        createdAt: _now.subtract(const Duration(minutes: 20)),
      ),
      AiOperationalDecision(
        id: 'AID-005',
        orderType: OrderType.preparation,
        orderRef: 'PREP-2026-0215-003',
        description: 'AI forecasted demand for Interrupteur diff 30mA — prepare 60 units',
        suggestedAction: 'Prepare 60 units from B7-N3-D8 to picking B7-0A-03-02',
        fromLocation: 'B7-N3-D8',
        toLocation: 'B7-0A-03-02',
        confidence: 0.78,
        reasoning: 'Moderate confidence. Recent demand volatile (40-80 range). Conservative estimate.',
        status: 'overridden',
        overrideJustification: 'Increased to 80 units — client confirmed large order arriving tomorrow.',
        overriddenBy: 'Supervisor Karim',
        overriddenAt: _now.subtract(const Duration(hours: 2)),
        createdAt: _now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  // ── Incidents (§7.2 item 5) ──────────────────────────────────

  static List<Incident> generateIncidents() {
    return [
      Incident(
        id: 'INC-001',
        type: IncidentType.missingProduct,
        description: 'SKU-31335 reported missing from B7-N2-D3. Expected 60, found 52.',
        location: 'B7-N2-D3',
        floor: 2,
        status: 'open',
        reportedBy: 'Mohamed Trabelsi',
        reportedAt: _now.subtract(const Duration(hours: 1)),
      ),
      Incident(
        id: 'INC-002',
        type: IncidentType.damagedProduct,
        description: '3 units of Tableau électrique 12 modules damaged during transfer.',
        location: 'B7-N1-C7',
        floor: 1,
        status: 'investigating',
        reportedBy: 'Fatma Bouazizi',
        reportedAt: _now.subtract(const Duration(hours: 3)),
      ),
      Incident(
        id: 'INC-003',
        type: IncidentType.locationConflict,
        description: 'Slot B7-N3-E5 assigned to 2 different SKUs by concurrent operations.',
        location: 'B7-N3-E5',
        floor: 3,
        status: 'open',
        reportedBy: 'System',
        reportedAt: _now.subtract(const Duration(minutes: 30)),
      ),
      Incident(
        id: 'INC-004',
        type: IncidentType.bottleneck,
        description: 'MC1 congested — 3 chariots waiting. Estimated delay: 15min.',
        location: 'MC1',
        floor: 0,
        status: 'resolved',
        reportedBy: 'System',
        resolvedBy: 'Karim Bensalah',
        resolution: 'Redirected Chariot C to MC2. Congestion cleared.',
        reportedAt: _now.subtract(const Duration(hours: 2)),
        resolvedAt: _now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      Incident(
        id: 'INC-005',
        type: IncidentType.other,
        description: 'Barcode scanner malfunction on Chariot B. Manual entry required.',
        location: 'B7-N1',
        floor: 1,
        status: 'open',
        reportedBy: 'Sami Jelassi',
        reportedAt: _now.subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  // ── Live Workers (§7.2 item 4) ──────────────────────────────

  static List<LiveWorker> generateLiveWorkers() {
    return [
      LiveWorker(id: 'LW-001', name: 'Mohamed Trabelsi', role: 'employee', floor: 0, x: 12.0, y: 10.0, currentTask: 'Receipt CMD-2026-0214-001', status: 'active', color: const Color(0xFF43A047)),
      LiveWorker(id: 'LW-002', name: 'Fatma Bouazizi', role: 'employee', floor: 1, x: 18.0, y: 14.0, currentTask: 'Transfer TRF-2026-0214-001', status: 'active', color: const Color(0xFFE53935)),
      LiveWorker(id: 'LW-003', name: 'Sami Jelassi', role: 'employee', floor: 0, x: 22.0, y: 8.0, currentTask: 'Picking PICK-2026-0214-001', status: 'active', color: const Color(0xFFFF9800)),
      LiveWorker(id: 'LW-004', name: 'Youcef Slimani', role: 'employee', floor: 2, x: 8.0, y: 18.0, currentTask: 'Transfer TRF-2026-0214-002', status: 'active', color: const Color(0xFF2196F3)),
      LiveWorker(id: 'LW-005', name: 'Sara Belkacem', role: 'employee', floor: 0, x: 36.0, y: 14.0, currentTask: 'Delivery DLV-2026-0214-001', status: 'active', color: const Color(0xFF9C27B0)),
      LiveWorker(id: 'LW-006', name: 'Ali Djeradi', role: 'employee', floor: 0, x: 30.0, y: 22.0, currentTask: '', status: 'idle', color: const Color(0xFF607D8B)),
      LiveWorker(id: 'LW-007', name: 'Karim Bensalah', role: 'supervisor', floor: 0, x: 32.0, y: 23.0, currentTask: 'Monitoring', status: 'active', color: const Color(0xFF006D84)),
    ];
  }
}
