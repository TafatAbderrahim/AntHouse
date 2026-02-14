import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _rng = Random(42);

// ═══════════════════════════════════════════════════════════════
//  DESIGN SYSTEM COLORS (§7.1)
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();
  // Primary
  static const Color primaryDark = Color(0xFF006D84);
  static const Color primary = Color(0xFF0E93AF);
  // Semantic
  static const Color accent = Color(0xFFFAC460);   // Orange → Human Overrides
  static const Color success = Color(0xFF35BB96);   // Mint Green → Validated / Approved
  static const Color error = Color(0xFFF21919);     // Red    → Errors / Critical
  static const Color aiBlue = Color(0xFF2E8BC0);    // Blue   → AI Decisions
  static const Color archived = Color(0xFF9EAAB8);  // Grey   → Archived / Historical
  // Surfaces
  static const Color bg = Color(0xFFF6F6F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8ECF0);
  // Text
  static const Color textDark = Color(0xFF1A2B3C);
  static const Color textMid = Color(0xFF5A6B7C);
  static const Color textLight = Color(0xFF8A9BAC);
  // Sidebar
  static const Color sidebar = Color(0xFF006D84);
  static const Color sidebarHover = Color(0xFF0E93AF);
}

// ═══════════════════════════════════════════════════════════════
//  APP USER
// ═══════════════════════════════════════════════════════════════

class AppUser {
  final String id;
  String name;
  String username;
  String email;
  String password;
  String firstName;
  String lastName;
  String role;   // admin, supervisor, employee
  String status; // active, inactive, suspended
  bool active;
  bool accountNonExpired;
  bool accountNonLocked;
  bool credentialsNonExpired;
  DateTime createdAt;
  DateTime? lastLogin;
  Color avatarColor;

  String get fullName => '$firstName $lastName'.trim();
  bool get canAuthenticate =>
      status == 'active' &&
      active &&
      accountNonExpired &&
      accountNonLocked &&
      credentialsNonExpired;

  AppUser({
    String? id,
    required this.name,
    String? username,
    required this.email,
    this.password = '123456',
    String? firstName,
    String? lastName,
    this.role = 'employee',
    this.status = 'active',
    this.active = true,
    this.accountNonExpired = true,
    this.accountNonLocked = true,
    this.credentialsNonExpired = true,
    DateTime? createdAt,
    this.lastLogin,
    Color? avatarColor,
  })  : id = id ?? _uuid.v4(),
        username = username ?? email.split('@').first,
        firstName = firstName ?? (name.trim().isEmpty ? '' : name.trim().split(' ').first),
        lastName = lastName ?? (() {
          final parts = name.trim().split(' ');
          if (parts.length <= 1) return '';
          return parts.sublist(1).join(' ');
        })(),
        createdAt = createdAt ?? DateTime.now(),
        avatarColor = avatarColor ?? _randomColor();

  static Color _randomColor() {
    const colors = [
      Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800),
      Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF00BCD4),
      Color(0xFF795548), Color(0xFF607D8B),
    ];
    return colors[_rng.nextInt(colors.length)];
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRODUCT / INVENTORY
// ═══════════════════════════════════════════════════════════════

class Product {
  final String id;
  String sku;
  String name;
  String category;
  int quantity;
  int minStock;
  int maxStock;
  String locationLabel;
  double price;
  DateTime lastUpdated;

  String get status {
    if (quantity <= 0) return 'out-of-stock';
    if (quantity <= minStock) return 'low-stock';
    return 'in-stock';
  }

  Color get statusColor {
    switch (status) {
      case 'in-stock':
        return AppColors.success;
      case 'low-stock':
        return AppColors.accent;
      default:
        return AppColors.error;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'in-stock':
        return 'In Stock';
      case 'low-stock':
        return 'Low Stock';
      default:
        return 'Out of Stock';
    }
  }

  Product({
    String? id,
    required this.sku,
    required this.name,
    required this.category,
    this.quantity = 0,
    this.minStock = 10,
    this.maxStock = 100,
    this.locationLabel = 'A-01',
    this.price = 0,
    DateTime? lastUpdated,
  })  : id = id ?? _uuid.v4(),
        lastUpdated = lastUpdated ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  AI DECISION
// ═══════════════════════════════════════════════════════════════

class AiDecision {
  final String id;
  String action;        // reorder, relocate, alert, optimize
  String description;
  DateTime timestamp;
  String status;        // approved, overridden, pending
  double confidence;
  String userName;

  Color get statusColor {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'overridden':
        return AppColors.accent;
      default:
        return AppColors.aiBlue;
    }
  }

