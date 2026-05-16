class StatusTileModel {
  final String userId;
  final String name;
  final List<Map<String, dynamic>> statuses;
  final bool hasUnViewed;
  final DateTime lastStatusTime;

  StatusTileModel({
    required this.userId,
    required this.name,
    required this.statuses,
    required this.hasUnViewed,
    required this.lastStatusTime,
  });
}
