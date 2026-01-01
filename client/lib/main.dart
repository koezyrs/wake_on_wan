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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark Slate
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8), // Sky Blue
          secondary: Color(0xFF818CF8), // Indigo
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
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
      home: const MyHomePage(title: 'Control Center'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serverIpController = TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  final TextEditingController _macAddressController = TextEditingController();
  final TextEditingController _targetIpController = TextEditingController();
  final TextEditingController _targetPortController = TextEditingController();

  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIpController.text = prefs.getString('server_ip') ?? '';
      _serverPortController.text = prefs.getString('server_port') ?? '8000';
      _macAddressController.text = prefs.getString('mac_address') ?? '';
      _targetIpController.text =
          prefs.getString('target_ip') ?? '255.255.255.255';
      _targetPortController.text = prefs.getString('target_port') ?? '9';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIpController.text);
    await prefs.setString('server_port', _serverPortController.text);
    await prefs.setString('mac_address', _macAddressController.text);
    await prefs.setString('target_ip', _targetIpController.text);
    await prefs.setString('target_port', _targetPortController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuration Saved'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendWakeRequest() async {
    if (_serverIpController.text.isEmpty ||
        _macAddressController.text.isEmpty) {
      _showStatus('Server IP and MAC Address are required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Transmitting magic packet...';
    });

    final serverUrl =
        'http://${_serverIpController.text}:${_serverPortController.text}/wake';

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'mac_address': _macAddressController.text,
          'ip_address': _targetIpController.text,
          'port': int.tryParse(_targetPortController.text) ?? 9,
        }),
      );

      if (response.statusCode == 200) {
        _showStatus('Wake Signal Sent Successfully!');
      } else {
        _showStatus('Failed: ${response.statusCode} - ${response.body}',
            isError: true);
      }
    } catch (e) {
      _showStatus('Connection Failed. Check Server.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
    });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wake on WAN',
                            style: GoogleFonts.orbitron(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF38BDF8),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF38BDF8)
                                        .withOpacity(0.5),
                                    blurRadius: 10,
                                  )
                                ]),
                          ),
                          Text(
                            'Remote Power Control',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.download_done_rounded,
                            color: Color(0xFF38BDF8)),
                        tooltip: 'Save Settings',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.all(12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Gateway Server', Icons.router),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _serverIpController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Server Host / IP',
                            prefixIcon: Icon(Icons.dns_rounded),
                            hintText: '192.168.1.x',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _serverPortController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            prefixIcon: Icon(Icons.numbers_rounded),
                            hintText: '8000',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Target Machine', Icons.computer),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _macAddressController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'MAC Address',
                            prefixIcon: Icon(Icons.fingerprint_rounded),
                            hintText: 'AA:BB:CC:DD:EE:FF',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _targetIpController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Broadcast IP',
                                  prefixIcon: Icon(Icons.sensors),
                                  hintText: '255.255.255.255',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _targetPortController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Port',
                                  hintText: '9',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: InkWell(
                      onTap: _isLoading ? null : _sendWakeRequest,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 160,
                        height: 160,
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
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_statusMessage.isNotEmpty)
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.startsWith('Success') ||
                                _statusMessage.startsWith('Wake')
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFF87171),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
