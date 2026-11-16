import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleUuids {
  static const String service = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f00';
  static const String fwVersionChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f01';
  static const String battChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f02';
  static const String activityStateChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f10';
  static const String speedChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f11';
  static const String paceChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f12';
  static const String distanceChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f13';
  static const String strokeRateChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f14';
  static const String heartRateChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f15';
  static const String sessionTimeChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f16';
  static const String strokeCountChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f17';
  static const String sensorHrChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f20';
  static const String sensorRowpodChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f21';
  static const String workoutConfigChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f30';
  static const String displayPresetChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f31';
  static const String cmdChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f40';
  static const String activityListChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f50';
  static const String activityDetailChar = '9b7e1000-2b2f-4f71-9b86-4bb2e6d54f51';

  static final Guid serviceGuid = Guid(service);
  static final Guid cmdCharGuid = Guid(cmdChar);
  static final Guid battCharGuid = Guid(battChar);
}

class BleCommands {
  static const int none = 0;
  static const int startActivity = 1;
  static const int stopActivity = 2;
  static const int pauseActivity = 3;
  static const int resumeActivity = 4;
  static const int forgetHr = 9;
  static const int forgetRowpod = 10;

  // Legacy command IDs kept for compatibility with unused JSON methods
  static const int getStatus = 0x01;
  static const int getBattery = 0x02;
  static const int listFiles = 0x03;
  static const int getFile = 0x04;
  static const int deleteFile = 0x05;
  static const int getConfig = 0x10;
  static const int setConfig = 0x11;
  static const int getPreview = 0x30;
}

class BleStatus {
  static const int ok = 0;
  static const int error = 0x01;
  static const int notFound = 0x02;
  static const int busy = 0x03;
  static const int invalidParam = 0x04;
  static const int noFile = 0x05;
}

class DeviceState {
  static const String idle = 'idle';
  static const String recording = 'recording';
  static const String paused = 'paused';
}

class WorkoutType {
  static const int free = 0;
  static const int time = 1;
  static const int distance = 2;
  static const int interval = 3;
}

class DisplayMode {
  static const int pace = 0;
  static const int speed = 1;
  static const int accelGraph = 2;
}

class FileType {
  static const String tcx = 'tcx';
  static const String strokes = 'strokes';
  static const String splits = 'splits';
}

class SportType {
  static const String run = 'run';
  static const String ride = 'ride';
  static const String row = 'row';
  static const String swim = 'swim';
}