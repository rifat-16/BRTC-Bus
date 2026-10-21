class RouteFareModel {
  final String id;
  final String from;
  final String to;
  final int fare;

  RouteFareModel({
    required this.id,
    required this.from,
    required this.to,
    required this.fare,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'fare': fare,
    };
  }

  factory RouteFareModel.fromMap(String docId, Map<String, dynamic> map) {
    return RouteFareModel(
      id: docId,
      from: map['from'] as String? ?? '',
      to: map['to'] as String? ?? '',
      fare: (map['fare'] as num?)?.toInt() ?? 350,
    );
  }
}
