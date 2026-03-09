import 'package:intl/intl.dart';

enum DeliveryStatus { pending, outForDelivery, delivered, rejected }

extension DeliveryStatusExt on DeliveryStatus {
  String get label => switch (this) {
        DeliveryStatus.pending        => 'Pending',
        DeliveryStatus.outForDelivery => 'Out for Delivery',
        DeliveryStatus.delivered      => 'Delivered',
        DeliveryStatus.rejected       => 'Rejected',
      };
}

class DeliveryOrderItem {
  final String name;
  final String unitWeight; // e.g. "1 kg", "500g" — weight per packet/unit
  final int quantity;     // number of units/packets
  final int price;

  const DeliveryOrderItem({
    required this.name,
    this.unitWeight = '',
    required this.quantity,
    required this.price,
  });

  /// Display format: "Unit weight × quantity" e.g. "1 kg × 2"
  String get displayQuantity {
    if (unitWeight.isNotEmpty && quantity > 0) {
      return '$unitWeight × $quantity';
    }
    if (quantity > 0) return '× $quantity';
    return unitWeight.isNotEmpty ? unitWeight : '';
  }

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    final unit = (json['unitWeight'] as String?)?.trim() ?? '';
    return DeliveryOrderItem(
      name: json['name'] as String? ?? '',
      unitWeight: unit,
      quantity: qty,
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String customerName;
  final String phone;
  final String area;
  final String fullAddress;
  final String pincodeCode;
  final double? addressLatitude;
  final double? addressLongitude;
  final int itemCount;
  final int amount;      // subtotal
  final int deliveryFee;
  final bool isCOD;
  final DeliveryStatus status;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String time;             // "10:30 AM" — order placed / delivery time
  final String date;             // "March 8, 2026"
  final List<DeliveryOrderItem> items;
  // Delivery stats (filled once dispatched/delivered)
  final String? departedTime;    // "9:15 AM" — when rider departed
  final String? deliveredTime;   // "9:15 AM" — when order was delivered
  final int? deliveryMinutes;    // wait time: reached → completed (minutes)
  final double? distanceKm;      // 2.4
  final String? proofImageUrl;   // signed Supabase URL for proof photo
  final double? customerRating;  // 4.0
  final DateTime? placedAt;

  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.area,
    required this.fullAddress,
    required this.pincodeCode,
    this.addressLatitude,
    this.addressLongitude,
    required this.itemCount,
    required this.amount,
    required this.deliveryFee,
    required this.isCOD,
    required this.status,
    this.riderId,
    required this.time,
    required this.date,
    required this.items,
    this.riderName,
    this.riderPhone,
    this.departedTime,
    this.deliveredTime,
    this.deliveryMinutes,
    this.distanceKm,
    this.proofImageUrl,
    this.customerRating,
    this.placedAt,
  });

  int get total => amount + deliveryFee;

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'CONFIRMED';
    final status = switch (statusStr) {
      'OUT_FOR_DELIVERY' => DeliveryStatus.outForDelivery,
      'DELIVERED'        => DeliveryStatus.delivered,
      'REJECTED'         => DeliveryStatus.rejected,
      _                  => DeliveryStatus.pending,
    };

    final placedAt = json['placedAt'] != null
        ? DateTime.parse(json['placedAt'] as String).toLocal()
        : DateTime.now();
    final departedAt = json['departedAt'] != null
        ? DateTime.parse(json['departedAt'] as String).toLocal()
        : null;
    final deliveredAt = json['deliveredAt'] != null
        ? DateTime.parse(json['deliveredAt'] as String).toLocal()
        : null;

    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .cast<Map<String, dynamic>>()
        .map(DeliveryOrderItem.fromJson)
        .toList();

    return DeliveryOrder(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      area: json['area'] as String? ?? '',
      fullAddress: json['fullAddress'] as String? ?? '',
      pincodeCode: json['pincode'] as String? ?? '',
      addressLatitude: (json['addressLatitude'] as num?)?.toDouble(),
      addressLongitude: (json['addressLongitude'] as num?)?.toDouble(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? items.length,
      amount: (json['amount'] as num?)?.toInt() ??
              (json['subTotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      isCOD: json['isCOD'] as bool? ?? false,
      status: status,
      riderId: json['riderId'] as String?,
      time: DateFormat('h:mm a').format(placedAt),
      date: DateFormat('MMMM d, yyyy').format(placedAt),
      items: items,
      riderName: json['riderName'] as String?,
      riderPhone: json['riderPhone'] as String?,
      departedTime: departedAt != null
          ? DateFormat('h:mm a').format(departedAt)
          : null,
      deliveredTime: deliveredAt != null
          ? DateFormat('h:mm a').format(deliveredAt)
          : null,
      deliveryMinutes: json['deliveryMinutes'] as int?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      proofImageUrl: json['proofImageUrl'] as String? ??
          json['proof_image_url'] as String?,
      customerRating: null, // not stored in backend yet
      placedAt: placedAt,
    );
  }
}
