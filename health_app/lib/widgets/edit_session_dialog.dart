import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hybrid_data_service.dart';

class EditSessionDialog extends StatefulWidget {
  final TrackingSession session;
  final Function(TrackingSession updatedSession) onUpdate;

  const EditSessionDialog({
    super.key,
    required this.session,
    required this.onUpdate,
  });

  @override
  State<EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<EditSessionDialog> {
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;
  late TextEditingController _durationController;
  late String _selectedActivityType;
  late DateTime _startTime;
  late DateTime _endTime;

  final List<String> _activityTypes = ['walking', 'running', 'cycling', 'hiking'];

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(
      text: widget.session.distance.toStringAsFixed(2),
    );
    _caloriesController = TextEditingController(
      text: widget.session.calories.toStringAsFixed(0),
    );
    _durationController = TextEditingController(
      text: widget.session.duration.toString(),
    );
    _selectedActivityType = widget.session.activityType;
    _startTime = widget.session.startTime;
    _endTime = widget.session.endTime;
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
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Edit Session',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            type == 'running' ? Icons.directions_run :
                            type == 'cycling' ? Icons.directions_bike :
                            type == 'hiking' ? Icons.terrain :
                            Icons.directions_walk,
                            color: Colors.deepPurple,
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),

            // Duration
            _buildTextField(
              label: 'Duration (minutes)',
              controller: _durationController,
              icon: Icons.timer,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),

            // Time Range
            const Text(
              'Time Range',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectTimeRange,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Changes'),
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
            prefixIcon: Icon(icon, color: Colors.deepPurple, size: 20),
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
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTimeRange() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
      helpText: 'Select Start Time',
    );

    if (startTime != null) {
      final TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
        helpText: 'Select End Time',
      );

      if (endTime != null) {
        setState(() {
          final date = DateTime.now();
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            startTime.hour,
            startTime.minute,
          );
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            endTime.hour,
            endTime.minute,
          );

          // Ensure end time is after start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _endTime.add(const Duration(days: 1));
          }

          // Update duration based on time difference
          final duration = _endTime.difference(_startTime).inMinutes;
          _durationController.text = duration.toString();
        });
      }
    }
  }

  void _saveChanges() {
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

    final updatedSession = TrackingSession(
      distance: distance,
      calories: calories,
      duration: duration,
      activityType: _selectedActivityType,
      startTime: _startTime,
      endTime: _endTime,
      route: widget.session.route, // Keep original route
    );

    widget.onUpdate(updatedSession);
    Navigator.of(context).pop();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
