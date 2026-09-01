class StationSession {
  final String token;
  final int operatorId;
  final String operatorCode;
  final int userId;
  final String operatorName;
  final int stationId;
  final String stationName;
  final String? licenseNo;
  final String? regionZone;
  final String? status;
  final int expiresIn;

  const StationSession({
    required this.token,
    required this.operatorId,
    required this.operatorCode,
    required this.userId,
    required this.operatorName,
    required this.stationId,
    required this.stationName,
    required this.expiresIn,
    this.licenseNo,
    this.regionZone,
    this.status,
  });

  factory StationSession.fromLoginJson(Map<String, dynamic> json) {
    final operator = Map<String, dynamic>.from(json['operator'] ?? {});
    final station = Map<String, dynamic>.from(json['station'] ?? {});

    return StationSession(
      token: json['token']?.toString() ?? '',
      operatorId: int.tryParse(operator['id']?.toString() ?? '') ?? 0,
      operatorCode: operator['operator_code']?.toString() ?? '',
      userId: int.tryParse(operator['user_id']?.toString() ?? '') ?? 0,
      operatorName: operator['name']?.toString() ?? '',
      stationId: int.tryParse(station['id']?.toString() ?? '') ?? 0,
      stationName: station['station_name']?.toString() ?? '',
      licenseNo: station['license_no']?.toString(),
      regionZone: station['region_zone']?.toString(),
      status: station['status']?.toString(),
      expiresIn: int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }
}
