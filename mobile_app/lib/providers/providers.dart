import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/index.dart';
import '../services/api_service.dart';

/// API Service Provider - singleton instance
class ApiServiceProvider extends ChangeNotifier {
  late ApiService _apiService;

  ApiServiceProvider() {
    _apiService = ApiService(Supabase.instance.client);
  }

  ApiService get apiService => _apiService;
}

/// Current User Provider - manages authentication state
class CurrentUserProvider extends ChangeNotifier {
  late ApiService _apiService;
  User? _user;
  bool _isLoading = false;
  String? _error;

  CurrentUserProvider(this._apiService);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }
}

/// Reports Provider - manages all reports state
class ReportsProvider extends ChangeNotifier {
  late ApiService _apiService;
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;

  ReportsProvider(this._apiService);

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _apiService.getReports(page: page, pageSize: 10);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      return await _apiService.getNearbyReports(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Report?> getReport(String reportId) async {
    try {
      return await _apiService.getReport(reportId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Report?> createReport({
    required String damageType,
    required String severity,
    required double latitude,
    required double longitude,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final report = await _apiService.createReport(
        damageType: damageType,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        description: description,
        imageUrl: imageUrl,
      );
      _reports.insert(0, report);
      _error = null;
      notifyListeners();
      return report;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> voteReport(String reportId, {required bool upvote}) async {
    try {
      await _apiService.voteReport(reportId, upvote: upvote);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

/// Leaderboard Provider - manages leaderboard state
class LeaderboardProvider extends ChangeNotifier {
  late ApiService _apiService;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  LeaderboardProvider(this._apiService);

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaderboard({int? limit}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaderboard = await _apiService.getLeaderboard(limit: limit ?? 50);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _leaderboard = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// User Provider - manages user profile state
class UserProvider extends ChangeNotifier {
  late ApiService _apiService;
  Map<String, User?> _userCache = {};
  String? _error;

  UserProvider(this._apiService);

  String? get error => _error;

  Future<User?> getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _apiService.getUser(userId);
      _userCache[userId] = user;
      _error = null;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<User?> updateCurrentUser({String? username, String? avatarUrl}) async {
    try {
      final user = await _apiService.updateUser(
        username: username,
        avatarUrl: avatarUrl,
      );
      _error = null;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