  AiDecision({
    String? id,
    required this.action,
    required this.description,
    DateTime? timestamp,
    this.status = 'pending',
    this.confidence = 0.85,
    this.userName = 'System',
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  AUDIT LOG
// ═══════════════════════════════════════════════════════════════

class AuditLogEntry {
  final String id;
  String action;        // create, update, delete, override, login
  String description;
  DateTime timestamp;
  String userName;
  String? ipAddress;
  Map<String, String>? beforeData;
  Map<String, String>? afterData;

  Color get actionColor {
    switch (action) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.aiBlue;
      case 'delete':
        return AppColors.error;
      case 'override':
        return AppColors.accent;
      default:
        return AppColors.archived;
    }
  }

  AuditLogEntry({
    String? id,
    required this.action,
    required this.description,
    DateTime? timestamp,
    required this.userName,
    this.ipAddress,
    this.beforeData,
    this.afterData,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  ORDER ENTRY (for dashboard recent orders)
// ═══════════════════════════════════════════════════════════════

class OrderEntry {
  final String id;
  String orderNumber;
  String customer;
  int items;
  double total;
  String status; // processing, shipped, delivered, cancelled
  DateTime createdAt;

  Color get statusColor {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
        return AppColors.aiBlue;
      case 'processing':
        return AppColors.accent;
      default:
        return AppColors.error;
    }
  }

  OrderEntry({
    String? id,
    required this.orderNumber,
    required this.customer,
    this.items = 1,
    this.total = 0,
    this.status = 'processing',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  CHART DATA POINTS
// ═══════════════════════════════════════════════════════════════

class ChartPoint {
  final String label;
  final double value;
  final Color? color;
  const ChartPoint(this.label, this.value, [this.color]);
}

// ═══════════════════════════════════════════════════════════════
//  MOCK DATA GENERATOR
// ═══════════════════════════════════════════════════════════════

class MockDataGenerator {
  static final _r = Random(99);

  // ── Users ──
  static List<AppUser> generateUsers() {
    final now = DateTime.now();
    return [
      AppUser(name: 'Admin Principal', firstName: 'Admin', lastName: 'Principal', username: 'admin', email: 'admin@antbms.dz', password: 'admin123', role: 'admin', status: 'active', active: true, accountNonExpired: true, accountNonLocked: true, credentialsNonExpired: true, lastLogin: now.subtract(const Duration(minutes: 5)), avatarColor: const Color(0xFF006D84)),
      AppUser(name: 'Karim Bensalah', firstName: 'Karim', lastName: 'Bensalah', username: 'karim.b', email: 'karim.b@antbms.dz', password: 'karim123', role: 'supervisor', status: 'active', lastLogin: now.subtract(const Duration(hours: 2)), avatarColor: const Color(0xFF4CAF50)),
      AppUser(name: 'Amina Rachedi', firstName: 'Amina', lastName: 'Rachedi', username: 'amina.r', email: 'amina.r@antbms.dz', password: 'amina123', role: 'supervisor', status: 'active', lastLogin: now.subtract(const Duration(hours: 6)), avatarColor: const Color(0xFFE91E63)),
      AppUser(name: 'Youcef Slimani', firstName: 'Youcef', lastName: 'Slimani', username: 'youcef.s', email: 'youcef.s@antbms.dz', password: 'youcef123', role: 'employee', status: 'active', lastLogin: now.subtract(const Duration(hours: 1)), avatarColor: const Color(0xFF2196F3)),
      AppUser(name: 'Fatima Zahra', firstName: 'Fatima', lastName: 'Zahra', username: 'fatima.z', email: 'fatima.z@antbms.dz', password: 'fatima123', role: 'employee', status: 'active', lastLogin: now.subtract(const Duration(days: 1)), avatarColor: const Color(0xFF9C27B0)),
      AppUser(name: 'Mohamed Aissani', firstName: 'Mohamed', lastName: 'Aissani', username: 'mohamed.a', email: 'mohamed.a@antbms.dz', password: 'mohamed123', role: 'employee', status: 'inactive', active: false, lastLogin: now.subtract(const Duration(days: 14)), avatarColor: const Color(0xFF795548)),
      AppUser(name: 'Sara Belkacem', firstName: 'Sara', lastName: 'Belkacem', username: 'sara.b', email: 'sara.b@antbms.dz', password: 'sara123', role: 'employee', status: 'active', lastLogin: now.subtract(const Duration(hours: 3)), avatarColor: const Color(0xFFFF9800)),
      AppUser(name: 'Ali Djeradi', firstName: 'Ali', lastName: 'Djeradi', username: 'ali.d', email: 'ali.d@antbms.dz', password: 'ali123', role: 'employee', status: 'suspended', accountNonLocked: false, lastLogin: now.subtract(const Duration(days: 30)), avatarColor: const Color(0xFF607D8B)),
    ];
  }

  // ── Products ──
  static List<Product> generateProducts() {
    return [
      Product(sku: 'ELC-001', name: 'Câble H07V-U 2.5mm²', category: 'Électrique', quantity: 320, minStock: 50, maxStock: 500, locationLabel: 'A-01', price: 45.0),
      Product(sku: 'ELC-002', name: 'Disjoncteur 16A', category: 'Électrique', quantity: 85, minStock: 20, maxStock: 200, locationLabel: 'A-02', price: 890.0),
      Product(sku: 'ELC-003', name: 'Prise murale double', category: 'Électrique', quantity: 12, minStock: 30, maxStock: 300, locationLabel: 'A-03', price: 250.0),
      Product(sku: 'HDW-001', name: 'Boulon M10x60 (x100)', category: 'Quincaillerie', quantity: 450, minStock: 100, maxStock: 1000, locationLabel: 'B-01', price: 320.0),
      Product(sku: 'HDW-002', name: 'Vis autoperceuse 4.8x25', category: 'Quincaillerie', quantity: 0, minStock: 50, maxStock: 500, locationLabel: 'B-02', price: 180.0),
      Product(sku: 'SAF-001', name: 'Casque de chantier', category: 'Sécurité', quantity: 67, minStock: 15, maxStock: 100, locationLabel: 'C-01', price: 1200.0),
      Product(sku: 'SAF-002', name: 'Gants isolants CL2', category: 'Sécurité', quantity: 8, minStock: 10, maxStock: 80, locationLabel: 'C-02', price: 2500.0),
      Product(sku: 'TLS-001', name: 'Perceuse sans fil 18V', category: 'Outillage', quantity: 24, minStock: 5, maxStock: 40, locationLabel: 'D-01', price: 8500.0),
      Product(sku: 'TLS-002', name: 'Mètre laser 50m', category: 'Outillage', quantity: 31, minStock: 8, maxStock: 50, locationLabel: 'D-02', price: 4200.0),
      Product(sku: 'PKG-001', name: 'Carton 60x40x30', category: 'Emballage', quantity: 1200, minStock: 200, maxStock: 2000, locationLabel: 'E-01', price: 85.0),
      Product(sku: 'PKG-002', name: 'Film étirable 500mm', category: 'Emballage', quantity: 45, minStock: 20, maxStock: 100, locationLabel: 'E-02', price: 350.0),
      Product(sku: 'ELC-004', name: 'Tableau électrique 13M', category: 'Électrique', quantity: 18, minStock: 5, maxStock: 30, locationLabel: 'A-04', price: 3200.0),
      Product(sku: 'HDW-003', name: 'Cheville chimique M12', category: 'Quincaillerie', quantity: 95, minStock: 30, maxStock: 200, locationLabel: 'B-03', price: 550.0),
      Product(sku: 'TLS-003', name: 'Niveau laser rotatif', category: 'Outillage', quantity: 6, minStock: 3, maxStock: 15, locationLabel: 'D-03', price: 15000.0),
      Product(sku: 'SAF-003', name: 'Harnais antichute', category: 'Sécurité', quantity: 22, minStock: 10, maxStock: 50, locationLabel: 'C-03', price: 4800.0),
    ];
  }

  // ── Orders ──
  static List<OrderEntry> generateOrders() {
    final now = DateTime.now();
    return [
      OrderEntry(orderNumber: 'ORD-2401', customer: 'Sonelgaz Alger', items: 12, total: 45200, status: 'processing', createdAt: now.subtract(const Duration(hours: 1))),
      OrderEntry(orderNumber: 'ORD-2400', customer: 'COSIDER TP', items: 8, total: 28500, status: 'shipped', createdAt: now.subtract(const Duration(hours: 3))),
      OrderEntry(orderNumber: 'ORD-2399', customer: 'ETRHB Haddad', items: 25, total: 112000, status: 'delivered', createdAt: now.subtract(const Duration(hours: 8))),
      OrderEntry(orderNumber: 'ORD-2398', customer: 'Condor Electronics', items: 5, total: 18700, status: 'processing', createdAt: now.subtract(const Duration(hours: 12))),
      OrderEntry(orderNumber: 'ORD-2397', customer: 'ENIEM Tizi Ouzou', items: 15, total: 67300, status: 'shipped', createdAt: now.subtract(const Duration(days: 1))),
      OrderEntry(orderNumber: 'ORD-2396', customer: 'Groupe Cevital', items: 30, total: 185000, status: 'delivered', createdAt: now.subtract(const Duration(days: 1, hours: 6))),
      OrderEntry(orderNumber: 'ORD-2395', customer: 'SNVI Rouiba', items: 3, total: 9400, status: 'cancelled', createdAt: now.subtract(const Duration(days: 2))),
      OrderEntry(orderNumber: 'ORD-2394', customer: 'Naftal Distribution', items: 18, total: 74200, status: 'delivered', createdAt: now.subtract(const Duration(days: 2, hours: 5))),
    ];
  }

  // ── AI Decisions ──
  static List<AiDecision> generateAiDecisions() {
    final now = DateTime.now();
    return [
      AiDecision(action: 'reorder', description: 'Auto-reorder triggered for Câble H07V-U — stock below threshold', timestamp: now.subtract(const Duration(minutes: 15)), status: 'approved', confidence: 0.94, userName: 'AI Engine'),
      AiDecision(action: 'relocate', description: 'Suggest moving Disjoncteur 16A to Zone A-05 for faster picking', timestamp: now.subtract(const Duration(hours: 1)), status: 'pending', confidence: 0.87, userName: 'AI Engine'),
      AiDecision(action: 'alert', description: 'Demand spike predicted for Casque de chantier — +40% next week', timestamp: now.subtract(const Duration(hours: 2)), status: 'approved', confidence: 0.91, userName: 'AI Engine'),
      AiDecision(action: 'optimize', description: 'Route optimization: reduce picking distance by 18% on Floor 1', timestamp: now.subtract(const Duration(hours: 4)), status: 'overridden', confidence: 0.82, userName: 'Karim Bensalah'),
      AiDecision(action: 'reorder', description: 'Auto-reorder for Vis autoperceuse — zero stock detected', timestamp: now.subtract(const Duration(hours: 6)), status: 'approved', confidence: 0.98, userName: 'AI Engine'),
      AiDecision(action: 'alert', description: 'Storage utilization critical on Floor 3 — 92% capacity', timestamp: now.subtract(const Duration(hours: 8)), status: 'approved', confidence: 0.96, userName: 'AI Engine'),
      AiDecision(action: 'relocate', description: 'Consolidate slow-moving items from Zone D to Zone E', timestamp: now.subtract(const Duration(hours: 12)), status: 'overridden', confidence: 0.79, userName: 'Amina Rachedi'),
      AiDecision(action: 'optimize', description: 'Batch processing recommended for 5 pending shipments', timestamp: now.subtract(const Duration(days: 1)), status: 'approved', confidence: 0.88, userName: 'AI Engine'),
    ];
  }

  // ── Audit Logs ──
  static List<AuditLogEntry> generateAuditLogs() {
    final now = DateTime.now();
    return [
      AuditLogEntry(action: 'login', description: 'Admin logged in from Chrome/Windows', timestamp: now.subtract(const Duration(minutes: 5)), userName: 'Admin Principal', ipAddress: '192.168.1.100'),
      AuditLogEntry(action: 'update', description: 'Updated stock quantity for ELC-001', timestamp: now.subtract(const Duration(minutes: 30)), userName: 'Karim Bensalah', ipAddress: '192.168.1.105', beforeData: {'quantity': '280'}, afterData: {'quantity': '320'}),
      AuditLogEntry(action: 'override', description: 'Override AI reorder suggestion for HDW-002', timestamp: now.subtract(const Duration(hours: 1)), userName: 'Amina Rachedi', ipAddress: '192.168.1.108', beforeData: {'action': 'reorder', 'qty': '200'}, afterData: {'action': 'cancelled', 'reason': 'Supplier delay'}),
      AuditLogEntry(action: 'create', description: 'New product added: Niveau laser rotatif (TLS-003)', timestamp: now.subtract(const Duration(hours: 2)), userName: 'Admin Principal', ipAddress: '192.168.1.100'),
      AuditLogEntry(action: 'update', description: 'Zone B-03 status changed to Partial', timestamp: now.subtract(const Duration(hours: 3)), userName: 'Youcef Slimani', ipAddress: '192.168.1.112'),
      AuditLogEntry(action: 'delete', description: 'Removed expired product batch PKG-OLD-001', timestamp: now.subtract(const Duration(hours: 5)), userName: 'Admin Principal', ipAddress: '192.168.1.100', beforeData: {'sku': 'PKG-OLD-001', 'name': 'Carton ancien modèle', 'qty': '0'}),
      AuditLogEntry(action: 'create', description: 'New user created: Sara Belkacem (employee)', timestamp: now.subtract(const Duration(hours: 8)), userName: 'Admin Principal', ipAddress: '192.168.1.100'),
      AuditLogEntry(action: 'update', description: 'Warehouse Floor 2 dimensions updated to 60×35m', timestamp: now.subtract(const Duration(hours: 12)), userName: 'Admin Principal', ipAddress: '192.168.1.100', beforeData: {'width': '55', 'height': '30'}, afterData: {'width': '60', 'height': '35'}),
      AuditLogEntry(action: 'override', description: 'Override AI route optimization on Floor 1', timestamp: now.subtract(const Duration(days: 1)), userName: 'Karim Bensalah', ipAddress: '192.168.1.105'),
      AuditLogEntry(action: 'login', description: 'Manager login from mobile device', timestamp: now.subtract(const Duration(days: 1, hours: 2)), userName: 'Amina Rachedi', ipAddress: '10.0.0.45'),
      AuditLogEntry(action: 'update', description: 'User Ali Djeradi status changed to suspended', timestamp: now.subtract(const Duration(days: 2)), userName: 'Admin Principal', ipAddress: '192.168.1.100', beforeData: {'status': 'active'}, afterData: {'status': 'suspended'}),
    ];
  }

  // ── Stock Movement Time-Series (12 months) ──
  static List<ChartPoint> generateStockMovements() {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final values = [420, 380, 510, 470, 590, 620, 580, 650, 710, 680, 740, 790];
    return List.generate(12, (i) => ChartPoint(months[i], values[i].toDouble()));
  }

  // ── Inventory Breakdown (by category) ──
  static List<ChartPoint> generateInventoryBreakdown() {
    return [
      const ChartPoint('Électrique', 435, AppColors.primary),
      const ChartPoint('Quincaillerie', 545, AppColors.aiBlue),
      const ChartPoint('Sécurité', 97, AppColors.accent),
      const ChartPoint('Outillage', 61, AppColors.success),
      const ChartPoint('Emballage', 1245, AppColors.archived),
    ];
  }

  // ── Dashboard metrics ──
  static Map<String, dynamic> dashboardMetrics() {
    return {
      'totalStock': 2383,
      'activeOrders': 4,
      'overrides': 3,
      'aiAccuracy': 91.2,
      'systemHealth': 98.5,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
//  TRANSACTION (matches data dictionary: transactions table)
// ═══════════════════════════════════════════════════════════════

class Transaction {
  final String idTransaction;
  String typeTransaction; // RECEIPT, MOVE, PICK, ADJUSTMENT
  String referenceTransaction;
  DateTime creeLe;
  String creeParIdUtilisateur;
  String statut; // DRAFT, CONFIRMED, CANCELLED
  String notes;
  List<TransactionLine> lines;

  Color get statutColor {
    switch (statut) {
      case 'CONFIRMED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
      default: return AppColors.accent;
    }
  }

  Transaction({
    String? idTransaction,
    required this.typeTransaction,
    required this.referenceTransaction,
    DateTime? creeLe,
    required this.creeParIdUtilisateur,
    this.statut = 'DRAFT',
    this.notes = '',
    List<TransactionLine>? lines,
  })  : idTransaction = idTransaction ?? _uuid.v4(),
        creeLe = creeLe ?? DateTime.now(),
        lines = lines ?? [];
}

// ═══════════════════════════════════════════════════════════════
//  TRANSACTION LINE (matches data dictionary: lignes_transaction)
// ═══════════════════════════════════════════════════════════════

class TransactionLine {
  final String idTransaction;
  int noLigne;
  String idProduit;
  int quantite;
  String? emplacementSource;
  String? emplacementDestination;
  String? lotSerie;
  String? codeMotif; // COUNT, DAMAGED, EXPIRY

  TransactionLine({
    required this.idTransaction,
    required this.noLigne,
    required this.idProduit,
    required this.quantite,
    this.emplacementSource,
    this.emplacementDestination,
    this.lotSerie,
    this.codeMotif,
  });
}

// ═══════════════════════════════════════════════════════════════
//  STOCK MOVEMENT (audit trail for FR-25, FR-26)
// ═══════════════════════════════════════════════════════════════

class StockMovement {
  final String id;
  String sku;
  String productName;
  String type; // receipt, transfer, pick, adjustment, delivery
  int quantity;
  String fromLocation;
  String toLocation;
  DateTime timestamp;
  String performedBy;
  String? transactionRef;

  Color get typeColor {
    switch (type) {
      case 'receipt': return AppColors.success;
      case 'transfer': return AppColors.aiBlue;
      case 'pick': return AppColors.primary;
      case 'adjustment': return AppColors.accent;
      case 'delivery': return const Color(0xFF9C27B0);
      default: return AppColors.archived;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'receipt': return Icons.download_rounded;
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'pick': return Icons.shopping_basket_rounded;
      case 'adjustment': return Icons.tune_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      default: return Icons.info_rounded;
    }
  }

  StockMovement({
    String? id,
    required this.sku,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.fromLocation,
    required this.toLocation,
    DateTime? timestamp,
    required this.performedBy,
    this.transactionRef,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  OVERRIDE RECORD (FR-7, FR-8, FR-46, FR-47)
// ═══════════════════════════════════════════════════════════════

class OverrideRecord {
  final String id;
  String originalDecisionId;
  String originalType;    // AI, Supervisor
  String originalAction;  // reorder, relocate, route, preparation, picking
  String description;
  String justification;
  String overriddenBy;
  String overriddenByRole; // admin, supervisor
  DateTime timestamp;
  Map<String, String>? originalValues;
  Map<String, String>? newValues;

  Color get roleColor {
    switch (overriddenByRole) {
      case 'admin': return AppColors.primaryDark;
      case 'supervisor': return AppColors.aiBlue;
      default: return AppColors.archived;
    }
  }

  OverrideRecord({
    String? id,
    required this.originalDecisionId,
    required this.originalType,
    required this.originalAction,
    required this.description,
    required this.justification,
    required this.overriddenBy,
    this.overriddenByRole = 'admin',
    DateTime? timestamp,
    this.originalValues,
    this.newValues,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  SYSTEM CHECK RESULT (for system integrity screen)
// ═══════════════════════════════════════════════════════════════

class SystemCheckResult {
  final String id;
  String category; // stock, users, transactions, locations
  String checkName;
  String status; // passed, warning, failed
  String details;
  DateTime lastRun;
  int? affectedRecords;

  Color get statusColor {
    switch (status) {
      case 'passed': return AppColors.success;
      case 'warning': return AppColors.accent;
      case 'failed': return AppColors.error;
      default: return AppColors.archived;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'passed': return Icons.check_circle_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'failed': return Icons.error_rounded;
      default: return Icons.help_rounded;
    }
  }

  SystemCheckResult({
    String? id,
    required this.category,
    required this.checkName,
    required this.status,
    required this.details,
    DateTime? lastRun,
    this.affectedRecords,
  })  : id = id ?? _uuid.v4(),
        lastRun = lastRun ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════
//  MOCK AUTH SERVICE
// ═══════════════════════════════════════════════════════════════

class MockAuthService {
  static final List<AppUser> users = MockDataGenerator.generateUsers();

  static AppUser? authenticate(String identifier, String password) {
    final input = identifier.trim().toLowerCase();
    for (final u in users) {
      final emailMatch = u.email.toLowerCase() == input;
      final usernameMatch = u.username.toLowerCase() == input;
      if ((emailMatch || usernameMatch) && u.password == password) {
        return u;
      }
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
//  MOCK WAREHOUSE DATA (shared state for admin screens)
// ═══════════════════════════════════════════════════════════════

class MockWarehouseState {
  // Singleton lists for shared state across screens
  static final List<Transaction> transactions = _generateTransactions();
  static final List<StockMovement> stockMovements = _generateStockMovements();
  static final List<OverrideRecord> overrides = _generateOverrides();
  static final List<SystemCheckResult> systemChecks = _generateSystemChecks();

  static List<Transaction> _generateTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        idTransaction: 'T0001',
        typeTransaction: 'RECEIPT',
        referenceTransaction: 'RCV-2026-0001',
        creeLe: now.subtract(const Duration(hours: 2)),
        creeParIdUtilisateur: 'U001',
        statut: 'CONFIRMED',
        notes: 'Inbound from supplier X',
        lines: [
          TransactionLine(idTransaction: 'T0001', noLigne: 1, idProduit: 'P001', quantite: 120, emplacementDestination: 'B7-N1-C7', lotSerie: 'BATCH-24A'),
          TransactionLine(idTransaction: 'T0001', noLigne: 2, idProduit: 'P002', quantite: 60, emplacementDestination: 'B7-N1-C8'),
        ],
      ),
      Transaction(
        idTransaction: 'T0002',
        typeTransaction: 'MOVE',
        referenceTransaction: 'TRF-2026-0012',
        creeLe: now.subtract(const Duration(hours: 4)),
        creeParIdUtilisateur: 'U003',
        statut: 'CONFIRMED',
        notes: 'Transfer to floor 2 storage',
        lines: [
          TransactionLine(idTransaction: 'T0002', noLigne: 1, idProduit: 'P003', quantite: 45, emplacementSource: 'B7-N1-C2', emplacementDestination: 'B7-N2-D5'),
        ],
      ),
      Transaction(
        idTransaction: 'T0003',
        typeTransaction: 'PICK',
        referenceTransaction: 'PCK-2026-0008',
        creeLe: now.subtract(const Duration(hours: 6)),
        creeParIdUtilisateur: 'U004',
        statut: 'CONFIRMED',
        notes: 'Pick for delivery order',
        lines: [
          TransactionLine(idTransaction: 'T0003', noLigne: 1, idProduit: 'P001', quantite: 30, emplacementSource: 'B7-N1-C7', emplacementDestination: 'B7-0A-02-01'),
          TransactionLine(idTransaction: 'T0003', noLigne: 2, idProduit: 'P005', quantite: 15, emplacementSource: 'B7-N3-D8', emplacementDestination: 'B7-0A-03-01'),
        ],
      ),
      Transaction(
        idTransaction: 'T0004',
        typeTransaction: 'ADJUSTMENT',
        referenceTransaction: 'ADJ-2026-0003',
        creeLe: now.subtract(const Duration(hours: 8)),
        creeParIdUtilisateur: 'U001',
        statut: 'CONFIRMED',
        notes: 'Inventory count correction',
        lines: [
          TransactionLine(idTransaction: 'T0004', noLigne: 1, idProduit: 'P004', quantite: -5, emplacementSource: 'B7-N2-C3', codeMotif: 'DAMAGED'),
        ],
      ),
      Transaction(
        idTransaction: 'T0005',
        typeTransaction: 'RECEIPT',
        referenceTransaction: 'RCV-2026-0002',
        creeLe: now.subtract(const Duration(days: 1)),
        creeParIdUtilisateur: 'U003',
        statut: 'DRAFT',
        notes: 'Pending receipt from supplier Y',
        lines: [
          TransactionLine(idTransaction: 'T0005', noLigne: 1, idProduit: 'P006', quantite: 200, emplacementDestination: 'B7-N1-C5'),
        ],
      ),
      Transaction(
        idTransaction: 'T0006',
        typeTransaction: 'PICK',
        referenceTransaction: 'PCK-2026-0009',
        creeLe: now.subtract(const Duration(days: 1, hours: 3)),
        creeParIdUtilisateur: 'U005',
        statut: 'CANCELLED',
        notes: 'Cancelled — customer order withdrawn',
      ),
    ];
  }

  static List<StockMovement> _generateStockMovements() {
    final now = DateTime.now();
    return [
      StockMovement(sku: 'ELC-001', productName: 'Câble H07V-U 2.5mm²', type: 'receipt', quantity: 120, fromLocation: 'SUPPLIER', toLocation: 'B7-N1-C7', timestamp: now.subtract(const Duration(hours: 1)), performedBy: 'Youcef Slimani', transactionRef: 'RCV-2026-0001'),
      StockMovement(sku: 'ELC-002', productName: 'Disjoncteur 16A', type: 'transfer', quantity: 30, fromLocation: 'B7-N1-C8', toLocation: 'B7-N2-D5', timestamp: now.subtract(const Duration(hours: 2)), performedBy: 'Mohamed Aissani', transactionRef: 'TRF-2026-0012'),
      StockMovement(sku: 'ELC-001', productName: 'Câble H07V-U 2.5mm²', type: 'pick', quantity: 50, fromLocation: 'B7-N1-C7', toLocation: 'B7-0A-02-01', timestamp: now.subtract(const Duration(hours: 3)), performedBy: 'Fatima Zahra', transactionRef: 'PCK-2026-0008'),
      StockMovement(sku: 'HDW-001', productName: 'Boulon M10x60 (x100)', type: 'delivery', quantity: 80, fromLocation: 'B7-0A-02-01', toLocation: 'EXPEDITION', timestamp: now.subtract(const Duration(hours: 4)), performedBy: 'Sara Belkacem', transactionRef: 'DLV-2026-0015'),
      StockMovement(sku: 'HDW-002', productName: 'Vis autoperceuse 4.8x25', type: 'adjustment', quantity: -5, fromLocation: 'B7-N2-C3', toLocation: '—', timestamp: now.subtract(const Duration(hours: 6)), performedBy: 'Admin Principal', transactionRef: 'ADJ-2026-0003'),
      StockMovement(sku: 'SAF-001', productName: 'Casque de chantier', type: 'receipt', quantity: 40, fromLocation: 'SUPPLIER', toLocation: 'B7-N3-E2', timestamp: now.subtract(const Duration(hours: 8)), performedBy: 'Youcef Slimani', transactionRef: 'RCV-2026-0003'),
      StockMovement(sku: 'TLS-001', productName: 'Perceuse sans fil 18V', type: 'pick', quantity: 5, fromLocation: 'B7-N2-D1', toLocation: 'B7-0A-04-01', timestamp: now.subtract(const Duration(hours: 10)), performedBy: 'Mohamed Aissani', transactionRef: 'PCK-2026-0010'),
      StockMovement(sku: 'ELC-003', productName: 'Prise murale double', type: 'transfer', quantity: 60, fromLocation: 'B7-N1-A3', toLocation: 'B7-N3-C4', timestamp: now.subtract(const Duration(hours: 12)), performedBy: 'Fatima Zahra', transactionRef: 'TRF-2026-0013'),
      StockMovement(sku: 'PKG-001', productName: 'Carton 60x40x30', type: 'delivery', quantity: 200, fromLocation: 'B7-0A-05-01', toLocation: 'EXPEDITION', timestamp: now.subtract(const Duration(days: 1)), performedBy: 'Sara Belkacem', transactionRef: 'DLV-2026-0016'),
      StockMovement(sku: 'SAF-002', productName: 'Gants isolants CL2', type: 'receipt', quantity: 25, fromLocation: 'SUPPLIER', toLocation: 'B7-N1-C2', timestamp: now.subtract(const Duration(days: 1, hours: 2)), performedBy: 'Youcef Slimani', transactionRef: 'RCV-2026-0004'),
      StockMovement(sku: 'ELC-004', productName: 'Tableau électrique 13M', type: 'pick', quantity: 8, fromLocation: 'B7-N2-A4', toLocation: 'B7-0A-01-02', timestamp: now.subtract(const Duration(days: 1, hours: 5)), performedBy: 'Mohamed Aissani', transactionRef: 'PCK-2026-0011'),
      StockMovement(sku: 'HDW-003', productName: 'Cheville chimique M12', type: 'adjustment', quantity: 10, fromLocation: '—', toLocation: 'B7-N1-B3', timestamp: now.subtract(const Duration(days: 2)), performedBy: 'Admin Principal', transactionRef: 'ADJ-2026-0004'),
    ];
  }

  static List<OverrideRecord> _generateOverrides() {
    final now = DateTime.now();
    return [
      OverrideRecord(
        originalDecisionId: 'ai-001',
        originalType: 'AI',
        originalAction: 'route',
        description: 'Override AI picking route on Floor 1 — shorter manual path identified',
        justification: 'Manual inspection revealed blocked aisle on AI-suggested route. Using alternative path via D-row.',
        overriddenBy: 'Karim Bensalah',
        overriddenByRole: 'supervisor',
        timestamp: now.subtract(const Duration(hours: 3)),
        originalValues: {'route': 'A3 → C7 → E9 → Expedition', 'distance': '45m'},
        newValues: {'route': 'A3 → D4 → E9 → Expedition', 'distance': '38m'},
      ),
      OverrideRecord(
        originalDecisionId: 'ai-002',
        originalType: 'AI',
        originalAction: 'reorder',
        description: 'Cancel AI auto-reorder for HDW-002 — supplier delivery delay',
        justification: 'Supplier confirmed 2-week delay. Cancelling auto-reorder and sourcing from alternative.',
        overriddenBy: 'Admin Principal',
        overriddenByRole: 'admin',
        timestamp: now.subtract(const Duration(hours: 6)),
        originalValues: {'action': 'reorder', 'quantity': '200', 'supplier': 'Supplier A'},
        newValues: {'action': 'cancelled', 'reason': 'Supplier delay — sourcing alternative'},
      ),
      OverrideRecord(
        originalDecisionId: 'ai-003',
        originalType: 'AI',
        originalAction: 'relocate',
        description: 'Override AI storage suggestion — keep slow-movers in Zone D',
        justification: 'Consolidation would disrupt ongoing inventory count. Postpone until next week.',
        overriddenBy: 'Amina Rachedi',
        overriddenByRole: 'supervisor',
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      OverrideRecord(
        originalDecisionId: 'sv-001',
        originalType: 'Supervisor',
        originalAction: 'preparation',
        description: 'Admin override of Supervisor preparation order — added urgent items',
        justification: 'Priority customer order received. Adding 3 additional SKUs to preparation batch.',
        overriddenBy: 'Admin Principal',
        overriddenByRole: 'admin',
        timestamp: now.subtract(const Duration(days: 1)),
        originalValues: {'items': '5 SKUs', 'priority': 'normal'},
        newValues: {'items': '8 SKUs', 'priority': 'urgent'},
      ),
      OverrideRecord(
        originalDecisionId: 'ai-004',
        originalType: 'AI',
        originalAction: 'picking',
        description: 'Override AI picking location — damaged rack detected',
        justification: 'Rack B7-N3-D8 reported structural damage. Rerouting pick to B7-N3-D6.',
        overriddenBy: 'Admin Principal',
        overriddenByRole: 'admin',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        originalValues: {'location': 'B7-N3-D8'},
        newValues: {'location': 'B7-N3-D6'},
      ),
    ];
  }

  static List<SystemCheckResult> _generateSystemChecks() {
    final now = DateTime.now();
    return [
      SystemCheckResult(category: 'stock', checkName: 'Negative Stock Detection', status: 'passed', details: 'No products have negative stock quantities.', lastRun: now.subtract(const Duration(minutes: 5)), affectedRecords: 0),
      SystemCheckResult(category: 'stock', checkName: 'Stock vs. Transaction Consistency', status: 'passed', details: 'All stock levels match transaction ledger totals.', lastRun: now.subtract(const Duration(minutes: 5)), affectedRecords: 0),
      SystemCheckResult(category: 'stock', checkName: 'Orphan Stock Entries', status: 'warning', details: '2 stock entries reference deleted products.', lastRun: now.subtract(const Duration(minutes: 5)), affectedRecords: 2),
      SystemCheckResult(category: 'locations', checkName: 'Unique Location Codes', status: 'passed', details: 'All location codes are unique across warehouses.', lastRun: now.subtract(const Duration(minutes: 10)), affectedRecords: 0),
      SystemCheckResult(category: 'locations', checkName: 'Location Capacity Check', status: 'warning', details: '3 locations exceed 95% capacity threshold.', lastRun: now.subtract(const Duration(minutes: 10)), affectedRecords: 3),
      SystemCheckResult(category: 'users', checkName: 'Duplicate User Detection', status: 'passed', details: 'No duplicate usernames or emails detected.', lastRun: now.subtract(const Duration(minutes: 15)), affectedRecords: 0),
      SystemCheckResult(category: 'users', checkName: 'Inactive User Audit', status: 'warning', details: '1 user inactive for over 14 days without justification.', lastRun: now.subtract(const Duration(minutes: 15)), affectedRecords: 1),
      SystemCheckResult(category: 'transactions', checkName: 'Draft Transaction Age', status: 'warning', details: '1 draft transaction is over 24 hours old.', lastRun: now.subtract(const Duration(minutes: 20)), affectedRecords: 1),
      SystemCheckResult(category: 'transactions', checkName: 'Transaction Atomicity', status: 'passed', details: 'All confirmed transactions have complete line items.', lastRun: now.subtract(const Duration(minutes: 20)), affectedRecords: 0),
      SystemCheckResult(category: 'transactions', checkName: 'Override Audit Trail', status: 'passed', details: 'All overrides have justification and audit log entries.', lastRun: now.subtract(const Duration(minutes: 25)), affectedRecords: 0),
      SystemCheckResult(category: 'stock', checkName: 'Reorder Point Alert', status: 'failed', details: '2 SKUs below minimum stock with no open purchase orders.', lastRun: now.subtract(const Duration(minutes: 30)), affectedRecords: 2),
      SystemCheckResult(category: 'locations', checkName: 'Active Location Validation', status: 'passed', details: 'All active locations belong to active warehouses.', lastRun: now.subtract(const Duration(minutes: 30)), affectedRecords: 0),
    ];
  }
}
