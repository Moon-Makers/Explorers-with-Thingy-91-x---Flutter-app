import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thingy_91x/providers/ble_provider.dart';
import 'package:flutter_thingy_91x/screens/connection/connected_examples_hub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceScanScreen extends StatefulWidget {
  final String? targetExample; // 'led', 'sensors', or 'floor'
  
  const DeviceScanScreen({
    super.key,
    this.targetExample,
  });

  @override
  DeviceScanScreenState createState() => DeviceScanScreenState();
}

class DeviceScanScreenState extends State<DeviceScanScreen> {
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkBluetoothStatus();
    });
  }
  
  Future<void> _checkBluetoothStatus() async {
    if (!mounted) return;
    
    final bleProvider = Provider.of<BleProvider>(context, listen: false);
    
    try {
      if (kIsWeb) {
        setState(() {
          _errorMessage = '';
        });
        return;
      }
      
      final isReady = await bleProvider.isBluetoothReady();
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = isReady ? '' : 'Bluetooth no está encendido o no está disponible';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al verificar el estado de Bluetooth: $e';
      });
    }
  }

  Future<void> _startScan() async {
    setState(() => _errorMessage = '');
    final bleProvider = Provider.of<BleProvider>(context, listen: false);
    
    try {
      await bleProvider.startScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al iniciar el escaneo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context);
    final bool isScanning = bleProvider.isScanning;
    final adapterState = bleProvider.adapterState;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🔍 Buscar Dispositivos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(bleProvider, isScanning, adapterState),
    );
  }
  
  Widget _buildBody(BleProvider bleProvider, bool isScanning, BluetoothAdapterState adapterState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          
          // Header con título amigable
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bluetooth_searching,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conecta tu Thingy:91 X',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Asegúrate de que esté encendido y cerca',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Estado del Bluetooth (solo para móviles)
          if (!kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAdapterStateColor(adapterState).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getAdapterStateColor(adapterState).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getAdapterStateIcon(adapterState), 
                    color: _getAdapterStateColor(adapterState),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAdapterStateText(adapterState),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getAdapterStateColor(adapterState),
                            fontSize: 16,
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (adapterState != BluetoothAdapterState.on)
                    ElevatedButton(
                      onPressed: _checkBluetoothStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getAdapterStateColor(adapterState),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Verificar'),
                    ),
                ],
              ),
            ),
          
          // Botón de escaneo
          Center(
            child: Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: (isScanning || (!kIsWeb && adapterState != BluetoothAdapterState.on)) 
                    ? null 
                    : _startScan,
                icon: Icon(
                  isScanning ? Icons.stop : Icons.search,
                  size: 24,
                ),
                label: Text(
                  isScanning ? '🔄 Escaneando...' : '🔍 Buscar Dispositivos',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? Colors.orange[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lista de dispositivos
          Expanded(
            child: _buildDevicesList(bleProvider, isScanning),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDevicesList(BleProvider bleProvider, bool isScanning) {
    // Ordenar dispositivos por RSSI - más cercano a 0 = mejor señal (arriba)
    List<ScanResult> sortedResults = List.from(bleProvider.scanResults);
    sortedResults.sort((a, b) => b.rssi.compareTo(a.rssi)); // Mayor RSSI = mejor señal = arriba
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: sortedResults.isEmpty
          ? _buildEmptyState(isScanning)
          : _buildDevicesGrid(sortedResults, bleProvider),
    );
  }

  Widget _buildEmptyState(bool isScanning) {
    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animación de estado vacío
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[100]!,
                  Colors.blue[50]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
              size: 50,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Título principal
          Text(
            isScanning ? '🔍 Buscando dispositivos...' : '📱 Busca tu dispositivo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Descripción
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isScanning
                      ? 'Asegúrate de que tu dispositivo esté encendido y cerca'
                      : 'Toca el botón de escanear para encontrar dispositivos cercanos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                if (!isScanning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                          color: Colors.blue[600], 
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los dispositivos más cercanos aparecerán primero',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesGrid(List<ScanResult> sortedResults, BleProvider bleProvider) {
    return Container(
      key: const ValueKey('devices'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Lista de dispositivos
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sortedResults.length,
              itemBuilder: (context, index) {
                ScanResult result = sortedResults[index];
                return _buildModernDeviceItem(result, bleProvider, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDeviceItem(ScanResult result, BleProvider bleProvider, int index) {
    // Información del dispositivo
    final String deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Dispositivo Desconocido';
        
    final bool isThingy = deviceName.toLowerCase().contains('thingy');
    final bool isArduino = deviceName.toLowerCase().contains('arduino');
    final bool isESP = deviceName.toLowerCase().contains('esp');
    final bool isNordic = deviceName.toLowerCase().contains('nordic');
    final bool isCompatible = isThingy || isArduino || isESP || isNordic;
    
    // Determinar calidad de señal y colores
    String signalQuality;
    Color signalColor;
    IconData signalIcon;
    int signalBars;
    
    if (result.rssi >= -50) {
      signalQuality = 'Excelente';
      signalColor = Colors.green[600]!;
      signalIcon = Icons.signal_cellular_4_bar;
      signalBars = 4;
    } else if (result.rssi >= -70) {
      signalQuality = 'Buena';
      signalColor = Colors.lightGreen[600]!;
      signalIcon = Icons.signal_cellular_4_bar;
      signalBars = 3;
    } else if (result.rssi >= -85) {
      signalQuality = 'Regular';
      signalColor = Colors.orange[600]!;
      signalIcon = Icons.signal_cellular_alt;
      signalBars = 2;
    } else {
      signalQuality = 'Débil';
      signalColor = Colors.red[600]!;
      signalIcon = Icons.signal_cellular_alt_1_bar;
      signalBars = 1;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        elevation: isCompatible ? 8 : 4,
        borderRadius: BorderRadius.circular(20),
        shadowColor: isCompatible 
            ? Colors.blue.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isCompatible
                ? LinearGradient(
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isCompatible ? null : Colors.white,
            border: Border.all(
              color: isCompatible 
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: isCompatible ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Fila principal con información del dispositivo
                Row(
                  children: [
                    // Icono del dispositivo con ranking
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompatible
                              ? [Colors.blue[400]!, Colors.blue[600]!]
                              : [Colors.grey[400]!, Colors.grey[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompatible ? Colors.blue : Colors.grey).withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              isCompatible ? Icons.sensors : Icons.bluetooth,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          // Badge de ranking para top 3 compatibles
                          if (isCompatible && index < 3)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: index == 0 
                                        ? [Colors.amber[400]!, Colors.amber[600]!]
                                        : [Colors.amber[600]!, Colors.amber[800]!],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Información del dispositivo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre y badge de compatibilidad
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isCompatible ? Colors.blue[800] : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCompatible)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green[400]!, Colors.green[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '✓ Compatible',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // ID del dispositivo
                          Text(
                            'ID: ${result.device.remoteId.str}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Barra de señal y información
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: signalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: signalColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Información de señal
                      Row(
                        children: [
                          Icon(
                            signalIcon,
                            color: signalColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Señal: $signalQuality',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: signalColor,
                                  ),
                                ),
                                Text(
                                  '${result.rssi} dBm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Barras de señal visuales
                          Row(
                            children: List.generate(4, (barIndex) {
                              return Container(
                                margin: const EdgeInsets.only(left: 2),
                                width: 4,
                                height: 8 + (barIndex * 4),
                                decoration: BoxDecoration(
                                  color: barIndex < signalBars 
                                      ? signalColor 
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botón de conexión mejorado
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.link,
                            size: 20,
                          ),
                          label: const Text(
                            'Conectar Dispositivo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompatible 
                                ? Colors.blue[600]
                                : Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: isCompatible ? 4 : 2,
                            shadowColor: isCompatible 
                                ? Colors.blue.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.2),
                          ),
                          onPressed: () => _connectToDevice(result, bleProvider, deviceName),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice(ScanResult result, BleProvider bleProvider, String deviceName) async {
    // Detener el escaneo antes de conectar
    if (bleProvider.isScanning) {
      await bleProvider.stopScan();
    }
    
    final deviceNameShort = deviceName.length > 15 
        ? '${deviceName.substring(0, 15)}...' 
        : deviceName;
    
    // Diálogo de conexión optimizado según plataforma
    if (kIsWeb) {
      // En web, mostrar un mensaje más informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔗 Conectando con $deviceNameShort...',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        )
      );
    } else {
      // En móviles, mostrar un diálogo más elegante
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bluetooth_searching,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Conectando...',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Estableciendo conexión con\n$deviceNameShort',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    try {
      bool connected = await bleProvider.connectToDevice(result.device);
      
      // Cerrar diálogo en móviles
      if (!kIsWeb && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (connected) {
        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Conectado exitosamente a $deviceNameShort'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Navigate to the ConnectedExamplesHub for BLE connection
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ConnectedExamplesHub(
            connectionType: 'BLE',
            connectedDevice: result.device,
            initialExample: widget.targetExample,
          ),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('❌ Error al conectar con $deviceNameShort'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo en móviles
      if (!kIsWeb && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('⚠️ Error: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  Color _getAdapterStateColor(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return Colors.green;
      case BluetoothAdapterState.off:
        return Colors.red;
      case BluetoothAdapterState.turningOn:
      case BluetoothAdapterState.turningOff:
        return Colors.orange;
      case BluetoothAdapterState.unauthorized:
        return Colors.red;
      case BluetoothAdapterState.unknown:
      default:
        return Colors.grey;
    }
  }
  
  IconData _getAdapterStateIcon(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return Icons.bluetooth_connected;
      case BluetoothAdapterState.off:
        return Icons.bluetooth_disabled;
      case BluetoothAdapterState.turningOn:
      case BluetoothAdapterState.turningOff:
        return Icons.bluetooth_searching;
      case BluetoothAdapterState.unauthorized:
        return Icons.no_encryption_gmailerrorred;
      case BluetoothAdapterState.unknown:
      default:
        return Icons.bluetooth;
    }
  }
  
  String _getAdapterStateText(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return '✅ Bluetooth activado';
      case BluetoothAdapterState.off:
        return '❌ Bluetooth desactivado';
      case BluetoothAdapterState.turningOn:
        return '🔄 Activando Bluetooth...';
      case BluetoothAdapterState.turningOff:
        return '🔄 Desactivando Bluetooth...';
      case BluetoothAdapterState.unauthorized:
        return '🚫 Sin permisos de Bluetooth';
      case BluetoothAdapterState.unknown:
      default:
        return '❓ Estado de Bluetooth desconocido';
    }
  }
}
