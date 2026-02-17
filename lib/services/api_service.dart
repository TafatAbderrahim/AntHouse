import 'dart:convert';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════
//  API SERVICE — Central HTTP client for MobAI Backend
//  Base URL: http://<host>:8080/api
//  All responses wrapped in ApiResponse { success, message, data }
// ═══════════════════════════════════════════════════════════════

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final String? timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.timestamp,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromData != null ? fromData(json['data']) : json['data'] as T?,
      errorCode: json['errorCode'],
      timestamp: json['timestamp'],
    );
  }
}

class ApiService {
  // ── Configuration ──
  // Remote backend host shared across platforms
  static String get _baseUrl {
    // Prefer local backend during development. Use emulator host mapping for Android.
    try {
      if (Platform.isAndroid) {
        // Android emulator accesses host machine via 10.0.2.2
        return 'http://10.0.2.2:8080/api';
      }
      // iOS simulator, desktop and others can use localhost
      return 'http://localhost:8080/api';
    } catch (e) {
      // Fallback to localhost if Platform is not available (web) or any error
      return 'http://localhost:8080/api';
    }
  }

  static String? _accessToken;
  static String? _refreshToken;
  static String? _userId;
  static String? _username;
  static String? _email;
  static String? _firstName;
  static String? _lastName;
  static String? _role;

  // ── Token Management ──
  static void setTokens({
    required String accessToken,
    String? refreshToken,
    String? userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _username = username;
    _email = email;
    _firstName = firstName;
    _lastName = lastName;
    _role = role;
  }

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _username = null;
    _email = null;
    _firstName = null;
    _lastName = null;
    _role = null;
  }

  static String? get accessToken => _accessToken;
  static String? get currentUserId => _userId;
  static String? get currentUsername => _username;
  static String? get currentEmail => _email;
  static String? get currentFirstName => _firstName;
  static String? get currentLastName => _lastName;
  static String? get currentRole => _role;
  static bool get isLoggedIn => _accessToken != null;
  static String get currentFullName => '${_firstName ?? ''} ${_lastName ?? ''}'.trim();

