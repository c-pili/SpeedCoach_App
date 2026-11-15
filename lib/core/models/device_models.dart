import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_models.freezed.dart';
part 'device_models.g.dart';

@freezed
abstract class DeviceStatus with _$DeviceStatus {
  const factory DeviceStatus({
    required String firmware,
    required String state,
    required int battery,
    required bool charging,
    required bool gpsFix,
    required bool hrConnected,
    required bool podConnected,
    required int storageUsed,
    required int storageTotal,
    String? hrName,
    String? podName,
  }) = _DeviceStatus;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) =>
      _$DeviceStatusFromJson(json);
}

@freezed
abstract class CoachConfig with _$CoachConfig {
  const factory CoachConfig({
    required int splitDistance,
    required int displayMode,
    required int workoutType,
    required int workoutTarget,
    @Default(75) int userWeight,
    @Default('1x') String boatType,
    @Default(true) bool autoPause,
    @Default(true) bool soundEnabled,
  }) = _CoachConfig;

  factory CoachConfig.fromJson(Map<String, dynamic> json) =>
      _$CoachConfigFromJson(json);
}

@freezed
abstract class ActivityFile with _$ActivityFile {
  const factory ActivityFile({
    required String name,
    required int size,
    required DateTime date,
    required String type,
    String? sportType,
  }) = _ActivityFile;

  factory ActivityFile.fromJson(Map<String, dynamic> json) =>
      _$ActivityFileFromJson(json);
}

@freezed
abstract class FileListResponse with _$FileListResponse {
  const factory FileListResponse({
    required List<ActivityFile> files,
  }) = _FileListResponse;

  factory FileListResponse.fromJson(Map<String, dynamic> json) =>
      _$FileListResponseFromJson(json);
}

@freezed
abstract class LivePreview with _$LivePreview {
  const factory LivePreview({
    required int paceSecPerKm,
    required double speedKmh,
    required int spm,
    required int hr,
    required int distanceM,
    required int elapsedSec,
    @Default(0) int driveTimeMs,
    @Default(0) int recoveryTimeMs,
    @Default(0) int catchDeg,
    @Default(0) int finishDeg,
    @Default(0) int arcDeg,
    required int battery,
    @Default(false) bool gpsFix,
    @Default(false) bool hrConnected,
  }) = _LivePreview;

  factory LivePreview.fromJson(Map<String, dynamic> json) =>
      _$LivePreviewFromJson(json);
}

@freezed
abstract class StrokeData with _$StrokeData {
  const factory StrokeData({
    required int index,
    required DateTime timestamp,
    required int spm,
    required int driveTimeMs,
    required int recoveryTimeMs,
    required double distanceM,
    required double paceSecPerKm,
    int? hr,
    int? catchDeg,
    int? finishDeg,
    int? arcDeg,
  }) = _StrokeData;

  factory StrokeData.fromJson(Map<String, dynamic> json) =>
      _$StrokeDataFromJson(json);
}

@freezed
abstract class SplitData with _$SplitData {
  const factory SplitData({
    required int index,
    required DateTime startTime,
    required int durationSec,
    required double distanceM,
    required double avgPaceSecPerKm,
    required int avgSpm,
    int? avgHr,
    int? strokeCount,
  }) = _SplitData;

  factory SplitData.fromJson(Map<String, dynamic> json) =>
      _$SplitDataFromJson(json);
}

@freezed
abstract class ActivitySession with _$ActivitySession {
  const ActivitySession._();
  
  const factory ActivitySession({
    required String id,
    required DateTime startTime,
    required DateTime endTime,
    required int elapsedSec,
    required double distanceM,
    required double avgPaceSecPerKm,
    required double avgSpeedKmh,
    required int avgSpm,
    required int maxSpm,
    int? avgHr,
    int? maxHr,
    required List<StrokeData> strokes,
    required List<SplitData> splits,
    @Default('row') String sportType,
    String? deviceName,
    String? firmwareVersion,
  }) = _ActivitySession;

  factory ActivitySession.fromJson(Map<String, dynamic> json) =>
      _$ActivitySessionFromJson(json);

  double get distanceKm => distanceM / 1000.0;
  
  String get formattedDuration {
    final h = elapsedSec ~/ 3600;
    final m = (elapsedSec % 3600) ~/ 60;
    final s = elapsedSec % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
  
  String get formattedAvgPace {
    if (avgPaceSecPerKm <= 0) return '--:--';
    final m = (avgPaceSecPerKm / 60).floor();
    final s = (avgPaceSecPerKm % 60).round();
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

@freezed
abstract class BleCommand with _$BleCommand {
  const BleCommand._();

  const factory BleCommand({
    required int id,
    required int cmd,
    required Map<String, dynamic> payload,
  }) = _BleCommand;

  factory BleCommand.fromJson(Map<String, dynamic> json) =>
      _$BleCommandFromJson(json);

  String toJsonString() {
    final map = toJson();
    return map.toString().replaceAll('{', '').replaceAll('}', '');
  }
  
  Map<String, dynamic> toJsonMap() => toJson();
}

@freezed
abstract class BleResponse with _$BleResponse {
  const BleResponse._();
  
  const factory BleResponse({
    required int id,
    required int status,
    Map<String, dynamic>? data,
    String? error,
  }) = _BleResponse;

  factory BleResponse.fromJson(Map<String, dynamic> json) =>
      _$BleResponseFromJson(json);

  bool get isOk => status == 0;
}

@freezed
abstract class FileChunk with _$FileChunk {
  const factory FileChunk({
    required String fileName,
    required int chunkIndex,
    required int totalChunks,
    required String dataBase64,
    required bool isLast,
  }) = _FileChunk;

  factory FileChunk.fromJson(Map<String, dynamic> json) =>
      _$FileChunkFromJson(json);
}