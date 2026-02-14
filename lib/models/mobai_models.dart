import 'dart:math';
import 'package:flutter/material.dart' show Color;

// ═══════════════════════════════════════════════════════════════
//  MobAI Models — Core domain types referenced across the app
// ═══════════════════════════════════════════════════════════════

enum UserRole { admin, supervisor, employee }

enum OperationType { receipt, transfer, preparation, picking, delivery }

// ── ValidationTask ────────────────────────────────────────────

class ValidationTask {
  final String id;
  final OperationType operation;
  final String orderRef;
  final String status; // pending, validated, rejected
  final DateTime createdAt;

  ValidationTask({
    required this.id,
    required this.operation,
    required this.orderRef,
    required this.status,
    required this.createdAt,
  });

  Color get statusColor {
    switch (status) {
      case 'validated':
        return const Color(0xFF35BB96);
      case 'rejected':
        return const Color(0xFFF21919);
      default:
        return const Color(0xFFFAC460);
    }
  }
}

// ── Mock data generator ───────────────────────────────────────

class MobAiMock {
  static final _rng = Random(42);

  static List<ValidationTask> generateTasks() {
    final ops = OperationType.values;
    final statuses = ['pending', 'validated', 'rejected'];
    return List.generate(12, (i) {
      return ValidationTask(
        id: 'VT-${1000 + i}',
        operation: ops[i % ops.length],
        orderRef: 'ORD-${2000 + _rng.nextInt(500)}',
        status: statuses[i % statuses.length],
        createdAt: DateTime.now().subtract(Duration(hours: _rng.nextInt(48))),
      );
    });
  }

  static String operationLabel(OperationType op) {
    switch (op) {
      case OperationType.receipt:
        return 'Réception';
      case OperationType.transfer:
        return 'Transfert';
      case OperationType.preparation:
        return 'Préparation';
      case OperationType.picking:
        return 'Picking';
      case OperationType.delivery:
        return 'Livraison';
    }
  }
}