  // ── HTTP Helpers ──
  static HttpClient get _client {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    return client;
  }

  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Generic GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = await client.getUrl(uri);
      _authHeaders.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 401) {
        // Try refresh
        final refreshed = await _tryRefreshToken();
        if (refreshed) return get(endpoint);
        throw ApiException('Session expired. Please log in again.', 401);
      }

      if (body.isEmpty) return {'success': true, 'message': 'OK', 'data': null};
      return json.decode(body) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Cannot connect to server. Check your network.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Generic POST request
  static Future<Map<String, dynamic>> post(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = await client.postUrl(uri);
      _authHeaders.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(json.encode(body));
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) return post(endpoint, body);
        throw ApiException('Session expired. Please log in again.', 401);
      }

      if (responseBody.isEmpty) return {'success': true, 'message': 'OK', 'data': null};
      return json.decode(responseBody) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Cannot connect to server. Check your network.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Generic PUT request
  static Future<Map<String, dynamic>> put(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = await client.putUrl(uri);
      _authHeaders.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(json.encode(body));
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) return put(endpoint, body);
        throw ApiException('Session expired. Please log in again.', 401);
      }

      if (responseBody.isEmpty) return {'success': true, 'message': 'OK', 'data': null};
      return json.decode(responseBody) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Cannot connect to server. Check your network.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  /// Generic DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = await client.deleteUrl(uri);
      _authHeaders.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) return delete(endpoint);
        throw ApiException('Session expired. Please log in again.', 401);
      }

      if (responseBody.isEmpty) return {'success': true, 'message': 'OK', 'data': null};
      return json.decode(responseBody) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Cannot connect to server. Check your network.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // ── Token Refresh ──
  static Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl/auth/refresh?refreshToken=$_refreshToken');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['success'] == true && data['data'] != null) {
          final authData = data['data'];
          _accessToken = authData['accessToken'];
          _refreshToken = authData['refreshToken'] ?? _refreshToken;
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ═══════════════════════════════════════════════════════════════
  //  AUTH ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(String login, String password) async {
    final result = await post('/auth/login', {
      'login': login,
      'password': password,
    });

    if (result['success'] == true && result['data'] != null) {
      final d = result['data'];
      setTokens(
        accessToken: d['accessToken'] ?? '',
        refreshToken: d['refreshToken'],
        userId: d['userId']?.toString(),
        username: d['username'],
        email: d['email'],
        firstName: d['firstName'],
        lastName: d['lastName'],
        role: d['role'],
      );
    }
    return result;
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (_) {}
    clearTokens();
  }

  // ═══════════════════════════════════════════════════════════════
  //  USER ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getUsers() async {
    final result = await get('/users');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getUser(String id) async {
    final result = await get('/users/$id');
    if (result['success'] == true) return result['data'];
    return null;
  }

  // Admin user management
  static Future<Map<String, dynamic>> getAdminUsers({String? role, bool? active, int page = 0, int size = 50}) async {
    final params = <String>[];
    if (role != null) params.add('role=$role');
    if (active != null) params.add('active=$active');
    params.add('page=$page');
    params.add('size=$size');
    return get('/admin/users?${params.join('&')}');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    return post('/admin/users', userData);
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    return put('/admin/users/$userId', userData);
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    return delete('/admin/users/$userId');
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRODUCT ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getProducts() async {
    final result = await get('products');
    if (result['success'] == true && result['data'] != null) {
      print(result);
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAdminProducts({String? category, bool? active, String? search, int page = 0, int size = 50}) async {
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (active != null) params.add('active=$active');
    if (search != null) params.add('search=$search');
    params.add('page=$page');
    params.add('size=$size');
    final results=await get('/admin/products?${params.join('&')}');
    print(results);
    return results;
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    return post('/admin/products', productData);
  }

  static Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> productData) async {
    return put('/admin/products/$productId', productData);
  }

  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    return delete('/admin/products/$productId');
  }

  // ═══════════════════════════════════════════════════════════════
  //  WAREHOUSE ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getWarehouses() async {
    final result = await get('/warehouses');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAdminWarehouses() async {
    return get('/admin/warehouses');
  }

  static Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    return post('/admin/warehouses', data);
  }

  static Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> data) async {
    return put('/admin/warehouses/$id', data);
  }

  static Future<Map<String, dynamic>> deleteWarehouse(String id) async {
    return delete('/admin/warehouses/$id');
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOCATION ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getLocations() async {
    final result = await get('/locations');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAdminLocations({String? zone, String? type, bool? active, int page = 0, int size = 50}) async {
    final params = <String>[];
    if (zone != null) params.add('zone=$zone');
    if (type != null) params.add('type=$type');
    if (active != null) params.add('active=$active');
    params.add('page=$page');
    params.add('size=$size');
    return get('/admin/locations?${params.join('&')}');
  }

  static Future<Map<String, dynamic>> createLocation(Map<String, dynamic> data) async {
    return post('/admin/locations', data);
  }

  static Future<Map<String, dynamic>> updateLocation(String id, Map<String, dynamic> data) async {
    return put('/admin/locations/$id', data);
  }

  static Future<Map<String, dynamic>> deleteLocation(String id) async {
    return delete('/admin/locations/$id');
  }

  // ═══════════════════════════════════════════════════════════════
  //  TASK ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMyTasks({String? status}) async {
    final endpoint = status != null ? '/tasks/my-tasks?status=$status' : '/tasks/my-tasks';
    final result = await get(endpoint);
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getAllTasks({String? status}) async {
    final endpoint = status != null ? '/tasks?status=$status' : '/tasks';
    final result = await get(endpoint);
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    return post('/tasks/create', taskData);
  }

  static Future<Map<String, dynamic>> getAdminTasks({String? type, String? status, int page = 0, int size = 20}) async {
    final params = <String>[];
    if (type != null) params.add('type=$type');
    if (status != null) params.add('status=$status');
    params.add('page=$page');
    params.add('size=$size');
    return get('/admin/tasks?${params.join('&')}');
  }

  static Future<Map<String, dynamic>> adminCreateTask(Map<String, dynamic> data) async {
    return post('/admin/tasks', data);
  }

  static Future<Map<String, dynamic>> adminUpdateTask(String id, Map<String, dynamic> data) async {
    return put('/admin/tasks/$id', data);
  }

  static Future<Map<String, dynamic>> adminDeleteTask(String id) async {
    return delete('/admin/tasks/$id');
  }

  static Future<Map<String, dynamic>> assignTask(String taskId, String userId) async {
    return put('/tasks/$taskId/assign', {'assignedToId': userId});
  }

  // ═══════════════════════════════════════════════════════════════
  //  INVENTORY / STOCK ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getStockSummary() async {
    return get('/stock/summary');
  }

  static Future<Map<String, dynamic>> getAdminInventorySummary({String? category, bool? lowStockOnly, int page = 0, int size = 50}) async {
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (lowStockOnly == true) params.add('lowStockOnly=true');
    params.add('page=$page');
    params.add('size=$size');
    return get('/admin/inventory/summary?${params.join('&')}');
  }

  static Future<List<dynamic>> getInventoryAlerts() async {
    final result = await get('/admin/inventory/alerts');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> adjustStock(Map<String, dynamic> data) async {
    return post('/admin/inventory/adjustment', data);
  }

  // ═══════════════════════════════════════════════════════════════
  //  ORDER ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getOrders({int page = 0, int size = 20}) async {
    return get('/orders?page=$page&size=$size');
  }

  // ═══════════════════════════════════════════════════════════════
  //  CHARIOT ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getChariots() async {
    final result = await get('/chariots');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAdminChariots({String? status}) async {
    final endpoint = status != null ? '/admin/chariots?status=$status' : '/admin/chariots';
    return get(endpoint);
  }

  static Future<Map<String, dynamic>> createChariot(Map<String, dynamic> data) async {
    return post('/admin/chariots', data);
  }

  static Future<Map<String, dynamic>> updateChariot(String id, Map<String, dynamic> data) async {
    return put('/admin/chariots/$id', data);
  }

  static Future<Map<String, dynamic>> deleteChariot(String id) async {
    return delete('/admin/chariots/$id');
  }

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    return post('/orders', data);
  }

  static Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> data) async {
    return put('/orders/$id', data);
  }

  static Future<Map<String, dynamic>> deleteOrder(String id) async {
    return delete('/orders/$id');
  }

  static Future<List<dynamic>> getStockLedger() async {
    final result = await get('/stock/ledger');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getReportUserProductivity({required String startDate, required String endDate, String? userId}) async {
    final params = 'startDate=$startDate&endDate=$endDate${userId != null ? '&userId=$userId' : ''}';
    return get('/admin/reports/user-productivity?$params');
  }

  static Future<Map<String, dynamic>> getReportStockMovements({required String startDate, required String endDate, String? productId}) async {
    final params = 'startDate=$startDate&endDate=$endDate${productId != null ? '&productId=$productId' : ''}';
    return get('/admin/reports/stock-movements?$params');
  }

  // ═══════════════════════════════════════════════════════════════
  //  DASHBOARD ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    return get('/admin/dashboard');
  }

  static Future<Map<String, dynamic>> getEmployeeDashboard() async {
    return get('/dashboard/employee');
  }

  // ═══════════════════════════════════════════════════════════════
  //  MONITORING ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getActiveOperations() async {
    final result = await get('/monitoring/active-operations');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getEmployeeStatus() async {
    final result = await get('/monitoring/employee-status');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getChariotStatus() async {
    final result = await get('/monitoring/chariot-status');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getWarehouseMonitoring() async {
    return get('/admin/monitoring/warehouse-status');
  }

  // ═══════════════════════════════════════════════════════════════
  //  AI ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getAiDecisions() async {
    final result = await get('/ai-decisions');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getPendingAiDecisions() async {
    final result = await get('/ai-decisions/pending-review');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>> approveAiDecision(String id) async {
    return post('/ai-decisions/$id/approve');
  }

  static Future<Map<String, dynamic>> overrideAiDecision(String id, String reason, String newDecision) async {
    return post('/ai-decisions/$id/override', {
      'reason': reason,
      'newDecision': newDecision,
    });
  }

  static Future<Map<String, dynamic>> getAiHealth() async {
    return get('/ai/health');
  }

  static Future<Map<String, dynamic>> getAiWarehouseState() async {
    return get('/ai/warehouse-state');
  }

  // ═══════════════════════════════════════════════════════════════
  //  DISCREPANCY ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getDiscrepancies() async {
    final result = await get('/discrepancies');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getUnresolvedDiscrepancies() async {
    final result = await get('/discrepancies/unresolved');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as List<dynamic>;
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════
  //  OPERATIONS ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> startOperation(Map<String, dynamic> data) async {
    return post('/operations/start', data);
  }

  static Future<Map<String, dynamic>> executeLine(Map<String, dynamic> data) async {
    return post('/operations/execute-line', data);
  }

  static Future<Map<String, dynamic>> completeOperation(String transactionId, [Map<String, dynamic>? data]) async {
    return post('/operations/$transactionId/complete', data);
  }

  static Future<Map<String, dynamic>> reportIssue(Map<String, dynamic> data) async {
    return post('/operations/report-issue', data);
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCAN ENDPOINT
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> scanBarcode(String barcodeData, String context) async {
    return post('/scan/decode', {
      'barcodeData': barcodeData,
      'scanContext': context,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEALTH CHECK — Use to test connectivity
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> checkHealth() async {
    try {
      final client = _client;
      final uri = Uri.parse('$_baseUrl/test/health');
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getAuditLogs() async {
    return get('/admin/audit-logs');
  }
}

// ═══════════════════════════════════════════════════════════════
//  API EXCEPTION
// ═══════════════════════════════════════════════════════════════

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
