enum AppRole { customer, companion }

extension AppRoleApi on AppRole {
  String get api => this == AppRole.customer ? 'CUSTOMER' : 'COMPANION';
  static AppRole from(String v) => v == 'COMPANION' ? AppRole.companion : AppRole.customer;
}

class AppUser {
  final String id;
  final AppRole role;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? city;
  final String? photoUrl;
  final String? verificationStatus; // companion only

  const AppUser({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.city,
    this.photoUrl,
    this.verificationStatus,
  });

  AppUser copyWith({
    String? id,
    AppRole? role,
    String? fullName,
    String? phone,
    String? email,
    String? city,
    String? photoUrl,
    String? verificationStatus,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        role: AppRoleApi.from(j['role'] as String),
        fullName: j['fullName'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        city: j['city'] as String?,
        photoUrl: j['photoUrl'] as String?,
        verificationStatus: (j['companion'] as Map<String, dynamic>?)?['verificationStatus'] as String?,
      );
}

/// Result of GET /auth/me.
class Session {
  final bool registered;
  final AppUser? user;
  const Session({required this.registered, this.user});

  Session copyWith({
    bool? registered,
    AppUser? user,
  }) {
    return Session(
      registered: registered ?? this.registered,
      user: user ?? this.user,
    );
  }
}
