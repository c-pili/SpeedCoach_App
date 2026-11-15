import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/ble_service.dart';
import '../../core/services/parsers.dart';
import '../../core/models/device_models.dart';
import '../../features/strava/strava_service.dart';

part 'providers.g.dart';

@riverpod
BleService bleService(Ref ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
StravaExportService stravaService(Ref ref) {
  return StravaExportService();
}

@riverpod
Stream<BluetoothDevice> scanStream(Ref ref) {
  final ble = ref.watch(bleServiceProvider);
  ble.initialize();
  return ble.scanStream;
}

@riverpod
class DeviceConnection extends _$DeviceConnection {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> connect(BluetoothDevice device) async {
    state = const AsyncLoading();
    final ble = ref.read(bleServiceProvider);
    try {
      await ble.connectToDevice(device);
      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final ble = ref.read(bleServiceProvider);
    await ble.disconnect();
    state = const AsyncData(false);
  }
}

@riverpod
class DeviceStatusNotifier extends _$DeviceStatusNotifier {
  @override
  FutureOr<DeviceStatus?> build() {
    return null;
  }

  Future<void> refresh() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      final status = await ble.getStatus();
      state = AsyncData(status);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
class CoachConfigNotifier extends _$CoachConfigNotifier {
  @override
  FutureOr<CoachConfig?> build() {
    return null;
  }

  Future<void> load() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      final config = await ble.getConfig();
      state = AsyncData(config);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> save(CoachConfig config) async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.setConfig(config);
      state = AsyncData(config);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
class ActivityFilesNotifier extends _$ActivityFilesNotifier {
  @override
  FutureOr<List<ActivityFile>> build() {
    return [];
  }

  Future<void> refresh() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      final response = await ble.listFiles();
      state = AsyncData(response.files);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteFile(String fileName) async {
    final ble = ref.read(bleServiceProvider);
    try {
      await ble.deleteFile(fileName);
      state = AsyncData(state.value!.where((f) => f.name != fileName).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
class ActivitySessionNotifier extends _$ActivitySessionNotifier {
  @override
  FutureOr<ActivitySession?> build() {
    return null;
  }

  Future<void> loadFromFile(ActivityFile file) async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      final bytes = await ble.downloadFile(file.name);
      final content = utf8.decode(bytes);
      
      ActivitySession session;
      if (file.type == 'tcx') {
        session = TcxParser.parse(content);
      } else if (file.type == 'strokes') {
        final strokes = CsvParser.parseStrokes(content);
        final splits = file.name.contains('splits') 
            ? CsvParser.parseSplits(content) 
            : <SplitData>[];
        session = _buildSessionFromCsv(file, strokes, splits);
      } else {
        throw Exception('Unsupported file type');
      }
      
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  ActivitySession _buildSessionFromCsv(ActivityFile file, List<StrokeData> strokes, List<SplitData> splits) {
    if (strokes.isEmpty) {
      return ActivitySession(
        id: file.name,
        startTime: file.date,
        endTime: file.date,
        elapsedSec: 0,
        distanceM: 0,
        avgPaceSecPerKm: 0,
        avgSpeedKmh: 0,
        avgSpm: 0,
        maxSpm: 0,
        strokes: [],
        splits: [],
      );
    }

    final startTime = strokes.first.timestamp;
    final endTime = strokes.last.timestamp;
    final elapsedSec = endTime.difference(startTime).inSeconds;
    final distanceM = strokes.last.distanceM;
    final avgPace = distanceM > 0 && elapsedSec > 0 ? elapsedSec / (distanceM / 1000) : 0.0;
    final avgSpeed = elapsedSec > 0 && distanceM > 0 ? (distanceM / 1000) / (elapsedSec / 3600) : 0.0;
    final avgSpm = strokes.map((s) => s.spm).reduce((a, b) => a + b) ~/ strokes.length;
    final maxSpm = strokes.map((s) => s.spm).reduce((a, b) => a > b ? a : b);
    final hrStrokes = strokes.where((s) => s.hr != null && s.hr! > 0).toList();
    final avgHr = hrStrokes.isNotEmpty ? hrStrokes.map((s) => s.hr!).reduce((a, b) => a + b) ~/ hrStrokes.length : null;
    final maxHr = hrStrokes.isNotEmpty ? hrStrokes.map((s) => s.hr!).reduce((a, b) => a > b ? a : b) : null;

    return ActivitySession(
      id: file.name,
      startTime: startTime,
      endTime: endTime,
      elapsedSec: elapsedSec,
      distanceM: distanceM,
      avgPaceSecPerKm: avgPace,
      avgSpeedKmh: avgSpeed,
      avgSpm: avgSpm,
      maxSpm: maxSpm,
      avgHr: avgHr,
      maxHr: maxHr,
      strokes: strokes,
      splits: splits,
    );
  }
}

@riverpod
class LivePreviewNotifier extends _$LivePreviewNotifier {
  @override
  Stream<LivePreview> build() {
    final ble = ref.read(bleServiceProvider);
    return ble.previewStream;
  }

  Future<void> startPreview() async {
    final ble = ref.read(bleServiceProvider);
    await ble.enablePreview(true);
  }

  Future<void> stopPreview() async {
    final ble = ref.read(bleServiceProvider);
    await ble.enablePreview(false);
  }
}

@riverpod
class ActivityControlNotifier extends _$ActivityControlNotifier {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> startFree() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.startActivity(WorkoutType.free);
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startTime(int seconds) async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.startActivity(WorkoutType.time, targetSec: seconds);
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startDistance(int meters) async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.startActivity(WorkoutType.distance, targetM: meters);
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startInterval(int repetitions, int workSec, int restSec) async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.startActivity(WorkoutType.interval, targetSec: workSec);
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> pause() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.pauseActivity();
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> stop() async {
    final ble = ref.read(bleServiceProvider);
    state = const AsyncLoading();
    try {
      await ble.stopActivity();
      state = const AsyncData(null);
      ref.invalidate(deviceStatusProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
Stream<int> batteryStream(Ref ref) {
  final ble = ref.read(bleServiceProvider);
  return ble.batteryStream;
}