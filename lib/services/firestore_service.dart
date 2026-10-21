import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/ticket_model.dart';

class ScheduleSeatsData {
  final List<String> bookedSeats;
  final List<String> lockedSeats;

  ScheduleSeatsData({
    required this.bookedSeats,
    required this.lockedSeats,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References for dynamic seat locking & ticket creation
  CollectionReference get _busesRef => _db.collection('buses');
  CollectionReference get _ticketsRef => _db.collection('tickets');

  // Exact 2 Physical Official BRTC AC Buses
  static final List<BusModel> officialBRTCBuses = [
    // --- 1. BUS 1: BRTC AC SERVICE - 1 (Super: 01624-622614) ---
    BusModel(
      id: 'brtc_ac_1_going',
      busName: 'BRTC AC Service - 1 (০১৬২৪-৬২২৬১৪)',
      from: 'বড়চওনা / সখিপুর',
      to: 'ঢাকা',
      route: 'বড়চওনা (05:20 AM) ➔ সখিপুর (06:00 AM) ➔ ঢাকা',
      departureTime: '05:20 AM (বড়চওনা) / 06:00 AM (সখিপুর)',
      arrivalTime: '09:15 AM (ঢাকা)',
      fare: 350,
      totalSeats: 45,
    ),
    BusModel(
      id: 'brtc_ac_1_return',
      busName: 'BRTC AC Service - 1 (ফিরতী)',
      from: 'ঢাকা',
      to: 'সখিপুর / বড়চওনা',
      route: 'ঢাকা (06:00 PM) ➔ সখিপুর ➔ বড়চওনা',
      departureTime: '06:00 PM (ঢাকা)',
      arrivalTime: '09:30 PM (বড়চওনা)',
      fare: 350,
      totalSeats: 45,
    ),

    // --- 2. BUS 2: BRTC AC SERVICE - 2 (Super: 01352-203560) ---
    BusModel(
      id: 'brtc_ac_2_going',
      busName: 'BRTC AC Service - 2 (০১৩৫২-২০৩৫৬০)',
      from: 'গারোবাজার / সাগরদিঘী / সখিপুর',
      to: 'ঢাকা',
      route: 'গারোবাজার (05:15 AM) ➔ সাগরদিঘী (05:50 AM) ➔ সখিপুর (06:50 AM) ➔ ঢাকা',
      departureTime: '05:15 AM (গারোবাজার) / 05:50 AM (সাগরদিঘী) / 06:50 AM (সখিপুর)',
      arrivalTime: '09:45 AM (ঢাকা)',
      fare: 400,
      totalSeats: 45,
    ),
    BusModel(
      id: 'brtc_ac_2_return',
      busName: 'BRTC AC Service - 2 (ফিরতী)',
      from: 'ঢাকা',
      to: 'সখিপুর / সাগরদিঘী / গারোবাজার',
      route: 'ঢাকা (সচিবালয় 03:30 PM / খামার বাড়ী 04:15 PM) ➔ সখিপুর ➔ সাগরদিঘী ➔ গারোবাজার',
      departureTime: '03:30 PM (সচিবালয়) / 04:15 PM (খামার বাড়ী মোড়)',
      arrivalTime: '08:00 PM (গারোবাজার)',
      fare: 400,
      totalSeats: 45,
    ),
  ];

  // Helper filter method for strict directional location matching
  static List<BusModel> filterBusesList(
    List<BusModel> list, {
    String? from,
    String? to,
  }) {
    if (from == null && to == null) return list;

    final cleanFrom =
        (from ?? '').replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();
    final cleanTo =
        (to ?? '').replaceAll(RegExp(r'\([^)]*\)'), '').trim().toLowerCase();

    return list.where((bus) {
      final busFrom = bus.from.toLowerCase();
      final busTo = bus.to.toLowerCase();
      final busRoute = bus.route.toLowerCase();

      bool matchesFrom = cleanFrom.isEmpty ||
          busFrom.contains(cleanFrom) ||
          busRoute.contains(cleanFrom);
      bool matchesTo = cleanTo.isEmpty ||
          busTo.contains(cleanTo) ||
          busRoute.contains(cleanTo);

      if (cleanTo.contains('ঢাকা') && !busTo.contains('ঢাকা')) {
        return false;
      }
      if (cleanFrom.contains('ঢাকা') && !busFrom.contains('ঢাকা')) {
        return false;
      }

      return matchesFrom && matchesTo;
    }).toList();
  }

  // Pure Local Stream for Fixed Official BRTC Schedules
  Stream<List<BusModel>> getBusesStream({String? from, String? to}) {
    return Stream.value(filterBusesList(officialBRTCBuses, from: from, to: to));
  }

  // Get real-time stream of schedule seats (both booked and locked seats)
  Stream<ScheduleSeatsData> getScheduleSeatsStream({
    required String busId,
    required String journeyDate,
  }) {
    final dateDocId = journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef = _busesRef.doc(busId).collection('schedules').doc(dateDocId);

    return scheduleRef.snapshots().map((docSnapshot) {
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
      }
      final data = docSnapshot.data()!;
      final booked = List<String>.from(data['bookedSeats'] ?? []);
      final locked = List<String>.from(data['lockedSeats'] ?? []);
      return ScheduleSeatsData(bookedSeats: booked, lockedSeats: locked);
    }).handleError((_) {
      return ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
    });
  }

  // Legacy Stream method for backward compatibility
  Stream<List<String>> getBookedSeatsStream({
    required String busId,
    required String journeyDate,
  }) {
    return getScheduleSeatsStream(busId: busId, journeyDate: journeyDate).map(
      (seats) => [...seats.bookedSeats, ...seats.lockedSeats],
    );
  }

  // Book seats and write ticket directly to Cloud Firestore
  Future<TicketModel> bookSeatsAndCreateTicket({
    required String busId,
    required TicketModel ticket,
  }) async {
    final dateDocId =
        ticket.journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef =
        _busesRef.doc(busId).collection('schedules').doc(dateDocId);
    final newTicketRef = _ticketsRef.doc();

    final ticketMap = ticket.toMap();
    ticketMap['ticketId'] = newTicketRef.id;

    final bool isConfirmed = ticket.status == 'CONFIRMED';

    try {
      await scheduleRef.set({
        if (isConfirmed)
          'bookedSeats': FieldValue.arrayUnion(ticket.selectedSeats)
        else
          'lockedSeats': FieldValue.arrayUnion(ticket.selectedSeats),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await newTicketRef.set(ticketMap);
    } catch (e) {
      try {
        await newTicketRef.set(ticketMap);
      } catch (_) {}
    }

    return TicketModel(
      ticketId: newTicketRef.id.isNotEmpty
          ? newTicketRef.id
          : 'TKT-${DateTime.now().millisecondsSinceEpoch}',
      busId: busId,
      userId: ticket.userId,
      userEmail: ticket.userEmail,
      busName: ticket.busName,
      from: ticket.from,
      to: ticket.to,
      journeyDate: ticket.journeyDate,
      selectedSeats: ticket.selectedSeats,
      totalAmount: ticket.totalAmount,
      passengerName: ticket.passengerName,
      passengerPhone: ticket.passengerPhone,
      paymentMethod: ticket.paymentMethod,
      trxId: ticket.trxId,
      status: ticket.status,
      createdAt: DateTime.now(),
    );
  }

  // Stream of All Tickets for Admin Portal
  Stream<List<TicketModel>> getAllTicketsStream() {
    return _ticketsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    }).handleError((_) => <TicketModel>[]);
  }

  // Admin Action: Approve Ticket (Moves seats from lockedSeats to bookedSeats)
  Future<void> approveTicket({
    required String ticketId,
    required String busId,
    required String journeyDate,
    required List<String> selectedSeats,
  }) async {
    final dateDocId = journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef =
        _busesRef.doc(busId).collection('schedules').doc(dateDocId);

    try {
      await scheduleRef.set({
        'lockedSeats': FieldValue.arrayRemove(selectedSeats),
        'bookedSeats': FieldValue.arrayUnion(selectedSeats),
      }, SetOptions(merge: true));

      await _ticketsRef.doc(ticketId).update({
        'status': 'CONFIRMED',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Admin Action: Reject Ticket and Release Seats
  Future<void> rejectTicket({
    required String busId,
    required String journeyDate,
    required List<String> selectedSeats,
    required String ticketId,
  }) async {
    final dateDocId = journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef =
        _busesRef.doc(busId).collection('schedules').doc(dateDocId);

    try {
      await scheduleRef.set({
        'lockedSeats': FieldValue.arrayRemove(selectedSeats),
        'bookedSeats': FieldValue.arrayRemove(selectedSeats),
      }, SetOptions(merge: true));

      await _ticketsRef.doc(ticketId).update({
        'status': 'REJECTED',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      try {
        await _ticketsRef.doc(ticketId).update({
          'status': 'REJECTED',
        });
      } catch (_) {}
    }
  }

  // Real-time Stream for a Single Ticket
  Stream<TicketModel?> getTicketStream(String ticketId) {
    return _ticketsRef.doc(ticketId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).handleError((_) => null);
  }

  // Stream of User Purchased Tickets
  Stream<List<TicketModel>> getUserTicketsStream(String userId) {
    final String targetId = userId.isEmpty ? 'guest' : userId;

    return _ticketsRef
        .where('userId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    }).handleError((_) => <TicketModel>[]);
  }

  // Admin Action: Manually lock seats for counter sales or maintenance
  Future<void> manuallyLockSeats({
    required String busId,
    required String journeyDate,
    required List<String> seats,
  }) async {
    final dateDocId = journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef =
        _busesRef.doc(busId).collection('schedules').doc(dateDocId);

    await scheduleRef.set({
      'lockedSeats': FieldValue.arrayUnion(seats),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Admin Action: Manually unlock seats
  Future<void> manuallyUnlockSeats({
    required String busId,
    required String journeyDate,
    required List<String> seats,
  }) async {
    final dateDocId = journeyDate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final scheduleRef =
        _busesRef.doc(busId).collection('schedules').doc(dateDocId);

    await scheduleRef.set({
      'lockedSeats': FieldValue.arrayRemove(seats),
      'bookedSeats': FieldValue.arrayRemove(seats),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Admin Action: Issue ticket directly at counter (Immediate CONFIRMED)
  Future<TicketModel> issueCounterTicket({
    required String busId,
    required TicketModel ticket,
  }) async {
    final counterTicket = TicketModel(
      ticketId: ticket.ticketId,
      busId: busId,
      userId: ticket.userId,
      userEmail: ticket.userEmail,
      busName: ticket.busName,
      from: ticket.from,
      to: ticket.to,
      journeyDate: ticket.journeyDate,
      selectedSeats: ticket.selectedSeats,
      totalAmount: ticket.totalAmount,
      passengerName: ticket.passengerName,
      passengerPhone: ticket.passengerPhone,
      paymentMethod: 'COUNTER CASH',
      trxId:
          'COUNTER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'CONFIRMED',
      createdAt: DateTime.now(),
    );

    return await bookSeatsAndCreateTicket(
      busId: busId,
      ticket: counterTicket,
    );
  }
}
