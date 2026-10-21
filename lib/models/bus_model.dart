class BusModel {
  final String id;
  final String busName;
  final String from;
  final String to;
  final String route;
  final String departureTime;
  final String arrivalTime;
  final int fare;
  final int totalSeats;

  BusModel({
    required this.id,
    required this.busName,
    required this.from,
    required this.to,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    required this.totalSeats,
  });

  factory BusModel.fromMap(String id, Map<String, dynamic> map) {
    return BusModel(
      id: id,
      busName: map['busName'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      route: map['route'] ?? '',
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      fare: (map['fare'] is int)
          ? map['fare']
          : int.tryParse(map['fare']?.toString().replaceAll(RegExp(r'\D'), '') ?? '300') ?? 300,
      totalSeats: map['totalSeats'] ?? 45,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busName': busName,
      'from': from,
      'to': to,
      'route': route,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'fare': fare,
      'totalSeats': totalSeats,
    };
  }
}
