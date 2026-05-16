import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapscreen extends StatefulWidget {
  const GoogleMapscreen({super.key});

  @override
  State<GoogleMapscreen> createState() => _GoogleMapscreenState();
}

class _GoogleMapscreenState extends State<GoogleMapscreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _initialposition = CameraPosition(
    target: LatLng(29.40559381151884, 71.69902525394913),
    zoom: 14,
  );
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GoogleMap(
          initialCameraPosition: _initialposition,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),
    );
  }
}
