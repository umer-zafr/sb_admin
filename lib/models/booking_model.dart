class ConsultancyBookingItem {
  const ConsultancyBookingItem({
    required this.id,
    required this.userId,
    this.applicationId,
    required this.bookingReference,
    required this.serviceTitle,
    this.consultantId,
    this.consultantName = 'Senior Visa Officer',
    required this.bookingDate,
    required this.bookingTimeSlot,
    required this.status, // 'pending', 'confirmed', 'completed', 'cancelled'
    this.meetingLink,
    this.clientNotes,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String userId;
  final String? applicationId;
  final String bookingReference;
  final String serviceTitle;
  final String? consultantId;
  final String? consultantName;
  final String bookingDate;
  final String bookingTimeSlot;
  final String status;
  final String? meetingLink;
  final String? clientNotes;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userEmail;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory ConsultancyBookingItem.fromMap(
    Map<String, dynamic> map, {
    String? userName,
    String? userEmail,
  }) {
    return ConsultancyBookingItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      applicationId: map['application_id']?.toString(),
      bookingReference: map['booking_reference']?.toString() ?? '',
      serviceTitle: map['service_title']?.toString() ?? 'Visa Consultation',
      consultantId: map['consultant_id']?.toString(),
      consultantName:
          map['consultant_name']?.toString() ?? 'Senior Visa Officer',
      bookingDate: map['booking_date']?.toString() ?? '',
      bookingTimeSlot: map['booking_time_slot']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      meetingLink: map['meeting_link']?.toString(),
      clientNotes: map['client_notes']?.toString(),
      adminNotes: map['admin_notes']?.toString(),
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
      userName: userName,
      userEmail: userEmail,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'application_id': applicationId,
        'booking_reference': bookingReference,
        'service_title': serviceTitle,
        'consultant_id': consultantId,
        'consultant_name': consultantName,
        'booking_date': bookingDate,
        'booking_time_slot': bookingTimeSlot,
        'status': status,
        'meeting_link': meetingLink,
        'client_notes': clientNotes,
        'admin_notes': adminNotes,
      };
}
