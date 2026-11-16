import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../models/device_models.dart';
import '../utils/byte_buffer.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _battChar;
  BluetoothCharacteristic? _activityStateChar;
  BluetoothCharacteristic? _speedChar;
  BluetoothCharacteristic? _paceChar;
  BluetoothCharacteristic? _distanceChar;
  BluetoothCharacteristic? _strokeRateChar;
  BluetoothCharacteristic? _heartRateChar;
  BluetoothCharacteristic? _sessionTimeChar;
  BluetoothCharacteristic? _strokeCountChar;
  BluetoothCharacteristic? _fwVersionChar;
  BluetoothCharacteristic? _workoutConfigChar;
  BluetoothCharacteristic? _displayPresetChar;
  BluetoothCharacteristic? _activityListChar;
  BluetoothCharacteristic? _activityDetailChar;

  final _rspController = StreamController<BleResponse>.broadcast();
  final _fileController = StreamController<FileChunk>.broadcast();
  final _battController = StreamController<int>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _scanController = StreamController<BluetoothDevice>.broadcast();

  Stream<BleResponse> get responses => _rspController.stream;
  Stream<FileChunk> get fileChunks => _fileController.stream;
  Stream<int> get batteryStream => _battController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<BluetoothDevice> get scanStream => _scanController.stream;

  BluetoothDevice? get connectedDevice => _device;
  bool get isConnected => _device != null;

  int _commandId = 0;
  final Map<int, Completer<BleResponse>> _pendingCommands = {};
  final Map<String, _FileTransferState> _fileTransfers = {};

  static const String _targetDeviceName = 'SpeedCoach';
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _commandTimeout = Duration(seconds: 5);
  static const Duration _connectTimeout = Duration(seconds: 15);

  Future<void> initialize() async {
    await _requestPermissions();
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });
  }

  Future<void> _requestPermissions() async {
    if (await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.locationWhenInUse.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(
        withNames: [_targetDeviceName],
        timeout: _scanTimeout,
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (result.device.name.contains(_targetDeviceName) ||
              result.advertisementData.localName.contains(_targetDeviceName)) {
            _scanController.add(result.device);
          }
        }
      });
    } catch (e) {
      print('Scan error: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _device = device;
    
    try {
      await _device!.connect(license: License.free, autoConnect: false, timeout: _connectTimeout);
      
      await _discoverServices();
      await _enableNotifications();
      await _negotiateMtu();
      
      _connectionController.add(true);
    } catch (e) {
      _connectionController.add(false);
      await disconnect();
      rethrow;
    }
  }

  Future<void> _discoverServices() async {
    final services = await _device!.discoverServices();
    
    for (final service in services) {
      if (service.uuid.str.toLowerCase() == BleUuids.service) {
        for (final char in service.characteristics) {
          switch (char.uuid.str.toLowerCase()) {
            case BleUuids.cmdChar:
              _cmdChar = char;
              break;
            case BleUuids.battChar:
              _battChar = char;
              break;
            case BleUuids.fwVersionChar:
              _fwVersionChar = char;
              break;
            case BleUuids.activityStateChar:
              _activityStateChar = char;
              break;
            case BleUuids.speedChar:
              _speedChar = char;
              break;
            case BleUuids.paceChar:
              _paceChar = char;
              break;
            case BleUuids.distanceChar:
              _distanceChar = char;
              break;
            case BleUuids.strokeRateChar:
              _strokeRateChar = char;
              break;
            case BleUuids.heartRateChar:
              _heartRateChar = char;
              break;
            case BleUuids.sessionTimeChar:
              _sessionTimeChar = char;
              break;
            case BleUuids.strokeCountChar:
              _strokeCountChar = char;
              break;
            case BleUuids.workoutConfigChar:
              _workoutConfigChar = char;
              break;
            case BleUuids.displayPresetChar:
              _displayPresetChar = char;
              break;
            case BleUuids.activityListChar:
              _activityListChar = char;
              break;
            case BleUuids.activityDetailChar:
              _activityDetailChar = char;
              break;
          }
        }
      }
    }

    if (_cmdChar == null) {
      throw Exception('Required characteristics not found');
    }
  }

  Future<void> _negotiateMtu() async {
    try {
      await _device!.requestMtu(158);
    } catch (_) {
      // MTU negotiation failed, continue with default
    }
  }

  Future<void> _enableNotifications() async {
    if (_battChar != null) {
      await _battChar!.setNotifyValue(true);
      _battChar!.lastValueStream.listen(_onBatteryNotification);
    }
  }

  void _onRspNotification(List<int> value) {
    try {
      final jsonStr = utf8.decode(value);
      final response = BleResponse.fromJson(jsonDecode(jsonStr));
      
      final completer = _pendingCommands.remove(response.id);
      if (completer != null) {
        completer.complete(response);
      }
      
      _rspController.add(response);
    } catch (e) {
      print('RSP parse error: $e');
    }
  }

  void _onFileNotification(List<int> value) {
    try {
      final jsonStr = utf8.decode(value);
      final chunk = FileChunk.fromJson(jsonDecode(jsonStr));
      
      _fileController.add(chunk);
      
      final state = _fileTransfers[chunk.fileName];
      if (state != null) {
        final bytes = base64Decode(chunk.dataBase64);
        state.buffer.addAll(bytes);
        
        if (chunk.isLast) {
          state.completer.complete(Uint8List.fromList(state.buffer));
          _fileTransfers.remove(chunk.fileName);
        }
      }
    } catch (e) {
      print('File chunk parse error: $e');
    }
  }

  void _onBatteryNotification(List<int> value) {
    if (value.isNotEmpty) {
      _battController.add(value[0]);
    }
  }

  Future<BleResponse> sendCommand(int cmd, Map<String, dynamic> payload) async {
    if (_cmdChar == null) {
      throw Exception('Not connected');
    }

    final id = ++_commandId;
    final command = BleCommand(id: id, cmd: cmd, payload: payload);
    final jsonStr = jsonEncode(command.toJson());
    final data = utf8.encode(jsonStr);

    final completer = Completer<BleResponse>();
    _pendingCommands[id] = completer;

    try {
      await _cmdChar!.write(data, withoutResponse: false);
      
      final response = await completer.future.timeout(_commandTimeout);
      return response;
    } on TimeoutException {
      _pendingCommands.remove(id);
      throw Exception('Command timeout');
    } catch (e) {
      _pendingCommands.remove(id);
      rethrow;
    }
  }

  Future<DeviceStatus> getStatus() async {
    final response = await sendCommand(BleCommands.getStatus, {});
    if (!response.isOk) throw Exception('Get status failed: ${response.error}');
    return DeviceStatus.fromJson(response.data!);
  }

  Future<int> getBattery() async {
    if (_battChar == null) throw Exception('Not connected');
    final value = await _battChar!.read();
    return value.isNotEmpty ? value[0] : 0;
  }

  Future<CoachConfig> getConfig() async {
    final response = await sendCommand(BleCommands.getConfig, {});
    if (!response.isOk) throw Exception('Get config failed');
    return CoachConfig.fromJson(response.data!);
  }

  Future<void> setConfig(CoachConfig config) async {
    final response = await sendCommand(BleCommands.setConfig, config.toJson());
    if (!response.isOk) throw Exception('Set config failed: ${response.error}');
  }

  Future<FileListResponse> listFiles() async {
    final response = await sendCommand(BleCommands.listFiles, {});
    if (!response.isOk) throw Exception('List files failed');
    return FileListResponse.fromJson(response.data!);
  }

  Future<Uint8List> downloadFile(String fileName) async {
    final completer = Completer<Uint8List>();
    _fileTransfers[fileName] = _FileTransferState(completer: completer);
    
    try {
      await sendCommand(BleCommands.getFile, {'file': fileName});
      return await completer.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      _fileTransfers.remove(fileName);
      throw Exception('File download timeout');
    } catch (e) {
      _fileTransfers.remove(fileName);
      rethrow;
    }
  }

  Future<void> deleteFile(String fileName) async {
    final response = await sendCommand(BleCommands.deleteFile, {'file': fileName});
    if (!response.isOk) throw Exception('Delete file failed');
  }

  Future<void> startActivity(int type, {int? targetSec, int? targetM}) async {
    if (_cmdChar == null) throw Exception('Not connected');
    await _cmdChar!.write([BleCommands.startActivity], withoutResponse: false);
  }

  Future<void> pauseActivity() async {
    if (_cmdChar == null) throw Exception('Not connected');
    await _cmdChar!.write([BleCommands.pauseActivity], withoutResponse: false);
  }

  Future<void> stopActivity() async {
    if (_cmdChar == null) throw Exception('Not connected');
    await _cmdChar!.write([BleCommands.stopActivity], withoutResponse: false);
  }

  Future<void> enablePreview(bool enable) async {
    final response = await sendCommand(BleCommands.getPreview, {'enable': enable});
    if (!response.isOk) throw Exception('Preview control failed');
  }

  Stream<LivePreview> get previewStream => _rspController.stream
      .where((r) => r.data != null && r.data!.containsKey('pace_sec_per_km'))
      .map((r) => LivePreview.fromJson(r.data!));

  Future<void> disconnect() async {
    try {
      if (_battChar != null) await _battChar!.setNotifyValue(false);
      
      if (_device != null) {
        await _device!.disconnect();
      }
    } catch (_) {}
    finally {
      _device = null;
      _cmdChar = null;
      _battChar = null;
      _activityStateChar = null;
      _speedChar = null;
      _paceChar = null;
      _distanceChar = null;
      _strokeRateChar = null;
      _heartRateChar = null;
      _sessionTimeChar = null;
      _strokeCountChar = null;
      _fwVersionChar = null;
      _workoutConfigChar = null;
      _displayPresetChar = null;
      _activityListChar = null;
      _activityDetailChar = null;
      _pendingCommands.clear();
      _fileTransfers.clear();
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
    }
  }

  void dispose() {
    _rspController.close();
    _fileController.close();
    _battController.close();
    _connectionController.close();
    _scanController.close();
    disconnect();
  }
}

class _FileTransferState {
  final Completer<Uint8List> completer;
  final List<int> buffer = [];
  
  _FileTransferState({required this.completer});
}