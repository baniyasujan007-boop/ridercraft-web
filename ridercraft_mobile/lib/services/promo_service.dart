import '../models/promo.dart';
import 'api_client.dart';

/// Promo / coupon endpoints. The backend remains the source of truth for
/// discount calculation — the app only validates and redeems against it.
///
/// Endpoints:
/// - GET /promos/active
/// - POST /promos/validate {code, subtotal, shipping?}
/// - POST /promos/redeem  {code, subtotal, shipping?}
class PromoService {
  final ApiClient _api;

  PromoService(this._api);

  Future<List<Promo>> listActivePromos() async {
    final data = await _api.get('/promos/active');
    if (data is! List) return <Promo>[];
    return data
        .map((item) => Promo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Validates a code against the backend and returns the server-computed
  /// discount. Throws [ApiException] with the server's message if invalid.
  Future<PromoValidation> validate({
    required String code,
    required double subtotal,
    double shipping = 0,
  }) async {
    final data = await _api.post(
      '/promos/validate',
      data: {
        'code': code,
        'subtotal': subtotal,
        'shipping': shipping,
      },
    );
    return PromoValidation.fromJson(data as Map<String, dynamic>);
  }

  /// Redeems a code. Returns the applied discount amount.
  Future<PromoValidation> redeem({
    required String code,
    required double subtotal,
    double shipping = 0,
  }) async {
    final data = await _api.post(
      '/promos/redeem',
      data: {
        'code': code,
        'subtotal': subtotal,
        'shipping': shipping,
      },
    );
    return PromoValidation.fromJson(data as Map<String, dynamic>);
  }
}
