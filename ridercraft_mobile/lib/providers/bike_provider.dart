import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/bike.dart';
import '../services/storage_service.dart';

/// Manages the rider's bikes, persisted locally (no backend Bike endpoints
/// exist). Used by the My Bike screen and the booking flow.
class BikeProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Bike> _bikes = [];
  String? _selectedBikeId;
  bool _loaded = false;

  BikeProvider(this._storage);

  List<Bike> get bikes => List.unmodifiable(_bikes);
  bool get loaded => _loaded;

  Bike? get selectedBike {
    for (final bike in _bikes) {
      if (bike.id == _selectedBikeId) return bike;
    }
    return _bikes.isEmpty ? null : _bikes.first;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await _storage.readBikes();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _bikes = (decoded['bikes'] as List? ?? [])
            .map((e) => Bike.fromJson(e as Map<String, dynamic>))
            .toList();
        _selectedBikeId = decoded['selectedId'] as String?;
      }
    } catch (_) {
      // Corrupt/unreadable local data degrades to an empty garage rather
      // than crashing the app.
      _bikes = [];
      _selectedBikeId = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addBike(Bike bike) async {
    _bikes.insert(0, bike);
    _selectedBikeId ??= bike.id;
    await _persist();
    notifyListeners();
  }

  Future<void> updateBike(Bike bike) async {
    final index = _bikes.indexWhere((e) => e.id == bike.id);
    if (index < 0) return;
    _bikes[index] = bike;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteBike(String id) async {
    _bikes.removeWhere((e) => e.id == id);
    if (_selectedBikeId == id) _selectedBikeId = null;
    await _persist();
    notifyListeners();
  }

  Future<void> selectBike(String id) async {
    _selectedBikeId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.writeBikes(jsonEncode({
      'bikes': _bikes.map((bike) => bike.toJson()).toList(),
      'selectedId': _selectedBikeId,
    }));
  }
}
