import '../models/user.dart';
import 'route_names.dart';

/// Single place that decides the landing shell after a successful session:
/// garage-role accounts go to [RouteNames.garageMain], everyone else
/// (customer + admin) keeps the existing [RouteNames.main].
///
/// Used by both the post-login navigation and the splash session restore so
/// the two flows can never disagree.
String homeRouteFor(User user) {
  return user.isGarage ? RouteNames.garageMain : RouteNames.main;
}