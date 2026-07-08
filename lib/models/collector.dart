class Collector {
  const Collector({
    required this.id,
    required this.fullName,
    required this.qrCode,
    required this.isActive,
    this.phone,
    this.quartierId,
  });

  final String id;
  final String fullName;
  final String qrCode;
  final bool isActive;
  final String? phone;
  final String? quartierId;

  factory Collector.fromFirestore(String id, Map<String, dynamic> data) {
    return Collector(
      id: id,
      fullName: (data['fullName'] ?? data['nom'] ?? '').toString(),
      qrCode: (data['qrCode'] ?? '').toString(),
      isActive: data['isActive'] == true || data['active'] == true,
      phone: data['phone']?.toString(),
      quartierId: data['quartierId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'qrCode': qrCode,
      'isActive': isActive,
      'phone': phone,
      'quartierId': quartierId,
    };
  }
}
