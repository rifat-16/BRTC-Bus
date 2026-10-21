import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';

class AdminProvider with ChangeNotifier {
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  // Seat Manager Tab State
  BusModel _seatManagerBus = FirestoreService.officialBRTCBuses.first;
  DateTime _seatManagerDate = DateTime.now();

  // Counter Sales Tab State
  BusModel _counterBus = FirestoreService.officialBRTCBuses.first;
  DateTime _counterDate = DateTime.now();

  // Getters
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  BusModel get seatManagerBus => _seatManagerBus;
  DateTime get seatManagerDate => _seatManagerDate;

  BusModel get counterBus => _counterBus;
  DateTime get counterDate => _counterDate;

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void updateSeatManagerBus(BusModel bus) {
    _seatManagerBus = bus;
    notifyListeners();
  }

  void updateSeatManagerDate(DateTime date) {
    _seatManagerDate = date;
    notifyListeners();
  }

  void updateCounterBus(BusModel bus) {
    _counterBus = bus;
    notifyListeners();
  }

  void updateCounterDate(DateTime date) {
    _counterDate = date;
    notifyListeners();
  }
}
