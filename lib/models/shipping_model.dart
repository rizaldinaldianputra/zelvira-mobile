class ShippingCourierResponse {
  final String code;
  final String name;
  final String service;
  final String description;
  final double cost;
  final String etd;

  ShippingCourierResponse({
    required this.code,
    required this.name,
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
  });

  factory ShippingCourierResponse.fromJson(Map<String, dynamic> json) {
    return ShippingCourierResponse(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      etd: json['etd'] ?? '',
    );
  }
}

class Province {
  final String provinceId;
  final String province;

  Province({required this.provinceId, required this.province});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      provinceId: (json['province_id'] ?? json['id'] ?? '').toString(),
      province: json['province'] ?? json['name'] ?? '',
    );
  }
}

class City {
  final String cityId;
  final String provinceId;
  final String cityName;
  final String type;
  final String postalCode;

  City({
    required this.cityId,
    required this.provinceId,
    required this.cityName,
    required this.type,
    required this.postalCode,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: (json['city_id'] ?? json['id'] ?? '').toString(),
      provinceId: (json['province_id'] ?? '').toString(),
      cityName: json['city_name'] ?? json['name'] ?? '',
      type: json['type'] ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
    );
  }
}

class District {
  final String districtId;
  final String cityId;
  final String districtName;

  District({
    required this.districtId,
    required this.cityId,
    required this.districtName,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtId: (json['subdistrict_id'] ?? json['district_id'] ?? json['id'] ?? '').toString(),
      cityId: (json['city_id'] ?? '').toString(),
      districtName: json['subdistrict_name'] ?? json['district_name'] ?? json['name'] ?? '',
    );
  }
}

class Subdistrict {
  final String subdistrictId;
  final String districtId;
  final String subdistrictName;

  Subdistrict({
    required this.subdistrictId,
    required this.districtId,
    required this.subdistrictName,
  });

  factory Subdistrict.fromJson(Map<String, dynamic> json) {
    return Subdistrict(
      subdistrictId: (json['subdistrict_id'] ?? json['id'] ?? '').toString(),
      districtId: (json['district_id'] ?? '').toString(),
      subdistrictName: json['subdistrict_name'] ?? json['name'] ?? '',
    );
  }
}
