import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/device_models.dart';
import '../utils/date_time.dart';

class TcxParser {
  static ActivitySession parse(String xmlString, {String? deviceName, String? firmwareVersion}) {
    final document = XmlDocument.parse(xmlString);
    
    final activity = document.findAllElements('Activity').firstOrNull;
    if (activity == null) {
      throw FormatException('No Activity element found in TCX');
    }

    final id = activity.getAttribute('Id') ?? DateTime.now().toIso8601String();
    final sport = activity.getAttribute('Sport')?.toLowerCase() ?? 'row';
    
    final laps = activity.findAllElements('Lap').toList();
    if (laps.isEmpty) {
      throw FormatException('No Lap elements found in TCX');
    }

    final firstLap = laps.first;
    final startTime = DateTimeUtils.parseIsoString(firstLap.getAttribute('StartTime')) ?? DateTime.now();
    
    final trackpoints = activity.findAllElements('Trackpoint').toList();
    if (trackpoints.isEmpty) {
      throw FormatException('No Trackpoints found in TCX');
    }

    double totalDistanceM = 0;
    int totalElapsedSec = 0;
    int totalStrokes = 0;
    int maxSpm = 0;
    int totalHr = 0;
    int hrCount = 0;
    int maxHr = 0;
    final strokes = <StrokeData>[];
    final splits = <SplitData>[];

    DateTime? lastTime;
    int strokeIndex = 0;
    int splitIndex = 0;

    for (final tp in trackpoints) {
      final timeStr = tp.findElements('Time').firstOrNull?.text;
      final time = DateTimeUtils.parseIsoString(timeStr);
      
      final distanceStr = tp.findElements('DistanceMeters').firstOrNull?.text;
      final distance = distanceStr != null ? double.tryParse(distanceStr) ?? 0 : 0.0;
      
      final hrStr = tp.findElements('HeartRateBpm').firstOrNull?.findElements('Value').firstOrNull?.text;
      final hr = hrStr != null ? int.tryParse(hrStr) : null;
      
      final cadenceStr = tp.findElements('Cadence').firstOrNull?.text;
      final cadence = cadenceStr != null ? int.tryParse(cadenceStr) : null;
      
      final extensions = tp.findElements('Extensions').firstOrNull;
      int? driveTime, recoveryTime, catchDeg, finishDeg, arcDeg;
      
      if (extensions != null) {
        final tpx = extensions.findElements('TPX').firstOrNull;
        if (tpx != null) {
          driveTime = int.tryParse(tpx.findElements('DriveTime').firstOrNull?.text ?? '');
          recoveryTime = int.tryParse(tpx.findElements('RecoveryTime').firstOrNull?.text ?? '');
          catchDeg = int.tryParse(tpx.findElements('CatchAngle').firstOrNull?.text ?? '');
          finishDeg = int.tryParse(tpx.findElements('FinishAngle').firstOrNull?.text ?? '');
          arcDeg = int.tryParse(tpx.findElements('ArcAngle').firstOrNull?.text ?? '');
        }
      }

      if (time != null) {
        if (lastTime != null) {
          totalElapsedSec += time.difference(lastTime).inSeconds;
        }
        lastTime = time;
      }

      if (distance > totalDistanceM) {
        totalDistanceM = distance;
      }

      if (hr != null && hr > 0) {
        totalHr += hr;
        hrCount++;
        if (hr > maxHr) maxHr = hr;
      }

      if (cadence != null && cadence > 0) {
        if (cadence > maxSpm) maxSpm = cadence;
      }

      if (cadence != null && driveTime != null) {
        totalStrokes++;
        strokes.add(StrokeData(
          index: strokeIndex++,
          timestamp: time ?? DateTime.now(),
          spm: cadence,
          driveTimeMs: driveTime,
          recoveryTimeMs: recoveryTime ?? 0,
          distanceM: distance,
          paceSecPerKm: distance > 0 && totalElapsedSec > 0 
              ? (totalElapsedSec / (distance / 1000)) 
              : 0,
          hr: hr,
          catchDeg: catchDeg,
          finishDeg: finishDeg,
          arcDeg: arcDeg,
        ));
      }
    }

    for (final lap in laps) {
      final lapStart = DateTimeUtils.parseIsoString(lap.getAttribute('StartTime')) ?? DateTime.now();
      final lapTimeStr = lap.findElements('TotalTimeSeconds').firstOrNull?.text;
      final lapTime = lapTimeStr != null ? int.tryParse(lapTimeStr) ?? 0 : 0;
      final lapDistStr = lap.findElements('DistanceMeters').firstOrNull?.text;
      final lapDist = lapDistStr != null ? double.tryParse(lapDistStr) ?? 0.0 : 0.0;
      final lapAvgPaceStr = lap.findElements('AveragePace').firstOrNull?.text;
      final lapAvgPace = lapAvgPaceStr != null ? double.tryParse(lapAvgPaceStr) ?? 0.0 : 0.0;
      final lapAvgCadStr = lap.findElements('AverageCadence').firstOrNull?.text;
      final lapAvgCad = lapAvgCadStr != null ? int.tryParse(lapAvgCadStr) : null;
      final lapAvgHrStr = lap.findElements('AverageHeartRateBpm').firstOrNull?.findElements('Value').firstOrNull?.text;
      final lapAvgHr = lapAvgHrStr != null ? int.tryParse(lapAvgHrStr) : null;
      final lapStrokeCountStr = lap.findElements('StrokeCount').firstOrNull?.text;
      final lapStrokeCount = lapStrokeCountStr != null ? int.tryParse(lapStrokeCountStr) : null;

      splits.add(SplitData(
        index: splitIndex++,
        startTime: lapStart,
        durationSec: lapTime,
        distanceM: lapDist,
        avgPaceSecPerKm: lapAvgPace,
        avgSpm: lapAvgCad ?? 0,
        avgHr: lapAvgHr,
        strokeCount: lapStrokeCount,
      ));
    }

    final avgPace = totalDistanceM > 0 && totalElapsedSec > 0
        ? totalElapsedSec / (totalDistanceM / 1000)
        : 0.0;
    final avgSpeed = totalElapsedSec > 0 && totalDistanceM > 0
        ? (totalDistanceM / 1000) / (totalElapsedSec / 3600)
        : 0.0;
    final avgSpm = strokes.isNotEmpty ? strokes.map((s) => s.spm).reduce((a, b) => a + b) ~/ strokes.length : 0;
    final avgHr = hrCount > 0 ? totalHr ~/ hrCount : null;

    return ActivitySession(
      id: id,
      startTime: startTime,
      endTime: lastTime ?? startTime.add(Duration(seconds: totalElapsedSec)),
      elapsedSec: totalElapsedSec,
      distanceM: totalDistanceM,
      avgPaceSecPerKm: avgPace,
      avgSpeedKmh: avgSpeed,
      avgSpm: avgSpm,
      maxSpm: maxSpm,
      avgHr: avgHr,
      maxHr: maxHr > 0 ? maxHr : null,
      strokes: strokes,
      splits: splits,
      sportType: sport,
      deviceName: deviceName,
      firmwareVersion: firmwareVersion,
    );
  }
}

