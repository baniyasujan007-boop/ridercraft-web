import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/promo.dart';
import '../services/promo_service.dart';
import '../services/storage_service.dart';

/// Persistent, provider-driven shopping cart.
///
/// Cart data lives on the device (the backend has no cart endpoint). Prices
/// come from [Product.displayPrice] which is computed server-side. Promo
/// discount is validated against the backend before being applied.
class CartProvider extends ChangeNotifier {
  final StorageService _storage;
  final PromoService _promoService;

  List<CartItem> _items = [];
  PromoValidation? _appliedPromo;
  bool _loaded = false;
  bool _applyingPromo = false;
  String? _promoError;

  CartProvider(this._storage, this._promoService);

  List<CartItem> get items => List.unmodifiable(_items);
  PromoValidation? get appliedPromo => _appliedPromo;
  bool get isApplyingPromo => _applyingPromo;
  String? get promoError => _promoError;

  int get count => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get discount => _appliedPromo?.discountAmount ?? 0;

  double get total {
    final value = subtotal - discount;
    return value < 0 ? 0 : value;
  }

  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.readCart();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => _fromStored(e as Map<String, dynamic>))
            .whereType<CartItem>()
            .toList();
      } catch (_) {
        _items = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  CartItem? _fromStored(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    if (productJson == null) return null;
    return CartItem(
      product: Product.fromJson(productJson),
      variantId: (json['variantId'] ?? '') as String,
      variantSku: (json['variantSku'] ?? '') as String,
      color: (json['color'] ?? '') as String,
      colorHex: (json['colorHex'] ?? '') as String,
      size: (json['size'] ?? '') as String,
      quantity: ((json['quantity'] ?? 1) as num).toInt().clamp(1, 99),
    );
  }

  Future<void> _persist() async {
    final payload = _items
        .map(
          (item) => {
            'product': item.product.toJson(),
            'variantId': item.variantId,
            'variantSku': item.variantSku,
            'color': item.color,
            'colorHex': item.colorHex,
            'size': item.size,
            'quantity': item.quantity,
          },
        )
        .toList();
    await _storage.writeCart(jsonEncode(payload));
  }

  Future<void> addProduct(
    Product product, {
    String variantId = '',
    String variantSku = '',
    String color = '',
    String colorHex = '',
    String size = '',
    int quantity = 1,
  }) async {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.variantId == variantId &&
          item.color == color &&
          item.size == size,
    );
    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      final newQty = (existing.quantity + quantity).clamp(1, 99);
      _items[existingIndex] = existing.copyWith(quantity: newQty);
    } else {
      _items.add(
        CartItem(
          product: product,
          variantId: variantId,
          variantSku: variantSku,
          color: color,
          colorHex: colorHex,
          size: size,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
    await _persist();
  }

  Future<void> increment(int index) async {
    final current = _items[index];
    if (current.quantity >= 99) return;
    _items[index] = current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
    await _persist();
  }

  Future<void> decrement(int index) async {
    final current = _items[index];
    if (current.quantity <= 1) return;
    _items[index] = current.copyWith(quantity: current.quantity - 1);
    notifyListeners();
    await _persist();
  }

  Future<void> removeItem(int index) async {
    _items.removeAt(index);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    _appliedPromo = null;
    _promoError = null;
    notifyListeners();
    await _storage.clearCart();
  }

  /// Validates the code against the backend (source of truth) and applies the
  /// returned discount. Returns false and sets [promoError] if invalid.
  Future<bool> applyPromo(String code) async {
    _applyingPromo = true;
    _promoError = null;
    notifyListeners();
    try {
      final validation = await _promoService.validate(
        code: code,
        subtotal: subtotal,
      );
      _appliedPromo = validation;
      notifyListeners();
      await _persist();
      return true;
    } catch (error) {
      _promoError = error.toString();
      _appliedPromo = null;
      notifyListeners();
      return false;
    } finally {
      _applyingPromo = false;
      notifyListeners();
    }
  }

  Future<void> removePromo() async {
    _appliedPromo = null;
    _promoError = null;
    notifyListeners();
    await _persist();
  }
}
