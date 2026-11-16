import '../../core/utils/json.dart';

/// Deal or cancellation. Values are shown exactly as returned.
class Deal {
  const Deal({
    required this.id,
    required this.propertyId,
    required this.outcome,
    this.type,
    this.price,
    this.buyerName,
    this.dealDate,
    this.notes,
    this.propertyName,
    this.propertyCode,
    this.salesName,
    this.createdAt,
  });

  final String id;
  final String propertyId;

  /// `deal` or `cancelled`.
  final String outcome;
  final String? type;
  final double? price;
  final String? buyerName;
  final DateTime? dealDate;
  final String? notes;
  final String? propertyName;
  final String? propertyCode;
  final String? salesName;
  final DateTime? createdAt;

  bool get isCancelled => outcome == 'cancelled';

  /// Reads only non-sensitive identifiers from the embedded property.
  factory Deal.fromJson(Map<String, dynamic> j) {
    final p = obj(j['property']);
    return Deal(
      id: strOr(j['id']),
      propertyId: strOr(j['property_id']),
      outcome: strOr(j['outcome']),
      type: str(j['type']),
      price: dblN(j['price']),
      buyerName: str(j['buyer_name']),
      dealDate: date(j['deal_date']),
      notes: str(j['notes']),
      propertyName: str(p['name']),
      propertyCode: str(p['code']),
      salesName: str(obj(j['sales'])['name']),
      createdAt: date(j['created_at']),
    );
  }
}

/// Commission. The app never calculates or edits amounts locally.
class Commission {
  const Commission({
    required this.id,
    required this.dealId,
    required this.percentage,
    required this.amount,
    required this.status,
    this.salesId,
    this.salesName,
    this.deal,
    this.createdAt,
  });

  final String id;
  final String dealId;
  final double percentage;
  final double amount;

  /// `pending`, `paid` or `cancelled`.
  final String status;
  final String? salesId;
  final String? salesName;
  final Deal? deal;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  factory Commission.fromJson(Map<String, dynamic> j) => Commission(
    id: strOr(j['id']),
    dealId: strOr(j['deal_id']),
    percentage: dblN(j['percentage']) ?? 0,
    amount: dblN(j['amount']) ?? 0,
    status: strOr(j['status']),
    salesId: str(j['sales_id']),
    salesName: str(obj(j['sales'])['name']),
    deal: obj(j['deal']).isEmpty ? null : Deal.fromJson(obj(j['deal'])),
    createdAt: date(j['created_at']),
  );

  static String statusLabel(String s) => switch (s) {
    'pending' => 'Menunggu',
    'paid' => 'Dibayar',
    'cancelled' => 'Dibatalkan',
    _ => s,
  };
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.module,
    this.entityId,
    this.userName,
    this.ipAddress,
    this.createdAt,
  });

  final String id;
  final String action;
  final String module;
  final String? entityId;
  final String? userName;
  final String? ipAddress;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
    id: strOr(j['id']),
    action: strOr(j['action']),
    module: strOr(j['module']),
    entityId: str(j['entity_id']),
    userName: str(obj(j['user'])['name']),
    ipAddress: str(j['ip_address']),
    createdAt: date(j['created_at']),
  );
}
