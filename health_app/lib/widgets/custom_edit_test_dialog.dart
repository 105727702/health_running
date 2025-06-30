import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomEditTestDialog extends StatefulWidget {
  final Function(
    String sessionId,
    double distance,
    double calories,
    int duration,
    String activityType,
  )
  onUpdate;
  final Map<String, dynamic>? existingSession;

  const CustomEditTestDialog({
    super.key,
    required this.onUpdate,
    this.existingSession,
  });

  @override
  State<CustomEditTestDialog> createState() => _CustomEditTestDialogState();
}

class _CustomEditTestDialogState extends State<CustomEditTestDialog> {
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;
  late TextEditingController _durationController;
  late String _selectedActivityType;
  String? _selectedSessionId;

  final List<String> _activityTypes = [
    'walking',
    'running',
    'cycling',
    'hiking',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing session data if provided
    if (widget.existingSession != null) {
      final session = widget.existingSession!;
      _distanceController = TextEditingController(
        text: ((session['distance'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2),
      );
      _caloriesController = TextEditingController(
        text: ((session['calories'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(0),
      );
      _durationController = TextEditingController(
        text: (session['duration'] as int? ?? 0).toString(),
      );
      _selectedActivityType = session['activityType'] as String? ?? 'walking';
      _selectedSessionId = session['id'] as String?;
    } else {
      // Initialize with default values for new session
      _distanceController = TextEditingController(text: '2.5');
      _caloriesController = TextEditingController(text: '200');
      _durationController = TextEditingController(text: '30');
      _selectedActivityType = 'walking';
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Admin: Custom Edit Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (widget.existingSession != null
                              ? Colors.blue
                              : Colors.green)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        (widget.existingSession != null
                                ? Colors.blue
                                : Colors.green)
                            .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.existingSession != null
                          ? Icons.edit
                          : Icons.add_circle_outline,
                      color: widget.existingSession != null
                          ? Colors.blue
                          : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.existingSession != null
                            ? 'Edit existing session with custom values'
                            : 'Create new session with custom values (no existing sessions found)',
                        style: TextStyle(
                          color: (widget.existingSession != null
                              ? Colors.blue
                              : Colors.green)[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activity Type
              const Text(
                'Activity Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivityType,
                    items: _activityTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              type == 'running'
                                  ? Icons.directions_run
                                  : type == 'cycling'
                                  ? Icons.directions_bike
                                  : type == 'hiking'
                                  ? Icons.terrain
                                  : Icons.directions_walk,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedActivityType = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Distance
              _buildTextField(
                label: 'Distance (km)',
                controller: _distanceController,
                icon: Icons.route,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
              const SizedBox(height: 16),

              // Calories
              _buildTextField(
                label: 'Calories',
                controller: _caloriesController,
                icon: Icons.local_fire_department,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Duration
              _buildTextField(
                label: 'Duration (minutes)',
                controller: _durationController,
                icon: Icons.timer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Session ID Info (if editing existing)
              if (_selectedSessionId != null) ...[
                const Text(
                  'Session ID',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSessionId!.length > 20
                              ? '${_selectedSessionId!.substring(0, 20)}...'
                              : _selectedSessionId!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _performEditTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            widget.existingSession != null ? 'Test Edit' : 'Create Session',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.orange, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _performEditTest() {
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final duration = int.tryParse(_durationController.text) ?? 0;

    if (distance <= 0 || calories <= 0 || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid values for all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If we have a selected session ID, use it; otherwise, we'll edit the first available session
    widget.onUpdate(
      _selectedSessionId ?? '',
      distance,
      calories,
      duration,
      _selectedActivityType,
    );

    Navigator.of(context).pop();
  }
}
