import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateOnlyFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm:ss');

  static String toIsoString(DateTime dt) => _isoFormat.format(dt.toUtc());
  
  static String formatForDisplay(DateTime dt) => _displayFormat.format(dt.toLocal());
  
  static String formatDateOnly(DateTime dt) => _dateOnlyFormat.format(dt.toLocal());
  
  static String formatTimeOnly(DateTime dt) => _timeOnlyFormat.format(dt.toLocal());

  static DateTime? parseIsoString(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return DateTime.parse(str).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String formatDuration(int seconds) {
    if (seconds < 0) return '00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  static String formatPace(double paceSecPerKm) {
    if (paceSecPerKm <= 0) return '--:--';
    final m = (paceSecPerKm / 60).floor();
    final s = (paceSecPerKm % 60).round();
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  static String formatSpeed(double speedKmh) {
    if (speedKmh <= 0) return '--.-';
    return speedKmh.toStringAsFixed(1);
  }

  static String formatDistance(double distanceM) {
    if (distanceM < 1000) {
      return '${distanceM.round()} m';
    }
    return '${(distanceM / 1000).toStringAsFixed(2)} km';
  }
}