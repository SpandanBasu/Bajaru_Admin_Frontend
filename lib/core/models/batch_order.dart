enum OrderPackStatus { toPack, packing, ready, issues }

// ── Vegetable-view models ─────────────────────────────────────────────────────

class VegetablePacket {
  final String orderId;
  final String orderDisplayId;
  final String itemId;
  final int quantity;
  final String unitWeight;
  final bool isChecked;

  const VegetablePacket({
    required this.orderId,
    required this.orderDisplayId,
    required this.itemId,
    required this.quantity,
    required this.unitWeight,
    this.isChecked = false,
  });

  VegetablePacket copyWith({bool? isChecked}) => VegetablePacket(
        orderId: orderId,
        orderDisplayId: orderDisplayId,
        itemId: itemId,
        quantity: quantity,
        unitWeight: unitWeight,
        isChecked: isChecked ?? this.isChecked,
      );

  factory VegetablePacket.fromJson(Map<String, dynamic> json) => VegetablePacket(
        orderId: json['orderId'] as String? ?? '',
        orderDisplayId: json['orderDisplayId'] as String? ?? '',
        itemId: json['itemId'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        unitWeight: json['unitWeight'] as String? ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
      );
}

class VegetablePackGroup {
  final String productId;
  final String productName;
  final int totalUnits;
  final bool allChecked;
  final List<VegetablePacket> packets;
  final bool isExpanded;

  const VegetablePackGroup({
    required this.productId,
    required this.productName,
    required this.totalUnits,
    required this.allChecked,
    required this.packets,
    this.isExpanded = false,
  });

  int get checkedCount => packets.where((p) => p.isChecked).length;

  VegetablePackGroup copyWith({
    bool? allChecked,
    List<VegetablePacket>? packets,
    bool? isExpanded,
  }) =>
      VegetablePackGroup(
        productId: productId,
        productName: productName,
        totalUnits: totalUnits,
        allChecked: allChecked ?? this.allChecked,
        packets: packets ?? this.packets,
        isExpanded: isExpanded ?? this.isExpanded,
      );

  factory VegetablePackGroup.fromJson(Map<String, dynamic> json) {
    final rawPackets = json['packets'] as List? ?? [];
    return VegetablePackGroup(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      totalUnits: json['totalUnits'] as int? ?? 0,
      allChecked: json['allChecked'] as bool? ?? false,
      packets: rawPackets
          .cast<Map<String, dynamic>>()
          .map(VegetablePacket.fromJson)
          .toList(),
    );
  }
}

extension OrderPackStatusLabel on OrderPackStatus {
  String get label {
    switch (this) {
      case OrderPackStatus.toPack:   return 'To Pack';
      case OrderPackStatus.packing:  return 'Packing';
      case OrderPackStatus.ready:    return 'Ready';
      case OrderPackStatus.issues:   return 'Issues';
    }
  }
}

class PackItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isChecked;

  const PackItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
  });

  PackItem copyWith({bool? isChecked}) =>
      PackItem(id: id, name: name, quantity: quantity, unit: unit,
               isChecked: isChecked ?? this.isChecked);

  factory PackItem.fromJson(Map<String, dynamic> json) => PackItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unitWeight'] as String? ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
      );
}

class BatchOrder {
  final String id;
  final String displayId;    // e.g. #ORD-1042
  final OrderPackStatus status;
  final String? issueMessage;
  final String area;
  final String pincode;
  final List<PackItem> items;
  final bool isExpanded;
  final double bagCharge;

  const BatchOrder({
    required this.id,
    required this.displayId,
    required this.status,
    this.issueMessage,
    required this.area,
    required this.pincode,
    required this.items,
    this.isExpanded = false,
    this.bagCharge = 0,
  });

  int get itemCount => items.length;
  int get checkedCount => items.where((i) => i.isChecked).length;
  bool get allChecked => items.isNotEmpty && items.every((i) => i.isChecked);

  factory BatchOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return BatchOrder(
      id: json['id'] as String? ?? '',
      displayId: json['displayId'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'TO_PACK'),
      issueMessage: json['issueMessage'] as String?,
      area: json['area'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      items: rawItems.cast<Map<String, dynamic>>().map(PackItem.fromJson).toList(),
      bagCharge: (json['bagCharge'] as num?)?.toDouble() ?? 0,
    );
  }

  static OrderPackStatus _parseStatus(String s) => switch (s) {
        'PACKING' => OrderPackStatus.packing,
        'READY'   => OrderPackStatus.ready,
        'ISSUES'  => OrderPackStatus.issues,
        _         => OrderPackStatus.toPack,
      };

  BatchOrder copyWith({
    OrderPackStatus? status,
    String? issueMessage,
    bool clearIssueMessage = false,
    List<PackItem>? items,
    bool? isExpanded,
  }) {
    return BatchOrder(
      id:         id,
      displayId:  displayId,
      status:     status     ?? this.status,
      issueMessage: clearIssueMessage
          ? null
          : (issueMessage ?? this.issueMessage),
      area:       area,
      pincode:    pincode,
      items:      items      ?? this.items,
      isExpanded: isExpanded ?? this.isExpanded,
      bagCharge:  bagCharge,
    );
  }
}
