import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/bike_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/home_provider.dart';
import 'providers/product_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'services/promo_service.dart';
import 'services/storage_service.dart';
import 'services/token_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final tokenStore = TokenStore();

  // API client that reads the in-memory token per request and, on a rejected
  // token, clears the session through the auth provider.
  late final AuthProvider authProvider;
  final apiClient = ApiClient(
    tokenProvider: () => tokenStore.current,
    onUnauthorized: () {
      tokenStore.current = null;
      authProvider.handleUnauthorized();
    },
  );

  final authService = AuthService(apiClient, storage);
  final promoService = PromoService(apiClient);
  final productService = ProductService(apiClient);
  final orderService = OrderService(apiClient);
  final notificationService = NotificationService(apiClient);
  final bookingService = BookingService(apiClient);

  authProvider = AuthProvider(authService, tokenStore);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => CartProvider(storage, promoService)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productService),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(productService, promoService)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(bookingService),
        ),
        ChangeNotifierProvider(
          create: (_) => BikeProvider(storage)..load(),
        ),
        Provider.value(value: orderService),
        Provider.value(value: notificationService),
      ],
      child: const RiderCraftApp(),
    ),
  );
}

class RiderCraftApp extends StatelessWidget {
  const RiderCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
