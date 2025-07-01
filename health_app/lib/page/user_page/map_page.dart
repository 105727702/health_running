import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../models/location_service.dart';
import '../../utils/distance_calculator.dart' as utils;
import '../../utils/calorie_calculator.dart';
import '../../models/tracking_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/session_info_widget.dart';
import '../../services/data_manage/tracking_data_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LatLng _center = const LatLng(21.0285, 105.8542);
  final LocationService _locationService = LocationService();
  final TrackingDataService _trackingDataService = TrackingDataService();

  TrackingState _trackingState = TrackingState();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkAndResumeTracking();
  }

  // Check if we were tracking before app was closed and resume if needed
  Future<void> _checkAndResumeTracking() async {
    final wasTracking = await _trackingDataService.wasTrackingBeforeClosure();
    if (wasTracking) {
      // Wait for service to be initialized
      await _trackingDataService.initialized;

      // Get the resumed tracking state
      final resumedState = _trackingDataService.currentState;
      if (resumedState.isTracking) {
        setState(() {
          _trackingState = resumedState;
        });

        // Restart location tracking
        _startLocationTracking();

        // Show notification that tracking was resumed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tracking resumed! Distance: ${resumedState.totalDistance.toStringAsFixed(2)} km',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fixed Stats Panel - Always visible at top
          Container(
            padding: const EdgeInsets.all(16),
            color: Color.fromARGB(255, 26, 157, 213),
            child: Column(
              children: [
                // Session Info with settings button
                Row(
                  children: [
                    Expanded(
                      child: SessionInfoWidget(
                        showSessionDuration: true,
                        showAsCard: false,
                        padding: EdgeInsets.only(bottom: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: _showSettingsDialog,
                      icon: Icon(Icons.settings, color: Colors.deepPurple),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                // Detailed stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatCard(
                      title: 'Distance',
                      value:
                          '${_trackingState.totalDistance.toStringAsFixed(2)} km',
                      icon: Icons.route,
                    ),
                    StatCard(
                      title: 'Calo',
                      value:
                          '${_trackingState.totalCalories.toStringAsFixed(0)} cal',
                      icon: Icons.local_fire_department,
                    ),
                    StatCard(
                      title: 'Activities',
                      value: _trackingState.activityType,
                      icon: Icons.directions_run,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _trackingState.isTracking
                          ? _stopTracking
                          : _startTracking,
                      icon: Icon(
                        _trackingState.isTracking
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      label: Text(_trackingState.isTracking ? 'Stop' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _trackingState.isTracking
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _resetTracking,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map - Takes remaining space
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _trackingState.currentPosition ?? _center,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) {
                  if (_trackingState.isTracking) {
                    _addPointToRoute(point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.health_app',
                  maxZoom: 18,
                ),
                // Route polyline
                if (_trackingState.route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _trackingState.route,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                // Markers
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              if (_trackingState.currentPosition != null) {
                _mapController.move(_trackingState.currentPosition!, 15.0);
              } else {
                _getCurrentLocation();
              }
            },
            heroTag: "track_location",
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              double currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom + 1,
              );
            },
            heroTag: "zoom_in",
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              double currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom - 1,
              );
            },
            heroTag: "zoom_out",
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Current position marker
    if (_trackingState.currentPosition != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _trackingState.currentPosition!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 40),
          ),
        ),
      );
    }

    // Start marker
    if (_trackingState.route.isNotEmpty) {
      markers.add(
        Marker(
          width: 60.0,
          height: 60.0,
          point: _trackingState.route.first,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
        ),
      );
    }

    // End marker
    if (_trackingState.route.length > 1) {
      markers.add(
        Marker(
          width: 60.0,
          height: 60.0,
          point: _trackingState.route.last,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 30),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _getCurrentLocation() async {
    try {
      LatLng? position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _trackingState = _trackingState.copyWith(currentPosition: position);
        });
        _mapController.move(position, 15.0);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _startTracking() {
    setState(() {
      _trackingState = _trackingState.copyWith(
        isTracking: true,
        route: [],
        totalDistance: 0.0,
        totalCalories: 0.0,
        lastPosition: null,
      );
    });

    // Update the global tracking service
    _trackingDataService.updateTrackingState(_trackingState);
    _startLocationTracking();
  }

  void _stopTracking() {
    final finalState = _trackingState.copyWith(isTracking: false);

    setState(() {
      _trackingState = finalState;
    });

    // Save session to global tracking service
    _trackingDataService.saveSession(finalState);

    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
  }

  void _resetTracking() {
    setState(() {
      _trackingState = _trackingState.copyWith(
        isTracking: false,
        route: [],
        totalDistance: 0.0,
        totalCalories: 0.0,
        lastPosition: null,
      );
    });

    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
  }

  void _startLocationTracking() {
    _positionStreamSubscription = _locationService.startLocationTracking(
      onLocationUpdate: (LatLng newPosition) {
        if (_trackingState.isTracking) {
          _updatePosition(newPosition);
        }

        setState(() {
          _trackingState = _trackingState.copyWith(
            currentPosition: newPosition,
          );
        });
      },
    );

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingState.isTracking && mounted) {
        setState(() {
          // Force UI update
        });
      }
    });
  }

  void _updatePosition(LatLng newPosition) {
    if (_trackingState.lastPosition != null) {
      double distance = utils.DistanceCalculator.calculateDistance(
        _trackingState.lastPosition!,
        newPosition,
      );

      if (distance > 0.005) {
        // 5 meters
        List<LatLng> newRoute = List.from(_trackingState.route)
          ..add(newPosition);
        double newTotalDistance = _trackingState.totalDistance + distance;
        double newCalories = CalorieCalculator.calculateCalories(
          distanceKm: newTotalDistance,
          userWeight: _trackingState.userWeight,
          activityType: _trackingState.activityType,
        );

        final updatedState = _trackingState.copyWith(
          route: newRoute,
          totalDistance: newTotalDistance,
          totalCalories: newCalories,
          lastPosition: newPosition,
        );

        setState(() {
          _trackingState = updatedState;
        });

        // Update the global tracking service
        _trackingDataService.updateTrackingState(updatedState);

        _mapController.move(newPosition, _mapController.camera.zoom);
      }
    } else {
      List<LatLng> newRoute = List.from(_trackingState.route)..add(newPosition);
      final updatedState = _trackingState.copyWith(
        route: newRoute,
        lastPosition: newPosition,
      );

      setState(() {
        _trackingState = updatedState;
      });

      // Update the global tracking service
      _trackingDataService.updateTrackingState(updatedState);
    }
  }

  void _addPointToRoute(LatLng point) {
    if (!_trackingState.isTracking) return;

    List<LatLng> newRoute = List.from(_trackingState.route)..add(point);
    double newTotalDistance = _trackingState.totalDistance;

    if (_trackingState.lastPosition != null) {
      double distance = utils.DistanceCalculator.calculateDistance(
        _trackingState.lastPosition!,
        point,
      );
      newTotalDistance += distance;
    }

    double newCalories = CalorieCalculator.calculateCalories(
      distanceKm: newTotalDistance,
      userWeight: _trackingState.userWeight,
      activityType: _trackingState.activityType,
    );

    setState(() {
      _trackingState = _trackingState.copyWith(
        route: newRoute,
        totalDistance: newTotalDistance,
        totalCalories: newCalories,
        lastPosition: point,
      );
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempWeight = _trackingState.userWeight;
        String tempActivity = _trackingState.activityType;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Fitness Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weight Setting
                    Text('Weight: ${tempWeight.toStringAsFixed(1)} kg'),
                    Slider(
                      value: tempWeight,
                      min: 30.0,
                      max: 150.0,
                      divisions: 120,
                      onChanged: (value) {
                        setDialogState(() {
                          tempWeight = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Activity Type Setting
                    const Text('Activity Type:'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempActivity,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'walking',
                          child: Text('Walking'),
                        ),
                        DropdownMenuItem(
                          value: 'running',
                          child: Text('Running'),
                        ),
                        DropdownMenuItem(
                          value: 'cycling',
                          child: Text('Cycling'),
                        ),
                        DropdownMenuItem(
                          value: 'jogging',
                          child: Text('Jogging'),
                        ),
                        DropdownMenuItem(
                          value: 'hiking',
                          child: Text('Hiking'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            tempActivity = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Calculate new calories with updated settings
                    double newCalories = CalorieCalculator.calculateCalories(
                      distanceKm: _trackingState.totalDistance,
                      userWeight: tempWeight,
                      activityType: tempActivity,
                    );

                    setState(() {
                      _trackingState = _trackingState.copyWith(
                        userWeight: tempWeight,
                        activityType: tempActivity,
                        totalCalories: newCalories,
                      );
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
