import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake on WAN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF38BDF8)),
          ),
          prefixIconColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _statusMessage = '';
  bool _isLoading = false;

  // Settings variables loaded from persistent storage
  String _serverIp = '';
  String _serverPort = '8000';
  String _macAddress = '';
  String _targetIp = '255.255.255.255';
  String _targetPort = '9';
  String _pcName = 'My PC';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIp = prefs.getString('server_ip') ?? '';
      _serverPort = prefs.getString('server_port') ?? '8000';
      _macAddress = prefs.getString('mac_address') ?? '';
      _targetIp = prefs.getString('target_ip') ?? '255.255.255.255';
      _targetPort = prefs.getString('target_port') ?? '9';
      _pcName = prefs.getString('pc_name') ?? 'My PC';
    });
  }

  Future<void> _sendWakeRequest() async {
    if (_serverIp.isEmpty || _macAddress.isEmpty) {
      _showStatus('Misconfigured. Tap Settings to setup.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Transmitting magic packet...';
    });

    final serverUrl = 'http://$_serverIp:$_serverPort/wake';
    
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'mac_address': _macAddress,
          'ip_address': _targetIp,
          'port': int.tryParse(_targetPort) ?? 9,
        }),
      );

      if (response.statusCode == 200) {
        _showStatus('Wake Signal Sent Successfully!');
      } else {
        _showStatus('Failed: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showStatus('Connection Failed. Check Server.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() => _statusMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              _loadSettings(); // Reload settings when returning
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pcName,
                  style: GoogleFonts.outfit(
                      fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (_serverIp.isNotEmpty)
                Text('Connected via $_serverIp',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const Spacer(),
              Center(
                child: InkWell(
                  onTap: _isLoading ? null : _sendWakeRequest,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.power_settings_new_rounded,
                              size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isLoading ? 'Waking up...' : 'Tap to Power On',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16, letterSpacing: 1.5),
              ),
              const Spacer(),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('Su')
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverIpController = TextEditingController();
  final _serverPortController = TextEditingController();
  final _macAddressController = TextEditingController();
  final _targetIpController = TextEditingController();
  final _targetPortController = TextEditingController();
  final _pcNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIpController.text = prefs.getString('server_ip') ?? '';
      _serverPortController.text = prefs.getString('server_port') ?? '8000';
      _macAddressController.text = prefs.getString('mac_address') ?? '';
      _targetIpController.text = prefs.getString('target_ip') ?? '255.255.255.255';
      _targetPortController.text = prefs.getString('target_port') ?? '9';
      _pcNameController.text = prefs.getString('pc_name') ?? 'My PC';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIpController.text);
    await prefs.setString('server_port', _serverPortController.text);
    await prefs.setString('mac_address', _macAddressController.text);
    await prefs.setString('target_ip', _targetIpController.text);
    await prefs.setString('target_port', _targetPortController.text);
    await prefs.setString('pc_name', _pcNameController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('General'),
              TextFormField(
                controller: _pcNameController,
                decoration: const InputDecoration(labelText: 'PC Name', prefixIcon: Icon(Icons.computer)),
              ),
              const SizedBox(height: 24),
              _buildHeader('Gateway Server'),
              TextFormField(
                controller: _serverIpController,
                decoration: const InputDecoration(labelText: 'Server IP / Host', prefixIcon: Icon(Icons.dns)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serverPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port', prefixIcon: Icon(Icons.numbers)),
              ),
              const SizedBox(height: 24),
              _buildHeader('Target Machine'),
              TextFormField(
                controller: _macAddressController,
                decoration: const InputDecoration(labelText: 'MAC Address', prefixIcon: Icon(Icons.fingerprint)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetIpController,
                      decoration: const InputDecoration(labelText: 'Broadcast IP', prefixIcon: Icon(Icons.sensors)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _targetPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'WOL Port'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }
}
