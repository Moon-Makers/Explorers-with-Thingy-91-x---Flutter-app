// Este archivo es un stub para que el código compile en web

class Permission {
  static final bluetooth = _PermissionStub();
  static final bluetoothScan = _PermissionStub();
  static final bluetoothConnect = _PermissionStub();
  static final location = _PermissionStub();
}

class _PermissionStub {
  Future<PermissionStatus> request() async {
    return PermissionStatus.granted;
  }
}

enum PermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  permanentlyDenied
}