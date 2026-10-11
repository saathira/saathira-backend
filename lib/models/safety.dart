class BlockedUser {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? city;

  const BlockedUser({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.city,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final blocked = json['blocked'] as Map<String, dynamic>? ?? json;
    return BlockedUser(
      id: blocked['id'] as String? ?? '',
      fullName: blocked['fullName'] as String? ?? 'User',
      photoUrl: blocked['photoUrl'] as String?,
      city: blocked['city'] as String?,
    );
  }
}

class ComplaintRecord {
  final String id;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  const ComplaintRecord({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintRecord.fromJson(Map<String, dynamic> json) {
    return ComplaintRecord(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class DisputeRecord {
  final String id;
  final String bookingId;
  final String reason;
  final String? resolution;
  final String status;
  final DateTime createdAt;

  const DisputeRecord({
    required this.id,
    required this.bookingId,
    required this.reason,
    this.resolution,
    required this.status,
    required this.createdAt,
  });

  factory DisputeRecord.fromJson(Map<String, dynamic> json) {
    return DisputeRecord(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      resolution: json['resolution'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