class CsvParser {
  static List<List<dynamic>> _parseCsvRows(String csvContent) {
    return csvContent
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.split(',').map((cell) => cell.trim()).toList())
        .toList();
  }

  static List<StrokeData> parseStrokes(String csvContent) {
    final rows = _parseCsvRows(csvContent);
    if (rows.length < 2) return [];
    
    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1).toList();
    
    final strokeIndex = headers.indexWhere((h) => h.contains('stroke') || h.contains('index') || h == '#');
    final timeIndex = headers.indexWhere((h) => h.contains('time') || h.contains('timestamp') || h.contains('date'));
    final spmIndex = headers.indexWhere((h) => h.contains('spm') || h.contains('cadence') || h.contains('rate'));
    final driveIndex = headers.indexWhere((h) => h.contains('drive') || h.contains('propul'));
    final recoveryIndex = headers.indexWhere((h) => h.contains('recovery') || h.contains('recup'));
    final distIndex = headers.indexWhere((h) => h.contains('dist') && !h.contains('total'));
    final paceIndex = headers.indexWhere((h) => h.contains('pace') || h.contains('allure'));
    final hrIndex = headers.indexWhere((h) => h.contains('hr') || h.contains('heart') || h.contains('fc') || h.contains('bpm'));
    final catchIndex = headers.indexWhere((h) => h.contains('catch') || h.contains('angle') && h.contains('catch'));
    final finishIndex = headers.indexWhere((h) => h.contains('finish') || h.contains('release'));
    final arcIndex = headers.indexWhere((h) => h.contains('arc') || h.contains('amplitude'));

    return dataRows.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value;
      
      return StrokeData(
        index: _parseInt(row, strokeIndex) ?? i,
        timestamp: _parseDateTime(row, timeIndex) ?? DateTime.now(),
        spm: _parseInt(row, spmIndex) ?? 0,
        driveTimeMs: _parseInt(row, driveIndex) ?? 0,
        recoveryTimeMs: _parseInt(row, recoveryIndex) ?? 0,
        distanceM: _parseDouble(row, distIndex) ?? 0,
        paceSecPerKm: _parseDouble(row, paceIndex) ?? 0,
        hr: _parseInt(row, hrIndex),
        catchDeg: _parseInt(row, catchIndex),
        finishDeg: _parseInt(row, finishIndex),
        arcDeg: _parseInt(row, arcIndex),
      );
    }).toList();
  }

  static List<SplitData> parseSplits(String csvContent) {
    final rows = _parseCsvRows(csvContent);
    if (rows.length < 2) return [];
    
    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1).toList();
    
    final indexIdx = headers.indexWhere((h) => h.contains('split') || h.contains('index') || h == '#');
    final startIdx = headers.indexWhere((h) => h.contains('start') || h.contains('time'));
    final durIdx = headers.indexWhere((h) => h.contains('dur') || h.contains('time') && h.contains('total'));
    final distIdx = headers.indexWhere((h) => h.contains('dist'));
    final paceIdx = headers.indexWhere((h) => h.contains('pace') || h.contains('allure'));
    final spmIdx = headers.indexWhere((h) => h.contains('spm') || h.contains('cadence'));
    final hrIdx = headers.indexWhere((h) => h.contains('hr') || h.contains('heart') || h.contains('fc'));
    final strokeIdx = headers.indexWhere((h) => h.contains('stroke') || h.contains('count'));

    return dataRows.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value;
      
      return SplitData(
        index: _parseInt(row, indexIdx) ?? i,
        startTime: _parseDateTime(row, startIdx) ?? DateTime.now(),
        durationSec: _parseInt(row, durIdx) ?? 0,
        distanceM: _parseDouble(row, distIdx) ?? 0,
        avgPaceSecPerKm: _parseDouble(row, paceIdx) ?? 0,
        avgSpm: _parseInt(row, spmIdx) ?? 0,
        avgHr: _parseInt(row, hrIdx),
        strokeCount: _parseInt(row, strokeIdx),
      );
    }).toList();
  }

  static int? _parseInt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final val = row[index];
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.round();
    return int.tryParse(val.toString());
  }

  static double? _parseDouble(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final val = row[index];
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static DateTime? _parseDateTime(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final val = row[index];
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTimeUtils.parseIsoString(val.toString());
  }
}

