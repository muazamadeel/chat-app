import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/livetracking.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class PlaceDetailPage extends StatefulWidget {
  final String placeId;
  final String apiKey;

  const PlaceDetailPage({
    super.key,
    required this.placeId,
    required this.apiKey,
  });

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  Map? details;
  bool loading = true;

  Position? currentPosition;
  double? distance; // distance in km

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _getCurrentPosition();
  }

  Future<void> _fetchDetails() async {
    final fields = [
      "name",
      "rating",
      "formatted_address",
      "formatted_phone_number",
      "website",
      "opening_hours",
      "photos",
      "reviews",
      "geometry",
      "url",
    ].join(',');

    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${widget.placeId}&fields=$fields&key=${widget.apiKey}";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        details = data["result"];
        loading = false;
      });
      _calculateDistance();
    } else {
      setState(() {
        loading = false;
      });
      debugPrint("Place details fetch failed: ${res.statusCode}");
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _calculateDistance();
    } catch (e) {
      debugPrint("Failed to get current position: $e");
    }
  }

  void _calculateDistance() {
    if (currentPosition != null &&
        details != null &&
        details!["geometry"] != null) {
      final geometry = details!["geometry"]["location"];
      final placeLatLng = LatLng(geometry["lat"], geometry["lng"]);

      distance =
          Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            placeLatLng.latitude,
            placeLatLng.longitude,
          ) /
          1000; // km

      setState(() {});
    }
  }

  String? _photoUrlFromRef(Map photo) {
    final ref = photo["photo_reference"];
    if (ref == null) return null;
    return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photo_reference=$ref&key=${widget.apiKey}";
  }

  Future<void> _launchUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cannotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (details == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.details)),
        body: Center(child: Text(l10n.noDetailsAvailable)),
      );
    }

    final name = details!["name"] ?? "";
    final rating = details!["rating"]?.toString() ?? "N/A";
    final addr = details!["formatted_address"] ?? "";
    final phone = details!["formatted_phone_number"];
    final website = details!["website"];
    // ignore: unused_local_variable
    final googleMapsUrl = details!["url"];
    final openingHours = details!["opening_hours"]?["weekday_text"] ?? [];
    final photos = details!["photos"] ?? [];
    final reviews = details!["reviews"] ?? [];
    final geometry = details!["geometry"]?["location"];
    LatLng? placeLatLng;
    if (geometry != null) {
      placeLatLng = LatLng(geometry["lat"], geometry["lng"]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(name), backgroundColor: Colors.blueAccent),
      body: ListView(
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 240,
              child: PageView(
                children: photos.map<Widget>((p) {
                  final url = _photoUrlFromRef(p);
                  return url != null
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(color: Colors.grey[300]);
                }).toList(),
              ),
            )
          else
            Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.image, size: 80)),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE + RATING
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(rating),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(addr, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),

                /// CALL / WEBSITE / DIRECTIONS BUTTONS
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (phone != null)
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl("tel:$phone"),
                        icon: const Icon(Icons.call),
                        label: Text(l10n.call),
                      ),
                    if (website != null)
                      OutlinedButton.icon(
                        onPressed: () => _launchUrl(website),
                        icon: const Icon(Icons.language),
                        label: Text(l10n.website),
                      ),
                    if (placeLatLng != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveTracking(
                                chatroomId: "place_direction",
                                isReceiver: false,
                                destination: placeLatLng!,
                                apiKey:
                                    "AIzaSyC2fWxeerzaACQnhahbU85T83o4fTTOszw",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions),
                        label: Text(l10n.directions),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                /// OPENING HOURS
                if (openingHours.isNotEmpty) ...[
                  Text(
                    l10n.openingHours,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...openingHours.map((d) => Text(d)).toList(),
                  const SizedBox(height: 12),
                ],

                /// REVIEWS
                Text(
                  l10n.reviews,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (reviews.isEmpty)
                  Text(l10n.noReviews)
                else
                  Column(
                    children: reviews.map<Widget>((r) {
                      final author = r["author_name"] ?? "User";
                      final text = r["text"] ?? "";
                      final authorRating = r["rating"]?.toString() ?? "";
                      final time = r["relative_time_description"] ?? "";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(child: Text(author[0])),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "$authorRating · $time",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(text),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
