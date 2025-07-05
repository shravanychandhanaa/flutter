import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../config/app_config.dart';

class EnvironmentSelector extends StatefulWidget {
  const EnvironmentSelector({super.key});

  @override
  State<EnvironmentSelector> createState() => _EnvironmentSelectorState();
}

class _EnvironmentSelectorState extends State<EnvironmentSelector> {
  late Environment _selectedEnvironment;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = EnvironmentConfig.environment;
  }

  Future<void> _saveEnvironment(Environment environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_environment', environment.name);
  }

  void _showEnvironmentConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Color(EnvironmentConfig.environmentColor),
            ),
            const SizedBox(width: 8),
            const Text('Environment Configuration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow('Environment', EnvironmentConfig.environmentName),
            const SizedBox(height: 8),
            _buildConfigRow('Base URL', EnvironmentConfig.baseUrl),
            const SizedBox(height: 8),
            _buildConfigRow('API Key', '${EnvironmentConfig.apiKey.substring(0, 8)}...'),
            const SizedBox(height: 8),
            _buildConfigRow('Timeout', '${EnvironmentConfig.timeout.inSeconds}s'),
            const SizedBox(height: 8),
            _buildConfigRow('Debug Logging', EnvironmentConfig.enableDebugLogging ? 'Enabled' : 'Disabled'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Test Environment Config Button
        ElevatedButton.icon(
          onPressed: _showEnvironmentConfig,
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Test Config', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 32),
          ),
        ),
        const SizedBox(width: 8),
        // Environment Selector
        PopupMenuButton<Environment>(
          initialValue: _selectedEnvironment,
          onSelected: (Environment newValue) async {
            setState(() {
              _selectedEnvironment = newValue;
            });
            EnvironmentConfig.setEnvironment(newValue);
            
            // Save to SharedPreferences
            await _saveEnvironment(newValue);
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${EnvironmentConfig.environmentName} environment'),
                  backgroundColor: Color(EnvironmentConfig.environmentColor),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Environment>>[
            const PopupMenuItem<Environment>(
              value: Environment.development,
              child: Text('Development'),
            ),
            const PopupMenuItem<Environment>(
              value: Environment.testing,
              child: Text('Testing'),
            ),
            const PopupMenuItem<Environment>(
              value: Environment.production,
              child: Text('Production'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(EnvironmentConfig.environmentColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(EnvironmentConfig.environmentColor),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings,
                  size: 16,
                  color: Color(EnvironmentConfig.environmentColor),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedEnvironment.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(EnvironmentConfig.environmentColor),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Color(EnvironmentConfig.environmentColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 