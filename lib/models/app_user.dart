enum AppUserType { admin, collecteur, habitant }

extension AppUserTypeValue on AppUserType {
  String get value {
    switch (this) {
      case AppUserType.admin:
        return 'admin';
      case AppUserType.collecteur:
        return 'collecteur';
      case AppUserType.habitant:
        return 'habitant';
    }
  }

  static AppUserType fromValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'admin':
      case 'administrateur':
        return AppUserType.admin;
      case 'habitant':
        return AppUserType.habitant;
      case 'collecteur':
      default:
        return AppUserType.collecteur;
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.type,
    required this.isActive,
    this.pin,
    this.qrCode,
    this.phone,
    this.address,
    this.quartierId,
    this.quartierName,
  });

  final String id;
  final String fullName;
  final String email;
  final AppUserType type;
  final bool isActive;
  final String? pin;
  final String? qrCode;
  final String? phone;
  final String? address;
  final String? quartierId;
  final String? quartierName;

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      fullName: (data['fullName'] ?? data['nom'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      type: AppUserTypeValue.fromValue((data['type'] ?? '').toString()),
      isActive: data['isActive'] == true || data['active'] == true,
      pin: data['pin']?.toString(),
      qrCode: data['qrCode']?.toString(),
      phone: data['phone']?.toString(),
      address: data['address']?.toString(),
      quartierId: data['quartierId']?.toString(),
      quartierName: data['quartierName']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'type': type.value,
      'isActive': isActive,
      'pin': pin,
      'qrCode': qrCode,
      'phone': phone,
      'address': address,
      'quartierId': quartierId,
      'quartierName': quartierName,
    };
  }
}
