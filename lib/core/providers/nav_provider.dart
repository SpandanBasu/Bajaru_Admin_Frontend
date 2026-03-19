import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index for drawer nav: 0=Dashboard, 1=Procurement, 2=Orders, 3=Riders, 4=Deliveries, 5=Catalog, 6=CustomerSupport
final navIndexProvider = StateProvider<int>((_) => 0);
