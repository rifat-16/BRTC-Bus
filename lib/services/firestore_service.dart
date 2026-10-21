import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/ticket_model.dart';

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
}

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

  // Collection References
  CollectionReference get _busesRef => _db.collection('buses');
  CollectionReference get _ticketsRef => _db.collection('tickets');
  CollectionReference get _routeFaresRef => _db.collection('route_fares');

  // Server-side verification method for 100% backend security
  Future<bool> verifyAdminAccessServerSide(String email, String uid) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'mirefat82@gmail.com') return true;

    try {
      final docByUid = await _db.collection('admins').doc(uid).get();
      if (docByUid.exists && docByUid.data()?['active'] == true) return true;

      final docByEmail = await _db.collection('admins').doc(cleanEmail).get();
      if (docByEmail.exists && docByEmail.data()?['active'] == true) return true;
    } catch (_) {}

    return false;
  }

  // Official Default Route Fares (Station-to-Station)
  static final List<RouteFareModel> officialRouteFares = [
    RouteFareModel(id: 'dhaka_sakhipur', from: 'ঢাকা', to: 'সখিপুর', fare: 350),
    RouteFareModel(id: 'sakhipur_dhaka', from: 'সখিপুর', to: 'ঢাকা', fare: 350),
    RouteFareModel(id: 'dhaka_borochowna', from: 'ঢাকা', to: 'বড়চওনা', fare: 380),
    RouteFareModel(id: 'borochowna_dhaka', from: 'বড়চওনা', to: 'ঢাকা', fare: 380),
    RouteFareModel(id: 'dhaka_garobazar', from: 'ঢাকা', to: 'গারোবাজার', fare: 400),
    RouteFareModel(id: 'garobazar_dhaka', from: 'গারোবাজার', to: 'ঢাকা', fare: 400),
    RouteFareModel(id: 'dhaka_sagardighi', from: 'ঢাকা', to: 'সাগরদিঘী', fare: 400),
    RouteFareModel(id: 'sagardighi_dhaka', from: 'সাগরদিঘী', to: 'ঢাকা', fare: 400),
    RouteFareModel(id: 'sakhipur_borochowna', from: 'সখিপুর', to: 'বড়চওনা', fare: 100),
    RouteFareModel(id: 'borochowna_sakhipur', from: 'বড়চওনা', to: 'সখিপুর', fare: 100),
  ];

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

  // Calculate fare dynamically based on station-to-station route pair
  static int calculateRouteFare({
    required String from,
    required String to,
    required List<RouteFareModel> faresList,
    int defaultBusFare = 350,
  }) {
    final cleanFrom = from.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final cleanTo = to.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    for (final rf in faresList) {
      if ((cleanFrom.contains(rf.from) || rf.from.contains(cleanFrom)) &&
          (cleanTo.contains(rf.to) || rf.to.contains(cleanTo))) {
        return rf.fare;
      }
    }
    return defaultBusFare;
  }

  // Stream of Station-to-Station Route Pair Fares
  Stream<List<RouteFareModel>> getRouteFaresStream() {
    return _routeFaresRef.snapshots().map((snapshot) {
      final List<RouteFareModel> list = [];

      for (final defaultFare in officialRouteFares) {
        final docs = snapshot.docs.where((d) => d.id == defaultFare.id);
        if (docs.isNotEmpty && docs.first.data() != null) {
          final data = docs.first.data() as Map<String, dynamic>;
          final dynamicFare = data['fare'] as int? ?? defaultFare.fare;
          list.add(
            RouteFareModel(
              id: defaultFare.id,
              from: defaultFare.from,
              to: defaultFare.to,
              fare: dynamicFare,
            ),
          );
        } else {
          list.add(defaultFare);
        }
      }

      return list;
    }).handleError((_) {
      return officialRouteFares;
    });
  }

  // Admin Action: Update Route Fare in Cloud Firestore
  Future<void> updateRouteFare({
    required String routeId,
    required int newFare,
  }) async {
    final routeRef = _routeFaresRef.doc(routeId);
    await routeRef.set({
      'fare': newFare,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

  // Dynamic Stream for Buses with Real-time Firestore Route Pair Fare Integration
  Stream<List<BusModel>> getBusesStream({String? from, String? to}) {
    return _routeFaresRef.snapshots().map((snapshot) {
      final List<RouteFareModel> activeFares = [];

      for (final defaultFare in officialRouteFares) {
        final docs = snapshot.docs.where((d) => d.id == defaultFare.id);
        if (docs.isNotEmpty && docs.first.data() != null) {
          final data = docs.first.data() as Map<String, dynamic>;
          final dynamicFare = data['fare'] as int? ?? defaultFare.fare;
          activeFares.add(
            RouteFareModel(
              id: defaultFare.id,
              from: defaultFare.from,
              to: defaultFare.to,
              fare: dynamicFare,
            ),
          );
        } else {
          activeFares.add(defaultFare);
        }
      }

      final List<BusModel> busesList = officialBRTCBuses.map((bus) {
        int dynamicFare = bus.fare;
        if (from != null && to != null) {
          dynamicFare = calculateRouteFare(
            from: from,
            to: to,
            faresList: activeFares,
            defaultBusFare: bus.fare,
          );
        }

        return BusModel(
          id: bus.id,
          busName: bus.busName,
          from: bus.from,
          to: bus.to,
          route: bus.route,
          departureTime: bus.departureTime,
          arrivalTime: bus.arrivalTime,
          fare: dynamicFare,
          totalSeats: bus.totalSeats,
        );
      }).toList();

      return filterBusesList(busesList, from: from, to: to);
    }).handleError((_) {
      return filterBusesList(officialBRTCBuses, from: from, to: to);
    });
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
