import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? ticketId;
  final String busId;
  final String userId;
  final String userEmail;
  final String busName;
  final String from;
  final String to;
  final String journeyDate;
  final List<String> selectedSeats;
  final int totalAmount;
  final String passengerName;
  final String passengerPhone;
  final String paymentMethod;
  final String trxId;
  final String status;
  final DateTime? createdAt;

  TicketModel({
    this.ticketId,
    this.busId = '',
    required this.userId,
    required this.userEmail,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDate,
    required this.selectedSeats,
    required this.totalAmount,
    required this.passengerName,
    required this.passengerPhone,
    required this.paymentMethod,
    required this.trxId,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory TicketModel.fromMap(String id, Map<String, dynamic> map) {
    return TicketModel(
      ticketId: id,
      busId: map['busId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      busName: map['busName'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      journeyDate: map['journeyDate'] ?? '',
      selectedSeats: List<String>.from(map['selectedSeats'] ?? []),
      totalAmount: map['totalAmount'] ?? 0,
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      trxId: map['trxId'] ?? '',
      status: map['status'] ?? 'PENDING',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'userId': userId,
      'userEmail': userEmail,
      'busName': busName,
      'from': from,
      'to': to,
      'journeyDate': journeyDate,
      'selectedSeats': selectedSeats,
      'totalAmount': totalAmount,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'paymentMethod': paymentMethod,
      'trxId': trxId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
