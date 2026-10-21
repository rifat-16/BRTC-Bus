import 'package:flutter/material.dart';
import '../models/bus_model.dart';

class BookingProvider with ChangeNotifier {
  String _selectedFrom = 'ঢাকা';
  String _selectedTo = 'সখিপুর';
  DateTime _journeyDate = DateTime.now();

  BusModel? _selectedBus;
  final List<String> _selectedSeats = [];

  // Controllers for Checkout
  String _passengerName = '';
  String _passengerPhone = '';
  String _paymentMethod = 'bKash';
  String _trxId = '';

  // Getters
  String get selectedFrom => _selectedFrom;
  String get selectedTo => _selectedTo;
  DateTime get journeyDate => _journeyDate;
  BusModel? get selectedBus => _selectedBus;
  List<String> get selectedSeats => List.unmodifiable(_selectedSeats);

  String get passengerName => _passengerName;
  String get passengerPhone => _passengerPhone;
  String get paymentMethod => _paymentMethod;
  String get trxId => _trxId;

  int get totalSeatsCount => _selectedSeats.length;
  int get totalPrice =>
      _selectedBus != null ? _selectedSeats.length * _selectedBus!.fare : 0;

  void updateRouteFilter(String from, String to) {
    _selectedFrom = from;
    _selectedTo = to;
    notifyListeners();
  }

  void updateJourneyDate(DateTime date) {
    _journeyDate = date;
    notifyListeners();
  }

  void selectBus(BusModel bus) {
    _selectedBus = bus;
    _selectedSeats.clear();
    notifyListeners();
  }

  void toggleSeat(String seatId) {
    if (_selectedSeats.contains(seatId)) {
      _selectedSeats.remove(seatId);
    } else {
      if (_selectedSeats.length < 6) {
        _selectedSeats.add(seatId);
      }
    }
    notifyListeners();
  }

  void clearSelectedSeats() {
    _selectedSeats.clear();
    notifyListeners();
  }

  void setCheckoutDetails({
    required String name,
    required String phone,
    required String method,
    required String trx,
  }) {
    _passengerName = name;
    _passengerPhone = phone;
    _paymentMethod = method;
    _trxId = trx;
    notifyListeners();
  }

  void resetBooking() {
    _selectedBus = null;
    _selectedSeats.clear();
    _passengerName = '';
    _passengerPhone = '';
    _trxId = '';
    notifyListeners();
  }
}
