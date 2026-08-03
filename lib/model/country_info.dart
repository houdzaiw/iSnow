class CountryInfo {
  const CountryInfo({
    required this.name,
    required this.arName,
    required this.isoCode,
    required this.dialCode,
  });

  final String name;
  final String arName;
  final String isoCode;
  final String dialCode;

  String get areaCode => dialCode.replaceFirst('+', '');

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    final dialCode = json['dialCode']?.toString() ?? '';
    return CountryInfo(
      name: json['name']?.toString() ?? '',
      arName: json['arName']?.toString() ?? '',
      isoCode: json['isoCode']?.toString() ?? '',
      dialCode: dialCode.startsWith('+') ? dialCode : '+$dialCode',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'arName': arName,
      'isoCode': isoCode,
      'dialCode': dialCode,
    };
  }

  static const CountryInfo kyrgyzstan = CountryInfo(
    name: 'Kyrgyzstan',
    arName: 'قيرغيزستان',
    isoCode: 'KG',
    dialCode: '+996',
  );

  static const CountryInfo saudiArabia = CountryInfo(
    name: 'Saudi Arabia',
    arName: 'السعودية',
    isoCode: 'SA',
    dialCode: '+966',
  );

  static const List<CountryInfo> fallbackList = [
    saudiArabia,
    kyrgyzstan,
    CountryInfo(
      name: 'United States',
      arName: 'الولايات المتحدة',
      isoCode: 'US',
      dialCode: '+1',
    ),
    CountryInfo(name: 'China', arName: 'الصين', isoCode: 'CN', dialCode: '+86'),
    CountryInfo(name: 'India', arName: 'الهند', isoCode: 'IN', dialCode: '+91'),
  ];
}
