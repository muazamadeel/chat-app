import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class SendLocationScreen extends StatefulWidget {
  final LatLng currentLatLng;
  final Function(LatLng) onSend;

  const SendLocationScreen({
    super.key,
    required this.currentLatLng,
    required this.onSend,
  });

  @override
  State<SendLocationScreen> createState() => _SendLocationScreenState();
}

class _SendLocationScreenState extends State<SendLocationScreen> {
  // ignore: unused_field
  late GoogleMapController _mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: widget.currentLatLng,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendLocation),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentLatLng,
              zoom: 16,
            ),
            markers: markers,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                widget.onSend(widget.currentLatLng);
                Navigator.pop(context);
              },
              child: Text(l10n.sendLocation),
            ),
          ),
        ],
      ),
    );
  }
}
