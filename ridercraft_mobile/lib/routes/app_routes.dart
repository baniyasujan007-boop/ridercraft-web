import 'package:flutter/material.dart';

import '../models/booking_draft.dart';
import '../models/product.dart';
import '../models/service_package.dart';
import '../models/service_request.dart';
import '../models/order.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/orders/order_screens.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/bikes/my_bikes_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/bookings/booking_review_screen.dart';
import '../screens/bookings/booking_success_screen.dart';
import '../screens/bookings/service_booking_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'route_names.dart';

/// Named-route table for the app.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      RouteNames.splash => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      ),
      RouteNames.login => MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: settings,
      ),
      RouteNames.register => MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
        settings: settings,
      ),
      RouteNames.forgotPassword => MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
        settings: settings,
      ),
      RouteNames.main => MaterialPageRoute(
        builder: (_) => const MainScaffold(),
        settings: settings,
      ),
      RouteNames.notifications => MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
        settings: settings,
      ),
      RouteNames.myBikes => MaterialPageRoute(
        builder: (_) => const MyBikesScreen(),
        settings: settings,
      ),
      RouteNames.productDetail => MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(product: settings.arguments as Product),
        settings: settings,
      ),
      RouteNames.serviceBooking => MaterialPageRoute(
        builder: (_) =>
            ServiceBookingScreen(package: settings.arguments as ServicePackage),
        settings: settings,
      ),
      RouteNames.bookingReview => MaterialPageRoute(
        builder: (_) =>
            BookingReviewScreen(draft: settings.arguments as BookingDraft),
        settings: settings,
      ),
      RouteNames.bookingSuccess => MaterialPageRoute(
        builder: (_) =>
            BookingSuccessScreen(booking: settings.arguments as ServiceRequest),
        settings: settings,
      ),
      RouteNames.bookingDetail => MaterialPageRoute(
        builder: (_) =>
            BookingDetailScreen(booking: settings.arguments as ServiceRequest),
        settings: settings,
      ),
      RouteNames.cart => MaterialPageRoute(
        builder: (_) => const CartScreen(),
        settings: settings,
      ),
      RouteNames.checkout => MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
        settings: settings,
      ),
      RouteNames.orderSuccess => MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(order: settings.arguments as Order),
        settings: settings,
      ),
      RouteNames.orders => MaterialPageRoute(
        builder: (_) => const OrdersScreen(),
        settings: settings,
      ),
      RouteNames.orderDetail => MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: settings.arguments as Order),
        settings: settings,
      ),
      _ => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      ),
    };
  }
}
