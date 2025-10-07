import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/connection/connected_examples_hub.dart';
import '../../providers/mqtt_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class MQTTConnectionScreen extends StatefulWidget {
  final String? targetExample; // 'led', 'sensors', or 'floor'
  
  const MQTTConnectionScreen({
    super.key,
    this.targetExample,
  });

  @override
  MQTTConnectionScreenState createState() => MQTTConnectionScreenState();
}

class MQTTConnectionScreenState extends State<MQTTConnectionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isConnecting = false;
  bool _hasNavigated = false; // Flag para evitar múltiples navegaciones
  String _connectionError = '';

  // Lista de brokers con configuración específica
  final List<Map<String, dynamic>> _popularBrokers = [
    {
      'name': 'HiveMQ Cloud',
      'broker': '348a449ebec442358d59a2eb048341c4.s1.eu.hivemq.cloud',
      'port': 8883,
      'description': 'Broker HiveMQ Cloud con TLS seguro',
      'icon': Icons.cloud_queue,
      'color': Colors.orange,
      'isRecommended': true,
      'username': 'Thingy91x',
      'password': 'Thingy91x',
      'requiresTLS': true,
    },
    {
      'name': 'Nordic Semiconductor',
      'broker': 'mqtt.nordicsemi.no',
      'port': 1883,
      'description': 'Broker público de Nordic Semiconductor',
      'icon': Icons.memory,
      'color': Colors.blue,
      'isRecommended': false,
      'username': '',
      'password': '',
      'requiresTLS': false,
    },
    {
      'name': 'Configuración Personalizada',
      'broker': '',
      'port': 1883,
      'description': 'Introduce tu propio broker MQTT',
      'icon': Icons.settings,
      'color': Colors.grey,
      'isRecommended': false,
      'username': '',
      'password': '',
      'requiresTLS': false,
    },
  ];
  
  int _selectedBrokerIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Inicializar con el primer broker por defecto
    _selectBroker(0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectBroker(int index) {
    setState(() {
      _selectedBrokerIndex = index;
      final broker = _popularBrokers[index];
      _brokerController.text = broker['broker'];
      _portController.text = broker['port'].toString();
      _usernameController.text = broker['username'] ?? '';
      _passwordController.text = broker['password'] ?? '';
      _connectionError = '';
      _hasNavigated = false; // Reset navigation flag
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MQTTProvider>(
      builder: (context, mqttProvider, child) {
        // Si estamos conectados, navegar al hub de ejemplos
        if (mqttProvider.isConnected && !_hasNavigated) {
          _hasNavigated = true; // Marcar que ya navegamos
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('🔗 MQTT conectado exitosamente, navegando al hub de ejemplos...');
              _navigateToTargetExample(mqttProvider);
            }
          });
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              '☁️ Conexión MQTT',
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
            actions: [
              if (mqttProvider.isConnected)
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: Colors.red),
                  onPressed: () {
                    mqttProvider.disconnect();
                    setState(() {
                      _isConnecting = false;
                      _connectionError = '';
                      _hasNavigated = false; // Reset navigation flag
                    });
                  },
                  tooltip: 'Desconectar',
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: mqttProvider.isConnected 
                ? _buildConnectedState(mqttProvider)
                : _buildConnectionForm(mqttProvider),
          ),
        );
      },
    );
  }

  // Navigate to the ConnectedExamplesHub for MQTT connection
  void _navigateToTargetExample(MQTTProvider mqttProvider) {
    print('🚀 Navegando al ConnectedExamplesHub con connectionType: MQTT');
    
    // Pequeño delay para asegurar que el widget esté completamente montado
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConnectedExamplesHub(
              connectionType: 'MQTT',
              initialExample: widget.targetExample,
            ),
          ),
        );
      }
    });
  }

  // Show connected state while navigation is happening
  Widget _buildConnectedState(MQTTProvider mqttProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connected! Redirecting...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionForm(MQTTProvider mqttProvider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header con gradiente y información
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[400]!,
                    Colors.blue[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withValues(alpha: 0.2),
                  //     borderRadius: BorderRadius.circular(16),
                  //   ),
                  //   child: SizedBox(
                  //     width: 40,
                  //     height: 40,
                  //     child: Lottie.asset(
                  //       'assets/animations/cloud.json',
                  //       repeat: true,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conecta vía MQTT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.targetExample != null 
                              ? 'Conecta para usar ${_getExampleName()}'
                              : 'Elige un broker y conecta remotamente',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
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
            
            // Estado de conexión
            if (_connectionError.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline, 
                      color: Colors.red[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error de conexión',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _connectionError,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Lista de brokers
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de brokers
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_queue,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selecciona un Broker MQTT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Grid de brokers
                  Expanded(
                    child: ListView.builder(
                      itemCount: _popularBrokers.length,
                      itemBuilder: (context, index) {
                        return _buildBrokerCard(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botón de conexión
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isConnecting || _selectedBrokerIndex == 2 && _brokerController.text.isEmpty
                    ? null 
                    : () => _connectToMQTT(mqttProvider),
                icon: Icon(
                  _isConnecting ? Icons.hourglass_empty : Icons.cloud_upload,
                  size: 24,
                ),
                label: Text(
                  _isConnecting ? '🔄 Conectando...' : '☁️ Conectar al Broker',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnecting ? Colors.blue[400] : Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerCard(int index) {
    final broker = _popularBrokers[index];
    final isSelected = _selectedBrokerIndex == index;
    final isCustom = index == 2;
    final isRecommended = broker['isRecommended'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectBroker(index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.blue[50]!,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              border: Border.all(
                color: isSelected 
                    ? Colors.blue.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Fila principal con información del broker
                  Row(
                    children: [
                      // Icono del broker
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [broker['color'][400]!, broker['color'][600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: broker['color'].withValues(alpha: 0.4),
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
                                broker['icon'],
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            // Badge recomendado
                            if (isRecommended)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Información del broker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    broker['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                if (isRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Recomendado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              broker['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!isCustom) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${broker['broker']}:${broker['port']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'monospace',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              // Mostrar información de seguridad TLS/SSL
                              if (broker['requiresTLS'] == true) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'TLS Seguro',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Mostrar información de credenciales si están disponibles
                              if (broker['username'] != null && broker['username'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Usuario: ${broker['username']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      
                      // Indicador de selección
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,                        border: Border.all(
                          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[600],
                                ),
                              ),
                            )
                          : null,
                      ),
                    ],
                  ),
                  
                  // Campos de configuración para cualquier broker seleccionado
                  if (isSelected) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    if (isCustom) 
                      _buildCustomBrokerFields()
                    else
                      _buildBrokerCredentialsFields(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBrokerFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de broker
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _brokerController,
              decoration: const InputDecoration(
                labelText: 'Dirección del Broker',
                hintText: 'ejemplo: broker.example.com',
                prefixIcon: Icon(Icons.cloud),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Introduce la dirección del broker';
                }
                return null;
              },
            ),
          ),
          
          // Campo de puerto
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: '1883',
                prefixIcon: Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Introduce el número de puerto';
                }
                if (int.tryParse(value) == null) {
                  return 'Introduce un puerto válido';
                }
                return null;
              },
            ),
          ),
          
          // Campo de username
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario (opcional)',
                hintText: 'username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          
          // Campo de password
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña (opcional)',
                hintText: 'password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerCredentialsFields() {
    final isCustomBroker = _selectedBrokerIndex == 2; // Configuración personalizada
    final isReadOnly = !isCustomBroker;
    
    return Column(
      children: [
        // Información sobre editabilidad para brokers predefinidos
        if (isReadOnly)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las credenciales están preconfiguradas para este broker. Usa "Configuración Personalizada" para cambiarlas.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _connectToMQTT(MQTTProvider mqttProvider) async {
    // Validar campos personalizados si es necesario
    if (_selectedBrokerIndex == 2 && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionError = '';
      _hasNavigated = false; // Reset navigation flag
    });

    try {
      print('🔄 Intentando conectar a MQTT: ${_brokerController.text}:${_portController.text}');
      print('📝 Usuario: ${_usernameController.text}');
      print('🔐 Con autenticación: ${_usernameController.text.isNotEmpty}');
      
      final broker = _popularBrokers[_selectedBrokerIndex];
      final useTLS = broker['requiresTLS'] == true;
      print('🔒 TLS requerido: $useTLS');
      
      bool connected = await mqttProvider.connectWithCredentials(
        _brokerController.text,
        int.parse(_portController.text),
        _usernameController.text.isNotEmpty ? _usernameController.text : null,
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
        useTLS,
      );
      
      if (mounted) {
        if (connected) {
          print('✅ MQTT conectado exitosamente');
          // Dejar que el Consumer maneje la navegación
          setState(() {
            _isConnecting = false;
          });
        } else {
          print('❌ MQTT falló al conectar');
          setState(() {
            _connectionError = 'No se pudo conectar al broker. Verifica las credenciales y la conectividad.';
            _isConnecting = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error de conexión MQTT: $e');
      if (mounted) {
        setState(() {
          _connectionError = 'Error de conexión: ${e.toString()}';
          _isConnecting = false;
        });
      }
    }
  }

  String _getExampleName() {
    switch (widget.targetExample) {
      case 'led':
        return 'Control de LEDs';
      case 'floor':
        return 'Detector de Suelo';
      case 'sensors':
        return 'Sensores';
      default:
        return 'Ejemplo';
    }
  }
}
