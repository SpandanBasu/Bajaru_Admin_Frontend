enum OrderPackStatus { toPack, packing, ready, issues }

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

  const BatchOrder({
    required this.id,
    required this.displayId,
    required this.status,
    this.issueMessage,
    required this.area,
    required this.pincode,
    required this.items,
    this.isExpanded = false,
  });

  int get itemCount => items.length;
  int get checkedCount => items.where((i) => i.isChecked).length;
  bool get allChecked => items.isNotEmpty && checkedCount == itemCount;

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
    );
  }
}
