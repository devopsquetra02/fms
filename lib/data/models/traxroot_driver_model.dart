/// Model representing a driver from Traxroot.
class TraxrootDriverModel {
  final int? id;
  final String? name;
  final String? phone;
  final String? category;
  final String? rank;
  final String? license;
  final int? licenseValidTill;
  final String? internalId;
  final String? insuranceId;
  final int? insuranceValidTill;

  const TraxrootDriverModel({
    this.id,
    this.name,
    this.phone,
    this.category,
    this.rank,
    this.license,
    this.licenseValidTill,
    this.internalId,
    this.insuranceId,
    this.insuranceValidTill,
  });

  factory TraxrootDriverModel.fromMap(Map<String, dynamic> map) {
    return TraxrootDriverModel(
      id: map['id'] as int?,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      category: map['category'] as String?,
      rank: map['rank'] as String?,
      license: map['license'] as String?,
      licenseValidTill: map['licenseValidTill'] as int?,
      internalId: map['internalId'] as String?,
      insuranceId: map['insuranceId'] as String?,
      insuranceValidTill: map['insuranceValidTill'] as int?,
    );
  }
}