class TcxGenerator {
  static String generate(ActivitySession session) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln('  xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2');
    buffer.writeln('  http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">');
    buffer.writeln('  <Activities>');
    buffer.writeln('    <Activity Sport="${_sportToTcx(session.sportType)}">');
    buffer.writeln('      <Id>${DateTimeUtils.toIsoString(session.startTime)}</Id>');
    buffer.writeln('      <Lap StartTime="${DateTimeUtils.toIsoString(session.startTime)}">');
    buffer.writeln('        <TotalTimeSeconds>${session.elapsedSec}</TotalTimeSeconds>');
    buffer.writeln('        <DistanceMeters>${session.distanceM.toStringAsFixed(1)}</DistanceMeters>');
    buffer.writeln('        <AverageHeartRateBpm><Value>${session.avgHr ?? 0}</Value></AverageHeartRateBpm>');
    buffer.writeln('        <MaximumHeartRateBpm><Value>${session.maxHr ?? 0}</Value></MaximumHeartRateBpm>');
    buffer.writeln('        <AverageCadence>${session.avgSpm}</AverageCadence>');
    buffer.writeln('        <MaximumCadence>${session.maxSpm}</MaximumCadence>');
    buffer.writeln('        <StrokeCount>${session.strokes.length}</StrokeCount>');
    buffer.writeln('        <Intensity>Active</Intensity>');
    buffer.writeln('        <TriggerMethod>Manual</TriggerMethod>');
    buffer.writeln('        <Track>');

