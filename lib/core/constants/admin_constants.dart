class AdminConstants {
  AdminConstants._();

  static const String appName = 'SB Consultants';
  static const String appTagline = 'Enterprise Admin Portal';
  static const String version = '1.0.0';

  // 5 Application Stepper Procedure Steps
  static const List<Map<String, dynamic>> procedureSteps = [
    {
      'step_number': 1,
      'title': 'Profile Review',
      'duration': '1-2 Days',
      'description': 'Initial document check and eligibility screening',
    },
    {
      'step_number': 2,
      'title': 'Consultant Call',
      'duration': 'Scheduled',
      'description': 'One-on-one session with assigned immigration officer',
    },
    {
      'step_number': 3,
      'title': 'Ready Case',
      'duration': '3-5 Days',
      'description': 'Complete application dossier and SOP preparation',
    },
    {
      'step_number': 4,
      'title': 'Embassy Submission',
      'duration': '2-3 Weeks',
      'description': 'Lodgment with target government/consulate',
    },
    {
      'step_number': 5,
      'title': 'Feedback & Rating',
      'duration': 'Post-Decision',
      'description': 'Visa outcome verification and client review',
    },
  ];

  static const List<String> applicationStatuses = [
    'submitted',
    'under_review',
    'in_review',
    'action_needed',
    'approved',
    'rejected',
    'completed',
    'cancelled',
    'withdrawn',
  ];

  static const List<String> bookingStatuses = [
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  static const List<String> paymentStatuses = [
    'pending',
    'success',
    'completed',
    'failed',
    'refunded',
  ];
}
