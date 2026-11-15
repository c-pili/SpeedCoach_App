class BleUuids {
  static const String service = '0000183a-0000-1000-8000-00805f9b34fb';
  static const String cmdChar = '00002a3b-0000-1000-8000-00805f9b34fb';
  static const String rspChar = '00002a3c-0000-1000-8000-00805f9b34fb';
  static const String fileChar = '00002a3d-0000-1000-8000-00805f9b34fb';
  static const String battChar = '00002a19-0000-1000-8000-00805f9b34fb';

  static const Guid serviceGuid = Guid(service);
  static const Guid cmdCharGuid = Guid(cmdChar);
  static const Guid rspCharGuid = Guid(rspChar);
  static const Guid fileCharGuid = Guid(fileChar);
  static const Guid battCharGuid = Guid(battChar);
}

class BleCommands {
  static const int getStatus = 0x01;
  static const int getBattery = 0x02;
  static const int listFiles = 0x03;
  static const int getFile = 0x04;
  static const int deleteFile = 0x05;
  static const int getConfig = 0x10;
  static const int setConfig = 0x11;
  static const int startActivity = 0x20;
  static const int pauseActivity = 0x21;
  static const int stopActivity = 0x22;
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