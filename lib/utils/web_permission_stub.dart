// Este archivo es un stub para la plataforma web que simula la API de permission_handler

class Permission {
  static final bluetooth = WebPermission();
  static final bluetoothScan = WebPermission();
  static final bluetoothConnect = WebPermission();
  static final bluetoothAdvertise = WebPermission();
  static final location = WebPermission();
}

enum PermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  permanentlyDenied,
}

class WebPermission {
  Future<PermissionStatus> request() async {
    // En web, asumimos que los permisos se solicitan mediante el navegador
    return PermissionStatus.granted;
  }

  Future<PermissionStatus> get status async => PermissionStatus.granted;
}