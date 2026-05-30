import 'dart:io' show Platform, SocketException;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/index.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // Production backend on Render
    return 'https://streetwatch.onrender.com/api/v1';
  }

  final SupabaseClient _supabase;

  ApiService(this._supabase);

  /// Get Supabase JWT token from current session
  Future<String?> _getAuthToken() async {
    try {
      final session = _supabase.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Build headers with Supabase JWT bearer token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ AUTH ENDPOINTS ============

  /// Get current user profile from backend
  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw ApiException(_extractErrorDetail(response.body), statusCode: 401);
      } else {
        throw ApiException(
          'Failed to fetch user profile: ${_extractErrorDetail(response.body)}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to get current user: $e');
    }
  }

  // ============ REPORTS ENDPOINTS ============

  /// Get all reports (paginated, filtered)
  Future<List<Report>> getReports({
    int? page,
    int? pageSize,
    String? status,
    String? username,
  }) async {
    try {
      final queryParams = {
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
        ...?status == null ? null : {'status': status},
        ...?username == null ? null : {'username': username},
      };

      final uri = Uri.parse(
        '$baseUrl/reports',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to fetch reports',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get reports: $e');
    }
  }

  Future<List<Report>> getMyReports({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    try {
      final queryParams = {
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
        ...?status == null ? null : {'status': status},
      };

      final uri = Uri.parse(
        '$baseUrl/users/me/reports',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to fetch your reports',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get my reports: $e');
    }
  }

  /// Get nearby reports (within radius)
  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/reports/nearby'
        '?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm',
      );

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to fetch nearby reports',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get nearby reports: $e');
    }
  }

  /// Get single report by ID
  Future<Report> getReport(String reportId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Report not found', statusCode: 404);
      } else {
        throw ApiException(
          'Failed to fetch report',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get report: $e');
    }
  }

  /// Create new report
  /// Note: imageUrl should be uploaded to Supabase Storage first
  Future<Report> createReport({
    required String damageType,
    required String severity,
    required double latitude,
    required double longitude,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final body = jsonEncode({
        'damage_type': normalizeDamageTypeValue(damageType),
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'image_url': imageUrl,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Report.fromJson(jsonDecode(response.body));
      } else {
        final errorDetail = _extractErrorDetail(response.body);
        throw ApiException(
          'Failed to create report: $errorDetail',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to create report: $e');
    }
  }

  String _extractErrorDetail(String responseBody) {
    if (responseBody.isEmpty) return 'Empty server response';

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail != null) return detail.toString();
      }
      return decoded.toString();
    } catch (_) {
      return responseBody;
    }
  }

  /// Vote on a report (upvote/downvote)
  Future<void> voteReport(String reportId, {required bool upvote}) async {
    try {
      final body = jsonEncode({'value': upvote ? 1 : -1});

      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/vote'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to vote on report',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to vote report: $e');
    }
  }

  // ============ USERS ENDPOINTS ============

  /// Get user profile by ID
  Future<User> getUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('User not found', statusCode: 404);
      } else {
        throw ApiException(
          'Failed to fetch user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get user: $e');
    }
  }

  /// Get user stats by ID
  Future<UserStats> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return UserStats.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('User not found', statusCode: 404);
      } else {
        throw ApiException(
          'Failed to fetch user stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get user stats: $e');
    }
  }

  /// Update current user profile
  Future<User> updateUser({
    String? username,
    String? avatarUrl,
    String? fullName,
    String? bio,
  }) async {
    try {
      final body = jsonEncode({
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
      });
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Failed to update user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to update user: $e');
    }
  }

  /// Update user email preferences
  Future<void> updateEmailPreferences({
    required bool incidentDigest,
    required bool milestoneAlerts,
    required bool productUpdates,
  }) async {
    try {
      final body = jsonEncode({
        'incident_digest': incidentDigest,
        'milestone_alerts': milestoneAlerts,
        'product_updates': productUpdates,
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/preferences/email'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update email preferences',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to update email preferences: $e');
    }
  }

  /// Update user security settings
  Future<void> updateSecuritySettings({
    required bool twoFactor,
    required bool biometricLock,
    required bool locationMasking,
  }) async {
    try {
      final body = jsonEncode({
        'two_factor_enabled': twoFactor,
        'biometric_lock': biometricLock,
        'location_masking': locationMasking,
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/preferences/security'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update security settings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to update security settings: $e');
    }
  }

  /// Update user appearance preferences
  Future<void> updateAppearancePreferences({
    required String theme,
    required bool darkMode,
  }) async {
    try {
      final body = jsonEncode({'theme': theme, 'dark_mode': darkMode});

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/preferences/appearance'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update appearance preferences',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to update appearance preferences: $e');
    }
  }

  /// Update user language preference
  Future<void> updateLanguagePreference(String language) async {
    try {
      final body = jsonEncode({'language': language});

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/preferences/language'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update language preference',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to update language preference: $e');
    }
  }

  // ============ LEADERBOARD ENDPOINTS ============

  /// Get top users by points
  Future<List<LeaderboardEntry>> getLeaderboard({int? limit}) async {
    try {
      final uri = Uri.parse('$baseUrl/leaderboard').replace(
        queryParameters: limit != null ? {'limit': limit.toString()} : null,
      );

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.asMap().entries.map((entry) {
          final index = entry.key + 1;
          return LeaderboardEntry.fromJson(
            entry.value as Map<String, dynamic>,
            index,
          );
        }).toList();
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Leaderboard endpoint is not available on the backend.',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          'Leaderboard service failed on the backend. Check backend setup and server logs.',
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          'Leaderboard request failed.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException(
        'Unable to reach the backend server. Make sure it is running and reachable from the app.',
      );
    } on http.ClientException {
      throw ApiException(
        'Unable to contact the leaderboard service. Verify the backend URL and try again.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get leaderboard: $e');
    }
  }

  // ============ BADGES ENDPOINTS ============

  Future<List<Badge>> getMyBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/badges/me/awards'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Badge.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to fetch badges',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get badges: $e');
    }
  }

  // ============ POINTS ENDPOINTS ============

  Future<List<PointTransaction>> getMyPointsHistory({int? limit}) async {
    try {
      final uri = Uri.parse('$baseUrl/points/me/history').replace(
        queryParameters: limit != null ? {'limit': limit.toString()} : null,
      );

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map(
              (json) => PointTransaction.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ApiException(
          'Failed to fetch point history',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Failed to get point history: $e');
    }
  }

  // ============ STORAGE ENDPOINTS (Supabase) ============

  /// Upload image to Supabase Storage (reports-images bucket)
  /// Returns the public URL of the uploaded image
  Future<String> uploadReportImage({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw ApiException('User not authenticated');
      }

      // Storage path inside the bucket: {userId}/{fileName}
      final storagePath = '$userId/$fileName';

      await _supabase.storage
          .from('reports-images')
          .uploadBinary(storagePath, Uint8List.fromList(fileBytes));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('reports-images')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw ApiException('Failed to upload image: $e');
    }
  }

  /// Upload avatar to Supabase Storage (avatars bucket)
  Future<String> uploadAvatar({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw ApiException('User not authenticated');
      }

      // Storage path inside the bucket: {userId}/{fileName}
      final storagePath = '$userId/$fileName';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(storagePath, Uint8List.fromList(fileBytes));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw ApiException('Failed to upload avatar: $e');
    }
  }
}
