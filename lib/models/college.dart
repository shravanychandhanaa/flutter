class College {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? phone;
  final String? email;
  final String? website;
  final String? status;

  College({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.phone,
    this.email,
    this.website,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'website': website,
      'status': status,
    };
  }

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id']?.toString() ?? json['college_id']?.toString() ?? '',
      name: json['college_name'] ?? json['name'] ?? json['collegeName'] ?? '',
      address: json['address'] ?? json['college_address'],
      city: json['city'] ?? json['college_city'],
      state: json['state'] ?? json['college_state'],
      pincode: json['pincode'] ?? json['college_pincode'],
      phone: json['phone'] ?? json['college_phone'],
      email: json['email'] ?? json['college_email'],
      website: json['website'] ?? json['college_website'],
      status: json['status'] ?? json['college_status'],
    );
  }

  @override
  String toString() {
    return name;
  }
} 