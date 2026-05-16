import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'place_details_page.dart';

class NearbySearchMap extends StatefulWidget {
  const NearbySearchMap({super.key});

  @override
  State<NearbySearchMap> createState() => _NearbySearchMapState();
}

class _NearbySearchMapState extends State<NearbySearchMap> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const String googleApiKey = "AIzaSyC2fWxeerzaACQnhahbU85T83o4fTTOszw";

  LatLng? currentPosition;
  Set<Marker> _markers = {};
  bool isLoading = true;

  String? selectedName;
  String? selectedAddress;
  String? selectedImage;
  LatLng? selectedLatLng;
  String? selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
      isLoading = false;
    });

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(currentPosition!, 15));
  }

  Future<void> _searchNearbyPlaces(String keyword) async {
    if (currentPosition == null || keyword.isEmpty) return;

    final lat = currentPosition!.latitude;
    final lng = currentPosition!.longitude;

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=${Uri.encodeComponent(keyword)}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "OK") {
        final List results = data["results"];

        Set<Marker> markers = {};
        for (var place in results) {
          final LatLng loc = LatLng(
            place["geometry"]["location"]["lat"],
            place["geometry"]["location"]["lng"],
          );

          String? photoUrl;
          if (place["photos"] != null && place["photos"].isNotEmpty) {
            final photoRef = place["photos"][0]["photo_reference"];
            photoUrl =
                "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=$googleApiKey";
          }

          final placeId = place["place_id"];

          markers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: loc,
              infoWindow: InfoWindow(title: place["name"]),
              onTap: () {
                setState(() {
                  selectedLatLng = loc;
                  selectedName = place["name"];
                  selectedAddress = place["vicinity"] ?? "";
                  selectedImage = photoUrl;
                  selectedPlaceId = placeId;
                });
              },
            ),
          );
        }

        setState(() {
          _markers = markers;
          selectedLatLng = null;
        });

        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(currentPosition!, 13),
        );
      } else {
        print("No results found: ${data["status"]}");
      }
    } else {
      print("Failed to fetch nearby places: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyPlacesSearch),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (!isLoading && currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                if (!_controller.isCompleted) _controller.complete(controller);
              },
              onTap: (_) => setState(() => selectedLatLng = null),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Search bar
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchNearbyHint,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blueAccent),
                    onPressed: () {
                      _searchNearbyPlaces(_searchController.text);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Info card when marker tapped
          if (selectedLatLng != null)
            Positioned(
              top: height / 2.5,
              left: width / 7,
              right: width / 7,
              child: GestureDetector(
                onTap: () {
                  if (selectedPlaceId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailPage(
                          placeId: selectedPlaceId!,
                          apiKey: googleApiKey,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.noPlaceIdAvailable)),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            selectedImage!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 40),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedName ?? l10n.unknown,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedAddress ?? "",
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          if (currentPosition != null) {
            final controller = await _controller.future;
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(currentPosition!, 15),
            );
          }
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
