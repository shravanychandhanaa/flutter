import 'package:flutter/material.dart';
import '../config/environment.dart';

class EnvironmentSelector extends StatefulWidget {
  final Function(Environment) onEnvironmentChanged;
  final Environment initialEnvironment;

  const EnvironmentSelector({
    super.key,
    required this.onEnvironmentChanged,
    this.initialEnvironment = Environment.development,
  });

  @override
  State<EnvironmentSelector> createState() => _EnvironmentSelectorState();
}

class _EnvironmentSelectorState extends State<EnvironmentSelector> {
  late Environment _selectedEnvironment;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = widget.initialEnvironment;
    print('🔧 EnvironmentSelector initState: _selectedEnvironment = $_selectedEnvironment');
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 EnvironmentSelector build: _selectedEnvironment = $_selectedEnvironment');
    
    print('🔧 EnvironmentSelector: Showing environment selector');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings,
            size: 16,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 8),
          Text(
            'Environment:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.amber[700],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<Environment>(
            value: _selectedEnvironment,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.amber[700],
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.amber[700],
            ),
            items: Environment.values.map((Environment env) {
              return DropdownMenuItem<Environment>(
                value: env,
                child: Text(
                  _getEnvironmentDisplayName(env),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[700],
                  ),
                ),
              );
            }).toList(),
            onChanged: (Environment? newValue) {
              if (newValue != null) {
                print('🔧 EnvironmentSelector: User selected $newValue');
                setState(() {
                  _selectedEnvironment = newValue;
                });
                widget.onEnvironmentChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  String _getEnvironmentDisplayName(Environment env) {
    switch (env) {
      case Environment.development:
        return 'Development';
      case Environment.testing:
        return 'Testing';
      case Environment.production:
        return 'Production';
    }
  }
} 