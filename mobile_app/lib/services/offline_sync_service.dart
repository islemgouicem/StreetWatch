import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import '../models/index.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String boxName = 'offline_reports';
  Box<Map>? _box;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<Map>(boxName);
      print('📦 Hive Offline Queue initialized. Box contains ${_box?.length ?? 0} drafts.');
    } catch (e) {
      print('❌ Hive initialization error: $e');
    }
  }

  Box<Map> get _getBox {
    if (_box == null) {
      throw Exception('OfflineSyncService is not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Check if the device currently has active internet connectivity
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Save a failed report submission to the offline queue
  Future<void> saveDraft(ReportDraft draft) async {
    final box = _getBox;
    final String key = 'draft_${DateTime.now().millisecondsSinceEpoch}';

    final draftMap = {
      'imagePath': draft.imagePath,
      'damageType': draft.damageType,
      'severity': draft.severity,
      'description': draft.description,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'boundingBoxes': draft.boundingBoxes,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await box.put(key, draftMap);
    print('💾 Saved offline report draft locally with key: $key');
  }

  /// Get all currently queued report drafts from local storage
  List<MapEntry<String, ReportDraft>> getQueuedDrafts() {
    final box = _getBox;
    final List<MapEntry<String, ReportDraft>> list = [];

    for (var key in box.keys) {
      final Map? rawMap = box.get(key);
      if (rawMap != null) {
        try {
          final map = Map<String, dynamic>.from(rawMap);
          final draft = ReportDraft(
            imagePath: map['imagePath'] as String,
            damageType: map['damageType'] as String,
            severity: map['severity'] as String,
            description: map['description'] as String?,
            latitude: map['latitude'] as double?,
            longitude: map['longitude'] as double?,
            boundingBoxes: (map['boundingBoxes'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );
          list.add(MapEntry(key.toString(), draft));
        } catch (e) {
          print('⚠️ Error parsing offline draft $key: $e');
        }
      }
    }

    // Sort drafts by timestamp descending (newest first)
    list.sort((a, b) {
      final Map? rawMapA = box.get(a.key);
      final Map? rawMapB = box.get(b.key);
      final int tsA = rawMapA?['timestamp'] as int? ?? 0;
      final int tsB = rawMapB?['timestamp'] as int? ?? 0;
      return tsB.compareTo(tsA);
    });

    return list;
  }

  /// Sync all queued report drafts to the FastAPI backend
  /// Returns count of successfully synchronized reports
  Future<int> syncQueue(ApiService apiService) async {
    final queued = getQueuedDrafts();
    if (queued.isEmpty) {
      print('📭 No offline reports to sync.');
      return 0;
    }

    print('⏳ Syncing ${queued.length} offline reports...');
    int successCount = 0;

    for (var entry in queued) {
      final key = entry.key;
      final draft = entry.value;

      try {
        final File imageFile = File(draft.imagePath);
        if (!await imageFile.exists()) {
          print('❌ Draft image file not found on disk at: ${draft.imagePath}. Skipping and removing corrupted draft.');
          await deleteDraft(key);
          continue;
        }

        final bytes = await imageFile.readAsBytes();
        final imageName = draft.imagePath.split(Platform.pathSeparator).last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$imageName';

        // 1. Upload the image to Supabase storage
        final imageUrl = await apiService.uploadReportImage(
          fileName: fileName,
          fileBytes: bytes,
        );

        // 2. Submit the report details to FastAPI
        await apiService.createReport(
          damageType: draft.damageType,
          severity: draft.severity,
          latitude: draft.latitude ?? 36.7538, // Fallback center
          longitude: draft.longitude ?? 3.0588,
          description: draft.description,
          imageUrl: imageUrl,
        );

        // 3. Successfully uploaded -> remove from Hive
        await deleteDraft(key);
        successCount++;
        print('✅ Successfully synced and removed offline report: $key');
      } catch (e) {
        print('❌ Failed to sync report draft $key: $e. Will retry later.');
      }
    }

    return successCount;
  }

  /// Delete a single draft from local Hive storage
  Future<void> deleteDraft(String key) async {
    await _getBox.delete(key);
  }
}
