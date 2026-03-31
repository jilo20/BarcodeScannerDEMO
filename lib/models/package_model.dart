
class Package {
  final int id;
  final String trackingNumber;
  final String referenceCode;
  final String senderName;
  final String recipientName;
  final String recipientAddress;
  final String recipientPhone;
  final String description;
  final String currentStatus;
  final String? barcodeSvg;
  final String? qrcodeSvg;

  Package({
    required this.id,
    required this.trackingNumber,
    required this.referenceCode,
    required this.senderName,
    required this.recipientName,
    required this.recipientAddress,
    required this.recipientPhone,
    required this.description,
    required this.currentStatus,
    this.createdAt,
    this.updatedAt,
    this.barcodeSvg,
    this.qrcodeSvg,
  });

  final String? createdAt;
  final String? updatedAt;

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] ?? 0,
      trackingNumber: json['tracking_number'] ?? '',
      referenceCode: json['reference_code'] ?? '',
      senderName: json['sender_name'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      recipientAddress: json['recipient_address'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      description: json['description'] ?? '',
      currentStatus: json['current_status'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      barcodeSvg: json['barcode_svg'],
      qrcodeSvg: json['qrcode_svg'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'reference_code': referenceCode,
      'sender_name': senderName,
      'recipient_name': recipientName,
      'recipient_address': recipientAddress,
      'recipient_phone': recipientPhone,
      'description': description,
      'current_status': currentStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'barcode_svg': barcodeSvg,
      'qrcode_svg': qrcodeSvg,
    };
  }
}

class PackageEvent {
  final int id;
  final int packageId;
  final String eventStatus;
  final String location;
  final String notes;

  PackageEvent({
    required this.id,
    required this.packageId,
    required this.eventStatus,
    required this.location,
    required this.notes,
    this.createdAt,
  });

  final String? createdAt;

  factory PackageEvent.fromJson(Map<String, dynamic> json) {
    return PackageEvent(
      id: json['id'] ?? 0,
      packageId: json['package_id'] ?? 0,
      eventStatus: json['event_status'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_id': packageId,
      'event_status': eventStatus,
      'location': location,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
