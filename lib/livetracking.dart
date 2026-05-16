import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class LiveTracking extends StatefulWidget {
  final String chatroomId;
  final bool isReceiver;
  final LatLng? destination;
  final String? apiKey;

  const LiveTracking({
    super.key,
    required this.chatroomId,
    required this.isReceiver,
    this.destination,
    this.apiKey,
  });

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  GoogleMapController? _mapController;
  LatLng? myLocation;
  LatLng? otherLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> pathCoordinates = [];

  StreamSubscription<Position>? _myLocationSub;
  StreamSubscription<DocumentSnapshot>? _otherLocationSub;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double distanceInMeters = 0.0;

  // Voice navigation
  final FlutterTts _tts = FlutterTts();
  List<Map<String, dynamic>> _steps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  Timer? _navTimer;
  DateTime? _lastSpeakTime;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initMyLocation();
    if (widget.isReceiver) _listenOtherLocation();
  }

  @override
  void dispose() {
    _myLocationSub?.cancel();
    _otherLocationSub?.cancel();
    _navTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _initTts() {
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  Future<void> _initMyLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      myLocation = LatLng(position.latitude, position.longitude);
      pathCoordinates.add(myLocation!);
      _updateMarkersAndPolyline();
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    if (!widget.isReceiver) return;

    _myLocationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((Position pos) async {
          myLocation = LatLng(pos.latitude, pos.longitude);

          await _firestore
              .collection('muazam chatroom')
              .doc(widget.chatroomId)
              .set({
                widget.isReceiver ? 'receiverLocation' : 'senderLocation': {
                  'lat': myLocation!.latitude,
                  'lng': myLocation!.longitude,
                },
              }, SetOptions(merge: true));

          pathCoordinates.add(myLocation!);
          _updateMarkersAndPolyline();

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: myLocation!, zoom: 17),
            ),
          );

          if (_isNavigating) {
            _updateNavigationProgress();
          }
        });
  }

  // Travel modes with average speeds in m/s
  final Map<String, double> travelModes = {
    'Car': 15.0, // ~54 km/h
    'Bike': 8.3, // ~30 km/h
    'Walk': 1.4, // ~5 km/h
  };

  String selectedMode = 'Car';

  String calculateETA(double distanceMeters) {
    final speed = travelModes[selectedMode] ?? 1.0; // m/s
    final seconds = distanceMeters / speed;
    if (seconds < 60) {
      return "${seconds.toStringAsFixed(0)} sec";
    } else if (seconds < 3600)
      return "${(seconds / 60).toStringAsFixed(0)} min";
    else
      return "${(seconds / 3600).toStringAsFixed(1)} hr";
  }

  void _listenOtherLocation() {
    _otherLocationSub = _firestore
        .collection('muazam chatroom')
        .doc(widget.chatroomId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data()!;
            Map<String, dynamic>? loc = widget.isReceiver
                ? data['senderLocation']
                : data['receiverLocation'];
            if (loc != null) {
              otherLocation = LatLng(loc['lat'], loc['lng']);
              _updateMarkersAndPolyline();
            }
          }
        });
  }

  Future<void> _fetchRouteAndSteps(
    LatLng origin,
    LatLng dest,
    String? apiKey,
  ) async {
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&key=$apiKey&units=metric';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final legs = route['legs'] as List<dynamic>;
            final steps = <Map<String, dynamic>>[];
            for (final leg in legs) {
              for (final s in leg['steps']) {
                final endLoc = s['end_location'];
                final dist = s['distance']?['value'] ?? 0;
                String instr = s['html_instructions'] ?? '';
                instr = _stripHtml(instr);
                steps.add({
                  'instruction': instr,
                  'endLat': endLoc['lat'],
                  'endLng': endLoc['lng'],
                  'distance': dist,
                });
              }
            }
            _steps = steps;
            _currentStepIndex = 0;
            return;
          }
        }
      } catch (_) {}
    }

    _steps = _generateSyntheticSteps(origin, dest, segmentMeters: 200);
    _currentStepIndex = 0;
  }

  List<Map<String, dynamic>> _generateSyntheticSteps(
    LatLng origin,
    LatLng dest, {
    double segmentMeters = 200,
  }) {
    final total = calculateDistance(
      origin.latitude,
      origin.longitude,
      dest.latitude,
      dest.longitude,
    );
    if (total <= 0) return [];

    final segments = max(1, (total / segmentMeters).ceil());
    final steps = <Map<String, dynamic>>[];

    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final lat = _lerp(origin.latitude, dest.latitude, t);
      final lng = _lerp(origin.longitude, dest.longitude, t);
      final remaining = calculateDistance(
        i == 1
            ? origin.latitude
            : _lerp(origin.latitude, dest.latitude, (i - 1) / segments),
        i == 1
            ? origin.longitude
            : _lerp(origin.longitude, dest.longitude, (i - 1) / segments),
        lat,
        lng,
      );
      steps.add({
        'instruction':
            'Continue straight for about ${remaining.toStringAsFixed(0)} meters',
        'endLat': lat,
        'endLng': lng,
        'distance': remaining.toInt(),
      });
    }

    if (steps.isNotEmpty) {
      steps.last['instruction'] =
          'You are near your destination. ${steps.last['instruction']}';
    }

    return steps;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '');

  void _startVoiceNavigation() {
    if (widget.destination == null) {
      _speak("No destination available for navigation.");
      return;
    }

    if (_steps.isEmpty) {
      if (myLocation != null) {
        _fetchRouteAndSteps(
          myLocation!,
          widget.destination!,
          widget.apiKey,
        ).then((_) {
          if (_steps.isNotEmpty) {
            _beginNavigation();
          } else {
            _speak("Failed to generate route steps.");
          }
        });
      } else {
        _speak("Current location not yet available.");
      }
    } else {
      _beginNavigation();
    }
  }

  void _beginNavigation() {
    _isNavigating = true;
    _speak("Navigation started. Proceed straight and follow instructions.");

    Future.delayed(const Duration(seconds: 1), () => _announceCurrentStep());

    _navTimer?.cancel();
    _navTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _updateNavigationProgress(),
    );
  }

  void _stopVoiceNavigation() {
    _isNavigating = false;
    _navTimer?.cancel();
    _speak("Navigation stopped");
  }

  void _announceCurrentStep() {
    if (_currentStepIndex >= _steps.length) return;

    final step = _steps[_currentStepIndex];
    final dist = step['distance']?.toDouble() ?? 0;
    String msg;

    if (dist > 1000) {
      msg = "Continue for ${(dist / 1000).toStringAsFixed(1)} kilometers.";
    } else if (dist > 200)
      msg = "Continue straight for about ${dist.toStringAsFixed(0)} meters.";
    else if (dist > 50)
      msg = "In ${dist.toStringAsFixed(0)} meters, continue straight.";
    else
      msg = "In ${dist.toStringAsFixed(0)} meters you will reach next point.";

    if (_canSpeakAgain()) _speak(msg);
  }

  void _updateNavigationProgress() {
    if (!_isNavigating || myLocation == null || _steps.isEmpty) return;

    final step = _steps[_currentStepIndex];
    final endLat = (step['endLat'] as num).toDouble();
    final endLng = (step['endLng'] as num).toDouble();
    final dist = calculateDistance(
      myLocation!.latitude,
      myLocation!.longitude,
      endLat,
      endLng,
    );

    if (_currentStepIndex == _steps.length - 1 && dist < 20) {
      _speak("You have arrived at your destination.");
      _stopVoiceNavigation();
      return;
    }

    if (dist < 20) {
      _currentStepIndex++;
      if (_currentStepIndex < _steps.length) {
        _speak("Proceeding to next segment.");
        _announceCurrentStep();
        return;
      }
    }

    if (dist < 60) {
      _speakThrottled(
        "In ${dist.toStringAsFixed(0)} meters, continue straight.",
        12,
      );
    } else if (dist < 200)
      _speakThrottled(
        "Continue straight. ${dist.toStringAsFixed(0)} meters remaining.",
        20,
      );
    else
      _speakThrottled("${dist.toStringAsFixed(0)} meters remaining.", 30);
  }

  bool _canSpeakAgain([int seconds = 4]) {
    if (_lastSpeakTime == null ||
        DateTime.now().difference(_lastSpeakTime!) >
            Duration(seconds: seconds)) {
      _lastSpeakTime = DateTime.now();
      return true;
    }
    return false;
  }

  void _speakThrottled(String msg, int seconds) {
    if (_lastSpeakTime == null ||
        DateTime.now().difference(_lastSpeakTime!) >
            Duration(seconds: seconds)) {
      _lastSpeakTime = DateTime.now();
      _speak(msg);
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void _updateMarkersAndPolyline() {
    if (!mounted) return;
    markers.clear();
    polylines.clear();

    if (myLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: myLocation!,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (otherLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('other'),
          position: otherLocation!,
          infoWindow: const InfoWindow(title: 'Friend'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      if (myLocation != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('path'),
            points: [myLocation!, otherLocation!],
            color: Colors.blueAccent,
            width: 5,
          ),
        );
      }
      if (widget.isReceiver && myLocation != null) {
        distanceInMeters = calculateDistance(
          myLocation!.latitude,
          myLocation!.longitude,
          otherLocation!.latitude,
          otherLocation!.longitude,
        );
      }
    }

    if (widget.destination != null &&
        myLocation != null &&
        !widget.isReceiver) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('destination_route'),
          points: [myLocation!, widget.destination!],
          color: Colors.red,
          width: 4,
        ),
      );
      distanceInMeters = calculateDistance(
        myLocation!.latitude,
        myLocation!.longitude,
        widget.destination!.latitude,
        widget.destination!.longitude,
      );
    }

    setState(() {});
  }

  void _sendLocation() async {
    if (myLocation == null) return;
    String mapsUrl =
        "https://www.google.com/maps?q=${myLocation!.latitude},${myLocation!.longitude}";
    await _firestore
        .collection('muazam chatroom')
        .doc(widget.chatroomId)
        .collection('muazam chats')
        .add({
          "sendBy": StaticData.model!.userId,
          "message": mapsUrl,
          "type": "location",
          "time": FieldValue.serverTimestamp(),
        });
    Navigator.pop(context);
  }

  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371000;
    double dLat = _degreesToRadians(endLat - startLat);
    double dLng = _degreesToRadians(endLng - startLng);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLat)) *
            cos(_degreesToRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
  String formatDistance(double meters) => meters < 1000
      ? "${meters.toStringAsFixed(0)} m"
      : "${(meters / 1000).toStringAsFixed(2)} km";

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.liveLocation),
        backgroundColor: Colors.blue,
        actions: [
          if (widget.destination != null)
            IconButton(
              icon: Icon(_isNavigating ? Icons.volume_off : Icons.volume_up),
              onPressed: () {
                if (_isNavigating) {
                  _stopVoiceNavigation();
                } else {
                  _startVoiceNavigation();
                }
              },
            ),
        ],
      ),
      body: myLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: myLocation!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                if (!widget.isReceiver)
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _sendLocation,
                      child: Text(l10n.sendLocation),
                    ),
                  ),
                if (distanceInMeters > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Distance: ${l10n.distance}: ${formatDistance(distanceInMeters)}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (distanceInMeters > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Travel mode buttons
                          Row(
                            children: travelModes.keys.map((mode) {
                              final isSelected = mode == selectedMode;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedMode = mode;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      mode,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // ETA
                          Text(
                            "ETA: ${calculateETA(distanceInMeters)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