    for (final stroke in session.strokes) {
      buffer.writeln('          <Trackpoint>');
      buffer.writeln('            <Time>${DateTimeUtils.toIsoString(stroke.timestamp)}</Time>');
      buffer.writeln('            <DistanceMeters>${stroke.distanceM.toStringAsFixed(1)}</DistanceMeters>');
      if (stroke.hr != null && stroke.hr! > 0) {
        buffer.writeln('            <HeartRateBpm><Value>${stroke.hr}</Value></HeartRateBpm>');
      }
      buffer.writeln('            <Cadence>${stroke.spm}</Cadence>');
      if (stroke.driveTimeMs > 0 || stroke.recoveryTimeMs > 0 || 
          stroke.catchDeg != 0 || stroke.finishDeg != 0 || stroke.arcDeg != 0) {
        buffer.writeln('            <Extensions>');
        buffer.writeln('              <TPX xmlns="http://www.garmin.com/xmlschemas/ActivityExtension/v2">');
        if (stroke.driveTimeMs > 0) {
          buffer.writeln('                <DriveTime>${stroke.driveTimeMs}</DriveTime>');
        }
        if (stroke.recoveryTimeMs > 0) {
          buffer.writeln('                <RecoveryTime>${stroke.recoveryTimeMs}</RecoveryTime>');
        }
        if (stroke.catchDeg != 0) {
          buffer.writeln('                <CatchAngle>${stroke.catchDeg}</CatchAngle>');
        }
        if (stroke.finishDeg != 0) {
          buffer.writeln('                <FinishAngle>${stroke.finishDeg}</FinishAngle>');
        }
        if (stroke.arcDeg != 0) {
          buffer.writeln('                <ArcAngle>${stroke.arcDeg}</ArcAngle>');
        }
        buffer.writeln('              </TPX>');
        buffer.writeln('            </Extensions>');
      }
      buffer.writeln('          </Trackpoint>');
    }

    buffer.writeln('        </Track>');
    buffer.writeln('      </Lap>');
    buffer.writeln('    </Activity>');
    buffer.writeln('  </Activities>');
    buffer.writeln('</TrainingCenterDatabase>');
    
    return buffer.toString();
  }

  static String _sportToTcx(String sport) {
    switch (sport.toLowerCase()) {
      case 'run': return 'Running';
      case 'ride': return 'Biking';
      case 'row': return 'Rowing';
      case 'swim': return 'Swimming';
      default: return 'Other';
    }
  }
}