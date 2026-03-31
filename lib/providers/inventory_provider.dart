import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';

class InventoryProvider extends ChangeNotifier {
  final String baseUrl =
      'https://pao.usjr.edu.ph/store/demo/public'; // Replace with actual API URL

  List<Package> _packages = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Package> get packages => _packages;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Helper to safely extract the payload from various API response formats
  dynamic _extractPayload(dynamic decoded) {
    if (decoded == null) return null;
    if (decoded is! Map) return decoded;

    // Look for common "data" or "item/package" keys
    if (decoded.containsKey('data')) {
      final data = decoded['data'];
      // Handle nested Laravel pagination: { "data": { "data": [...] } }
      if (data is Map && data.containsKey('data')) return data['data'];
      return data;
    }
    if (decoded.containsKey('package')) return decoded['package'];
    if (decoded.containsKey('packages')) return decoded['packages'];
    if (decoded.containsKey('items')) return decoded['items'];

    return decoded;
  }

  dynamic _safeDecode(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (_) {
      return null;
    }
  }

  // GET /api/dashboard - Get dashboard statistics
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/dashboard'));
      if (response.statusCode == 200) {
        final decoded = _safeDecode(response);
        final payload = _extractPayload(decoded);
        if (payload is Map<String, dynamic>) {
          _dashboardStats = payload;
        } else if (payload is Map) {
          _dashboardStats = Map<String, dynamic>.from(payload);
        }
        _errorMessage = null;
      } else {
        _handleError(response);
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/packages - List all packages
  Future<void> fetchPackages() async {
    _setLoading(true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/packages'));
      if (response.statusCode == 200) {
        final decoded = _safeDecode(response);
        final payload = _extractPayload(decoded);

        List<dynamic> data = [];
        if (payload is List) {
          data = payload;
        } else if (payload is Map && payload.containsKey('data')) {
          final subData = payload['data'];
          if (subData is List) data = subData;
        }

        _packages = data.map((json) => Package.fromJson(json)).toList();
        _errorMessage = null;
      } else {
        _handleError(response);
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
    } finally {
      _setLoading(false);
    }
  }

  // POST /api/packages - Create a new package
  Future<bool> createPackage(Map<String, dynamic> packageData) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/packages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(packageData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint(
          '✅ [API] Package created successfully. Response: ${response.body}',
        );
        await fetchPackages(); // Refresh list
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/packages/{id}/events - Get scan events for a package
  Future<List<PackageEvent>> fetchPackageEvents(int packageId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/packages/$packageId/events'),
      );
      if (response.statusCode == 200) {
        final decoded = _safeDecode(response);
        final payload = _extractPayload(decoded);

        List<dynamic> data = [];
        if (payload is List) {
          data = payload;
        }

        return data.map((json) => PackageEvent.fromJson(json)).toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return [];
    }
  }

  // POST /api/packages/{id}/scan - Record a scan for a specific package ID
  Future<bool> recordScanForPackage(
    int packageId,
    Map<String, dynamic> scanData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/packages/$packageId/scan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(scanData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
    }
  }

  // (Primary for Scanner) POST /api/scans - Record a scan using tracking_number or reference_code
  Future<bool> recordBarcodeScan(String code) async {
    _setLoading(true);
    try {
      // Send as both to be safe
      final body = json.encode({
        'tracking_number': code,
        'reference_code': code,
      });
      debugPrint('POST to /api/scans: $body');
      final response = await http.post(
        Uri.parse('$baseUrl/api/scans'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = null;
        fetchDashboardStats();
        return true;
      } else {
        if (response.statusCode == 422 || response.statusCode == 404) {
          debugPrint('=========================================');
          debugPrint('🚨 UNREGISTERED TRACKING NUMBER: "$code"');
          debugPrint('=========================================');
        }
        debugPrint('Scan failed: ${response.statusCode} - ${response.body}');
        _handleError(response);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e hehe';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/track/{trackingNumber} - Public tracking information
  Future<Package?> trackPackage(String trackingNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/track/$trackingNumber'),
      );
      if (response.statusCode == 200) {
        final decoded = _safeDecode(response);
        final payload = _extractPayload(decoded);
        if (payload is Map<String, dynamic>) {
          return Package.fromJson(payload);
        } else if (payload is Map) {
          return Package.fromJson(Map<String, dynamic>.from(payload));
        }
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(http.Response response) {
    final decoded = _safeDecode(response);

    switch (response.statusCode) {
      case 400:
        _errorMessage = 'Bad Request: ${response.body}';
        break;
      case 422:
        if (decoded is Map && decoded.containsKey('message')) {
          _errorMessage = decoded['message'];
        } else if (decoded is Map && decoded.containsKey('errors')) {
          // Common Laravel validation response
          _errorMessage = 'Validation Error: ${decoded['errors'].toString()}';
        } else {
          _errorMessage = 'Validation Error (422): ${response.body}';
        }
        break;
      case 404:
        _errorMessage = 'Resource not found (404)';
        break;
      case 500:
        _errorMessage = 'Internal Server Error (500)';
        break;
      default:
        _errorMessage = 'Error: ${response.statusCode}';
    }
    notifyListeners();
  }

  // Old scanBarcode method redirected to new API method for compatibility if needed
  void scanBarcode(String code) {
    recordBarcodeScan(code);
  }
}
