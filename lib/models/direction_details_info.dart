class DirectionDetailsInfo {
  String? distanceText;
  String? durationText;
  String? distanceValue;
  String? durationValue;
  List<dynamic>? encodedPoints;

  DirectionDetailsInfo({
    this.distanceText,
    this.durationText,
    this.distanceValue,
    this.durationValue,
    this.encodedPoints,
  });

  DirectionDetailsInfo.fromJson(Map<dynamic, dynamic> json) {
    distanceText = json['distance_text'];
    distanceValue = json['distance_value'];
    durationText = json['duration_text'];
    durationValue = json['duration_value'];
    encodedPoints = json['e_points'];
  }
}