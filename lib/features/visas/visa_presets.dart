class VisaCategoryPreset {
  const VisaCategoryPreset({
    required this.validity,
    required this.successRate,
    required this.applicantsCount,
    required this.processingTime,
    required this.fee,
    required this.serviceFeeLabel,
    required this.totalPayable,
    required this.aboutTitle,
    required this.aboutDescription,
    required this.eligibilityCriteria,
    required this.mandatoryDocuments,
    required this.timelineSteps,
    required this.feeBreakdown,
    this.statusBadge = 'Available',
    this.applicationRequirements = const {},
  });

  final String validity;
  final String successRate;
  final String applicantsCount;
  final String processingTime;
  final String fee;
  final String serviceFeeLabel;
  final String totalPayable;
  final String aboutTitle;
  final String aboutDescription;
  final List<String> eligibilityCriteria;
  final List<Map<String, String>> mandatoryDocuments;
  final List<Map<String, String>> timelineSteps;
  final List<Map<String, String>> feeBreakdown;
  final String statusBadge;
  final Map<String, dynamic> applicationRequirements;

  static VisaCategoryPreset getPresetForCategory(String categoryIdOrName) {
    final cat = categoryIdOrName.toLowerCase();

    if (cat.contains('job') || cat.contains('sponsor')) {
      return jobPreset;
    } else if (cat.contains('scholarship')) {
      return scholarshipPreset;
    } else if (cat.contains('study') || cat.contains('student') || cat.contains('tier 4')) {
      return studyPreset;
    } else if (cat.contains('golden') || cat.contains('invest')) {
      return goldenPreset;
    } else if (cat.contains('business') || cat.contains('commercial')) {
      return businessPreset;
    } else if (cat.contains('visit') || cat.contains('tourist') || cat.contains('holiday') || cat.contains('family')) {
      return visitPreset;
    }

    return workPreset;
  }

  // --------------------------------------------------------------------------
  // 0. SPONSORED JOB PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset jobPreset = VisaCategoryPreset(
    validity: '3-5 Years (Full Work Visa + PR Route)',
    successRate: '98%',
    applicantsCount: '4,200+ Placed',
    processingTime: '3-5 Weeks',
    fee: 'Free (Visa Sponsored)',
    serviceFeeLabel: 'PROCESSING CHARGES',
    totalPayable: 'Free',
    statusBadge: 'Visa Sponsored',
    aboutTitle: 'Verified Sponsored Jobs & Employment Route',
    aboutDescription:
        'Official sponsorship job opportunities with licensed employers (Certificate of Sponsorship / LMIA provided). Positions feature verified annual salary packages, structured career progression, and a direct pathway to permanent settlement.',
    eligibilityCriteria: [
      'Relevant academic diploma, bachelor degree, or verifiable trade experience in the domain.',
      'Basic to intermediate English proficiency (IELTS 4.5 - 5.5 or equivalent where required).',
      'Valid passport with at least 1 year validity before departure.',
      'Clear police character certificate and approved medical examination.',
      'Commitment to relocate and complete the employer employment contract tenure.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Valid Passport',
        'note': 'Minimum 12 months validity with blank pages',
        'icon': 'badge',
      },
      {
        'title': 'Updated Curriculum Vitae (CV / Resume)',
        'note': 'International standard format with verifiable employment timeline',
        'icon': 'description',
      },
      {
        'title': 'Academic Credentials & Transcripts',
        'note': 'Attested copies of degree, diploma, or vocational certificates',
        'icon': 'school',
      },
      {
        'title': 'Work Experience / Reference Letters',
        'note': 'Proof of past relevant employment on company letterheads',
        'icon': 'work',
      },
      {
        'title': 'Police Character Clearance Certificate',
        'note': 'Recent clean background clearance from local police',
        'icon': 'verified',
      },
    ],
    timelineSteps: [
      {
        'title': 'Profile Assessment & CV Optimization',
        'duration': 'Days 1 - 3',
        'description': 'Align candidate background with licensed sponsor compliance guidelines.',
        'icon': 'fact_check',
      },
      {
        'title': 'Direct Employer Application & Shortlisting',
        'duration': 'Weeks 1 - 2',
        'description': 'Direct submission via employer career link, interview screening, and verification.',
        'icon': 'work',
      },
      {
        'title': 'Certificate of Sponsorship (CoS / LMIA) Issuance',
        'duration': 'Weeks 2 - 3',
        'description': 'Licensed sponsor issues official government sponsorship reference.',
        'icon': 'card_membership',
      },
      {
        'title': 'Visa Application & Biometrics',
        'duration': 'Weeks 3 - 4',
        'description': 'Biometric enrollment at visa application center and documentation submission.',
        'icon': 'fingerprint',
      },
      {
        'title': 'Passport Collection & Flight Briefing',
        'duration': 'Week 5',
        'description': 'Visa stamped in passport and pre-departure relocation orientation.',
        'icon': 'flight_takeoff',
      },
    ],
    feeBreakdown: [],
    applicationRequirements: {
      'experience_requirement': {
        'enabled': true,
        'min_years': '1-2 Years',
        'role_level': 'Entry to Mid-Level Skilled',
      },
    },
  );

  // --------------------------------------------------------------------------
  // 1. WORK VISA PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset workPreset = VisaCategoryPreset(
    validity: '2-3 Years (Renewable with PR pathway)',
    successRate: '95%',
    applicantsCount: '3,850+ Applicants',
    processingTime: '3-4 Weeks',
    fee: 'PKR 35,000',
    serviceFeeLabel: 'CONSULTANCY CHARGES',
    totalPayable: 'PKR 35,000',
    statusBadge: 'Actively Hiring',
    aboutTitle: 'Skilled Worker & Employment Visa',
    aboutDescription:
        'Comprehensive advisory for international skilled work routes and official work permits. SB Consultants handles job sponsorship verification, Certificate of Sponsorship (CoS) compliance, points-based qualification audits, and complete consular filing.',
    eligibilityCriteria: [
      'Valid Job Offer or Certificate of Sponsorship (CoS) from a licensed destination employer.',
      'Relevant academic degree or minimum 3+ years documented professional experience in the field.',
      'English language competency (IELTS General / UKVI min 5.5 - 6.0 or ECCTIS certified).',
      'Meets destination country minimum salary threshold (skilled worker wage requirement).',
      'Clear international police clearance certificate and approved medical fitness check.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Current Valid Passport',
        'note': 'Minimum 1 year validity with at least 2 blank pages',
        'icon': 'badge',
      },
      {
        'title': 'Job Offer / Certificate of Sponsorship (CoS)',
        'note': 'Official employment contract with salary breakdown',
        'icon': 'work',
      },
      {
        'title': 'Educational Degrees & Transcripts',
        'note': 'Attested copies and official equivalence report',
        'icon': 'school',
      },
      {
        'title': 'Work Experience Certificates',
        'note': 'Detailed reference letters from previous employers',
        'icon': 'description',
      },
      {
        'title': 'Bank Statement & Maintenance Funds',
        'note': 'Last 3-6 months continuous financial maintenance',
        'icon': 'bank',
      },
      {
        'title': 'Police Clearance Certificate',
        'note': 'Issued by local law enforcement within the last 6 months',
        'icon': 'police',
      },
      {
        'title': 'Medical & TB Fitness Certificate',
        'note': 'Conducted at an accredited embassy panel diagnostic clinic',
        'icon': 'health',
      },
    ],
    timelineSteps: [
      {
        'title': 'Document Audit & Qualification Assessment',
        'duration': '3-5 Days',
        'description':
            'Full legal review of job contract, CoS eligibility, and points calculator score.',
        'icon': 'fact_check',
      },
      {
        'title': 'Application Filing & Biometric Appointment',
        'duration': '1 Week',
        'description':
            'Official government visa portal submission and VFS center biometric booking.',
        'icon': 'calendar',
      },
      {
        'title': 'Visa Decision & Passport Stamping',
        'duration': '3-4 Weeks',
        'description':
            'Final consular adjudication and delivery of stamped entry visa vignette.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Consultants Advisory & Case Filing',
        'amount': 'PKR 35,000',
        'subNote': 'Complete documentation, case filing, and advisory',
        'tag': 'Due Now',
      },
      {
        'label': 'Official Embassy Visa Application Fee',
        'amount': 'Official Consular Rate',
        'subNote': 'Paid directly on the government immigration portal',
        'tag': 'Embassy Fee',
      },
      {
        'label': 'Immigration Health Surcharge (IHS)',
        'amount': 'Official Rate',
        'subNote': 'National health service insurance coverage for full visa tenure',
        'tag': 'Health Levy',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 21,
        'max_age': 45,
        'bracket': '21 - 45 Years (Prime Skilled Worker Age)',
      },
      'education_requirement': {
        'enabled': true,
        'min_qualification': "Bachelor's / Associate Degree",
        'min_cgpa_or_marks': 'Second Class or 2.5+ CGPA',
        'field_of_study': 'Relevant technical or professional trade',
      },
      'language_requirement': {
        'enabled': true,
        'test_type': 'IELTS General / UKVI',
        'min_score': '5.5 Overall Band',
        'is_mandatory': true,
      },
      'experience_requirement': {
        'enabled': true,
        'min_years': '2 - 3 Years',
        'role_level': 'Mid-to-Senior Skilled Role',
      },
      'financial_requirement': {
        'enabled': true,
        'min_bank_balance': 'PKR 1,500,000 / £1,270',
        'holding_period': '28 Days Holding Record',
        'proof_type': 'Personal bank statement with bank verification letter',
      },
      'travel_history_requirement': {
        'prior_travel_required': false,
        'rejection_declaration_required': true,
        'police_certificate_required': true,
        'medical_check_required': true,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'Do you hold a valid Job Offer or CoS / LMIA from an overseas employer?',
          'type': 'dropdown',
          'options': 'Yes - Approved CoS/Job Offer, In Final Interview Stage, No - Need Employer Sponsorship Assistance',
          'is_required': true,
        },
        {
          'id': 'q2',
          'question': 'Specify your primary industry trade or profession:',
          'type': 'text',
          'options': '',
          'is_required': true,
        },
      ],
    },
  );

  // --------------------------------------------------------------------------
  // 2. STUDY VISA PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset studyPreset = VisaCategoryPreset(
    validity: '1-4 Years (Duration of Academic Program)',
    successRate: '97%',
    applicantsCount: '2,600+ Students',
    processingTime: '3-4 Weeks',
    fee: 'PKR 25,000',
    serviceFeeLabel: 'STUDENT ADVISORY FEE',
    totalPayable: 'PKR 25,000',
    statusBadge: 'Admissions Open',
    aboutTitle: 'Student Route & Higher Education Visa',
    aboutDescription:
        'End-to-end guidance for university admissions and student visas. We evaluate academic credentials, assist with university CAS/COE issuance, inspect financial bank statement holding periods, craft high-impact Statements of Purpose (SOP), and organize interview prep.',
    eligibilityCriteria: [
      'Unconditional admission offer letter & valid CAS / COE from a recognized licensed university.',
      'English language proficiency certificate (IELTS Academic / PTE / TOEFL score meeting course standards).',
      'Verified proof of funds covering 1-year university tuition and living maintenance (28-day continuous holding).',
      'Compelling Statement of Purpose (SOP) demonstrating genuine academic intent and career trajectory.',
      'Approved medical fitness test and clean character background.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Current Valid Passport',
        'note': 'Minimum 6 months validity beyond intended course start',
        'icon': 'badge',
      },
      {
        'title': 'University Offer Letter / CAS Document',
        'note': 'Official confirmation of acceptance for studies',
        'icon': 'description',
      },
      {
        'title': 'Academic Degrees, Transcripts & Diplomas',
        'note': 'Verified original copies with HEC / Board attestation',
        'icon': 'school',
      },
      {
        'title': 'Bank Statement & Maintenance Holding',
        'note': '28-day holding certificate with official bank stamp',
        'icon': 'bank',
      },
      {
        'title': 'English Language Test Score (IELTS / PTE)',
        'note': 'Official test report meeting university minimum band',
        'icon': 'translate',
      },
      {
        'title': 'Statement of Purpose (SOP)',
        'note': 'Detailed essay outlining study rationale and career goals',
        'icon': 'description',
      },
      {
        'title': 'Tuberculosis (TB) / Medical Certificate',
        'note': 'Issued by an approved panel clinic',
        'icon': 'health',
      },
    ],
    timelineSteps: [
      {
        'title': 'Academic Profile Evaluation & Course Shortlisting',
        'duration': '2-3 Days',
        'description':
            'Assessment of academic transcripts, GPA, and matching with accredited partner universities.',
        'icon': 'fact_check',
      },
      {
        'title': 'University Offer & CAS/COE Issuance',
        'duration': '1-2 Weeks',
        'description':
            'Securing unconditional admission letter and official Confirmation of Acceptance for Studies.',
        'icon': 'school',
      },
      {
        'title': 'Financial Scrutiny & Embassy Filing',
        'duration': '1 Week',
        'description':
            '28-day bank balance audit, SOP polishing, visa fee payment, and biometric slot booking.',
        'icon': 'calendar',
      },
      {
        'title': 'Visa Stamping & Pre-Departure Briefing',
        'duration': '3-4 Weeks',
        'description':
            'Receipt of passport with student visa vignette and briefing on student accommodation & campus life.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Comprehensive Student Advisory',
        'amount': 'PKR 25,000',
        'subNote': 'Complete admission placement, SOP crafting, and embassy filing',
        'tag': 'Due Now',
      },
      {
        'label': 'Official UKVI / Consular Student Visa Fee',
        'amount': 'Official Rate',
        'subNote': 'Direct consular visa tariff payable on embassy portal',
        'tag': 'Embassy Fee',
      },
      {
        'label': 'International Student Health Surcharge',
        'amount': 'Official Rate',
        'subNote': 'Healthcare access for full student course duration',
        'tag': 'Health Levy',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 17,
        'max_age': 32,
        'bracket': '17 - 32 Years (Student Academic Age)',
      },
      'education_requirement': {
        'enabled': true,
        'min_qualification': 'Intermediate / Bachelor’s Degree',
        'min_cgpa_or_marks': '60% or 2.8+ CGPA',
        'field_of_study': 'Intended Major / Degree Program',
      },
      'language_requirement': {
        'enabled': true,
        'test_type': 'IELTS Academic / PTE',
        'min_score': '6.0 - 6.5 Overall (min 5.5 each)',
        'is_mandatory': true,
      },
      'experience_requirement': {
        'enabled': false,
        'min_years': 'Fresh Graduate Eligible',
        'role_level': 'Academic Track',
      },
      'financial_requirement': {
        'enabled': true,
        'min_bank_balance': 'PKR 3,500,000 / £12,000',
        'holding_period': '28 Days Continuous Holding',
        'proof_type': 'Sponsor / Personal bank certificate with maintenance statement',
      },
      'travel_history_requirement': {
        'prior_travel_required': false,
        'rejection_declaration_required': true,
        'police_certificate_required': false,
        'medical_check_required': true,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'Have you already received an admission letter or CAS / I-20?',
          'type': 'dropdown',
          'options': 'Yes - Unconditional Offer/CAS, Yes - Conditional Offer, No - Need Admission Placement',
          'is_required': true,
        },
        {
          'id': 'q2',
          'question': 'Target academic intake semester:',
          'type': 'dropdown',
          'options': 'September / Fall Intake, January / Spring Intake, May / Summer Intake',
          'is_required': true,
        },
      ],
    },
  );

  // --------------------------------------------------------------------------
  // 3. VISIT & TOURIST VISA PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset visitPreset = VisaCategoryPreset(
    validity: '30 to 90 Days (Single / Multiple Entry)',
    successRate: '98%',
    applicantsCount: '5,100+ Travelers',
    processingTime: '5-10 Days',
    fee: 'PKR 20,000',
    serviceFeeLabel: 'VISIT PROCESSING FEE',
    totalPayable: 'PKR 20,000',
    statusBadge: 'Fast Track Available',
    aboutTitle: 'Tourist, Family Visit & Leisure Travel Visa',
    aboutDescription:
        'Fast and reliable tourist and family visit visa processing. SB Consultants assists with flight itineraries, hotel vouchers, cover letter drafting, financial maintenance presentation, and appointment scheduling for maximum grant success.',
    eligibilityCriteria: [
      'Valid passport with at least 6 months validity from departure date.',
      'Active bank statement demonstrating sufficient funds for stay duration (6-month history).',
      'Proof of ties to home country (employment letter, property documents, or business registration).',
      'Confirmed return flight reservation and verified hotel accommodation bookings.',
      'Clean international immigration record with no active travel bans.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Original Passport & Copies',
        'note': 'Clean stamp pages with minimum 6 months validity',
        'icon': 'badge',
      },
      {
        'title': 'Bank Account Statement (Last 6 Months)',
        'note': 'Showing steady income deposits with bank verification letter',
        'icon': 'bank',
      },
      {
        'title': 'Employment NOC / Salary Slips / Business NTN',
        'note': 'Proof of income and strong socioeconomic ties',
        'icon': 'work',
      },
      {
        'title': 'Travel Itinerary & Hotel Reservation',
        'note': 'Confirmed hotel vouchers and flight route booking',
        'icon': 'description',
      },
      {
        'title': 'White Background Biometric Photos',
        'note': '35x45mm matte finish photos matching consular standards',
        'icon': 'photo',
      },
      {
        'title': 'CNIC / National Identity Card',
        'note': 'Clear photocopy with official English translation',
        'icon': 'badge',
      },
    ],
    timelineSteps: [
      {
        'title': 'File Preparation & Cover Letter Drafting',
        'duration': '1-2 Days',
        'description':
            'Verification of bank balance, proof of ties, travel insurance, and cover letter crafting.',
        'icon': 'fact_check',
      },
      {
        'title': 'Consular Appointment & Submission',
        'duration': '2-3 Days',
        'description':
            'Submitting online portal application or attending VFS / Gerry’s drop-box appointment.',
        'icon': 'calendar',
      },
      {
        'title': 'Visa Decision & Passport Collection',
        'duration': '5-10 Days',
        'description':
            'Issuance of official tourist e-Visa or stamped visa sticker.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Complete Visit Visa Advisory',
        'amount': 'PKR 20,000',
        'subNote': 'File compilation, cover letter, hotel booking, and appointment slot',
        'tag': 'Due Now',
      },
      {
        'label': 'Embassy Visa Processing Fee',
        'amount': 'Official Consular Fee',
        'subNote': 'Direct consular visa tariff',
        'tag': 'Embassy Fee',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 18,
        'max_age': 65,
        'bracket': '18 - 65 Years',
      },
      'education_requirement': {
        'enabled': false,
        'min_qualification': 'Not Applicable',
        'min_cgpa_or_marks': 'N/A',
        'field_of_study': 'General',
      },
      'language_requirement': {
        'enabled': false,
        'test_type': 'None Required',
        'min_score': 'N/A',
        'is_mandatory': false,
      },
      'experience_requirement': {
        'enabled': true,
        'min_years': '1+ Year Employment or Business',
        'role_level': 'Employed / Self-Employed Business Owner',
      },
      'financial_requirement': {
        'enabled': true,
        'min_bank_balance': 'PKR 2,000,000',
        'holding_period': '6 Months Verified Statement',
        'proof_type': 'Bank statement showing regular income deposits + Account maintenance letter',
      },
      'travel_history_requirement': {
        'prior_travel_required': true,
        'rejection_declaration_required': true,
        'police_certificate_required': false,
        'medical_check_required': false,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'Primary Purpose of Visit:',
          'type': 'dropdown',
          'options': 'Tourism & Sightseeing, Visiting Family/Friends, Business Meetings / Conferences, Medical Treatment',
          'is_required': true,
        },
        {
          'id': 'q2',
          'question': 'Intended Stay Duration:',
          'type': 'dropdown',
          'options': '14 Days, 30 Days (Single Entry), 60 Days (Multiple Entry), 90 Days',
          'is_required': true,
        },
      ],
    },
  );

  // --------------------------------------------------------------------------
  // 4. GOLDEN VISA PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset goldenPreset = VisaCategoryPreset(
    validity: '5 to 10 Years Long-Term Residency',
    successRate: '99%',
    applicantsCount: '850+ Investors',
    processingTime: '1-2 Weeks',
    fee: 'PKR 50,000',
    serviceFeeLabel: 'INVESTOR ADVISORY CHARGES',
    totalPayable: 'PKR 50,000',
    statusBadge: 'VIP Fast Track',
    aboutTitle: 'Long-Term Investor & Golden Residency Visa',
    aboutDescription:
        'Exclusive residency by investment and extraordinary talent route. SB Consultants coordinates high-net-worth property evaluations, public investment deposits, VIP express medical clearances, and issuance of multi-year residency cards with 100% foreign business ownership.',
    eligibilityCriteria: [
      'Qualifying real estate investment (min AED 2 Million / USD 500,000) or accredited entrepreneur status.',
      'Verified proof of liquid funds, bank capital deposits, or high-income commercial enterprises.',
      'Active tax compliance records and valid commercial license.',
      'Comprehensive international health insurance coverage.',
      'Clear security background and valid passport.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Original Passport & High-Res Color Scan',
        'note': 'Minimum 1 year validity with personal information pages',
        'icon': 'badge',
      },
      {
        'title': 'Property Title Deed / Investment Certificate',
        'note': 'Attested deed issued by relevant Land Department',
        'icon': 'description',
      },
      {
        'title': 'Bank Balance & Financial Audit (Last 6-12 Months)',
        'note': 'Comprehensive capital audit verifying liquid maintenance',
        'icon': 'bank',
      },
      {
        'title': 'Commercial Trade License / Company Memorandum',
        'note': 'Certified copies showing ownership shareholding',
        'icon': 'work',
      },
      {
        'title': 'Health Insurance Card & VIP Medical Fitness',
        'note': 'Certified medical screening results',
        'icon': 'health',
      },
    ],
    timelineSteps: [
      {
        'title': 'Investment Portfolio Audit & Eligibility Nomination',
        'duration': '2-3 Days',
        'description':
            'Verification of title deeds, valuation reports, and pre-approval nomination filing.',
        'icon': 'fact_check',
      },
      {
        'title': 'Digital Entry Permit & Registration',
        'duration': '3-5 Days',
        'description':
            'Residency file opening on national immigration platform.',
        'icon': 'calendar',
      },
      {
        'title': 'VIP Medical & 10-Year Golden Visa Stamping',
        'duration': '2-3 Days',
        'description':
            'Express medical testing, biometric card issuance, and 10-year visa grant.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Executive Golden Visa Advisory',
        'amount': 'PKR 50,000',
        'subNote': 'End-to-end VIP concierge, nomination, and legal filing',
        'tag': 'Due Now',
      },
      {
        'label': 'Government Golden Residency Fee',
        'amount': 'Official Government Tariff',
        'subNote': 'Direct government immigration tariff',
        'tag': 'Government Fee',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 25,
        'max_age': 70,
        'bracket': '25+ Years (Investor / Entrepreneur)',
      },
      'education_requirement': {
        'enabled': false,
        'min_qualification': 'Degree or Accredited Executive Background',
        'min_cgpa_or_marks': 'N/A',
        'field_of_study': 'Business / Real Estate / Tech',
      },
      'language_requirement': {
        'enabled': false,
        'test_type': 'Exempt / Basic Communication',
        'min_score': 'N/A',
        'is_mandatory': false,
      },
      'experience_requirement': {
        'enabled': true,
        'min_years': '5+ Years Executive / Ownership Experience',
        'role_level': 'Majority Shareholder / Director / High Net Worth',
      },
      'financial_requirement': {
        'enabled': true,
        'min_bank_balance': 'AED 2,000,000 / USD 500,000',
        'holding_period': 'Audited Financial Statements (Last 2 Years)',
        'proof_type': 'Property title deed or bank liquid asset deposit certificate',
      },
      'travel_history_requirement': {
        'prior_travel_required': false,
        'rejection_declaration_required': true,
        'police_certificate_required': true,
        'medical_check_required': true,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'Golden Visa Qualifying Route:',
          'type': 'dropdown',
          'options': 'Real Estate Investment (AED 2M+), Public Investment / Deposit, Entrepreneur / Startup Founder, Exceptional Specialized Talent',
          'is_required': true,
        },
      ],
    },
  );

  // --------------------------------------------------------------------------
  // 5. BUSINESS VISA PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset businessPreset = VisaCategoryPreset(
    validity: '1-5 Years Multiple Entry Commercial Visa',
    successRate: '96%',
    applicantsCount: '1,750+ Businessmen',
    processingTime: '2-3 Weeks',
    fee: 'PKR 30,000',
    serviceFeeLabel: 'COMMERCIAL CONSULTING FEE',
    totalPayable: 'PKR 30,000',
    statusBadge: 'Fast Track Available',
    aboutTitle: 'Commercial & Business Traveler Visa',
    aboutDescription:
        'Professional visa filing for business executives, delegates, trade fair participants, and commercial entrepreneurs. Includes Chamber of Commerce documentation, trade invitation letter verification, FBR tax compliance audit, and fast-track submission.',
    eligibilityCriteria: [
      'Official business invitation letter from the destination host company or conference organizer.',
      'Active commercial enterprise ownership or executive employment with company dispatch letter.',
      'Active NTN number and recent 2-3 years FBR income tax returns.',
      'Verified corporate bank statement demonstrating healthy trade turnover.',
      'Valid Chamber of Commerce membership certificate.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Original Passport & Old Passports',
        'note': 'Minimum 6 months validity with previous travel records',
        'icon': 'badge',
      },
      {
        'title': 'Host Company Business Invitation Letter',
        'note': 'Signed invitation outlining purpose of business meetings',
        'icon': 'description',
      },
      {
        'title': 'Company NTN & Last 2 Years Tax Returns',
        'note': 'FBR certified active taxpayer documentation',
        'icon': 'work',
      },
      {
        'title': 'Company & Personal Bank Statements (6 Months)',
        'note': 'Showing business turnover with bank verification letter',
        'icon': 'bank',
      },
      {
        'title': 'Chamber of Commerce Membership Certificate',
        'note': 'Attested valid commercial trade license',
        'icon': 'description',
      },
      {
        'title': 'Photographs & CNIC Copy',
        'note': 'Biometric specifications on plain white background',
        'icon': 'photo',
      },
    ],
    timelineSteps: [
      {
        'title': 'Commercial Credentials Scrutiny',
        'duration': '3-4 Days',
        'description':
            'Scrutiny of business invitation, Chamber certificate, and tax audit.',
        'icon': 'fact_check',
      },
      {
        'title': 'Formal Consular Submission',
        'duration': '1 Week',
        'description':
            'Direct submission at diplomatic mission or visa application center.',
        'icon': 'calendar',
      },
      {
        'title': 'Visa Issuance & Commercial Passport Release',
        'duration': '1-2 Weeks',
        'description':
            'Final commercial visa vignette sticker and passport release.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Commercial Advisory & Representation',
        'amount': 'PKR 30,000',
        'subNote': 'Invitation letter verification, cover letter, and appointment',
        'tag': 'Due Now',
      },
      {
        'label': 'Official Business Visa Fee',
        'amount': 'Official Consular Rate',
        'subNote': 'Direct consular visa fee',
        'tag': 'Embassy Fee',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 21,
        'max_age': 65,
        'bracket': '21 - 65 Years',
      },
      'education_requirement': {
        'enabled': false,
        'min_qualification': 'Not Mandatory (Experience Weighted)',
        'min_cgpa_or_marks': 'N/A',
        'field_of_study': 'Commerce / Trade / Industry',
      },
      'language_requirement': {
        'enabled': false,
        'test_type': 'Basic Business English',
        'min_score': 'N/A',
        'is_mandatory': false,
      },
      'experience_requirement': {
        'enabled': true,
        'min_years': '2+ Years Registered Business Operations',
        'role_level': 'Proprietor / Partner / Managing Director',
      },
      'financial_requirement': {
        'enabled': true,
        'min_bank_balance': 'PKR 4,000,000 (Company / Personal)',
        'holding_period': '6 Months Company Bank Statement',
        'proof_type': 'Company bank account statement with active turnover & NTN tax certificate',
      },
      'travel_history_requirement': {
        'prior_travel_required': false,
        'rejection_declaration_required': true,
        'police_certificate_required': false,
        'medical_check_required': false,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'Is your company officially registered with FBR and Chamber of Commerce?',
          'type': 'dropdown',
          'options': 'Yes - FBR NTN & Chamber Member, FBR Registered only, Sole Proprietorship in process',
          'is_required': true,
        },
        {
          'id': 'q2',
          'question': 'Do you hold an official invitation letter from an overseas partner/expo?',
          'type': 'dropdown',
          'options': 'Yes - Verified Invitation Letter, Expo Registration Badge, No - Need B2B Matchmaking Support',
          'is_required': true,
        },
      ],
    },
  );

  // --------------------------------------------------------------------------
  // 6. SCHOLARSHIP PRESET
  // --------------------------------------------------------------------------
  static const VisaCategoryPreset scholarshipPreset = VisaCategoryPreset(
    validity: 'Full Degree Tenure (Fully Funded)',
    successRate: '94%',
    applicantsCount: '1,400+ Scholars',
    processingTime: '4-6 Weeks',
    fee: 'PKR 25,000',
    serviceFeeLabel: 'SCHOLARSHIP ADVISORY FEE',
    totalPayable: 'PKR 25,000',
    statusBadge: 'Fully Funded',
    aboutTitle: 'Government & University Fully Funded Scholarships',
    aboutDescription:
        'Comprehensive advisory for Chevening, Erasmus Mundus, DAAD, Australia Awards, and university merit scholarships. We assist with research proposal drafting, Professor outreach, academic nomination, and student visa compliance.',
    eligibilityCriteria: [
      'Minimum First Class Academic Distinction (3.5+ CGPA or 75%+ marks).',
      'Age limit: Under 28 (Masters) or Under 35 (PhD).',
      'IELTS Academic 6.5 - 7.5 overall with strong written competency.',
      'Documented leadership initiatives, publications, or extracurricular awards.',
      'Strong letters of recommendation from department professors.',
    ],
    mandatoryDocuments: [
      {
        'title': 'Original Passport',
        'note': 'Valid for full duration of scholarship program',
        'icon': 'badge',
      },
      {
        'title': 'HEC Attested Degrees & Transcripts',
        'note': 'Verified official sealed transcripts',
        'icon': 'school',
      },
      {
        'title': 'Scholarship Nomination / Award Letter',
        'note': 'Official grant confirming 100% tuition and stipend',
        'icon': 'description',
      },
      {
        'title': 'IELTS Academic Test Certificate',
        'note': 'Minimum overall band 7.0 (or equivalent)',
        'icon': 'translate',
      },
      {
        'title': 'Research Proposal & Academic CV',
        'note': 'Structured academic roadmap and publications list',
        'icon': 'description',
      },
      {
        'title': 'Professor Recommendation Letters (x2)',
        'note': 'Signed on official university letterhead',
        'icon': 'description',
      },
    ],
    timelineSteps: [
      {
        'title': 'Scholarship Profile & Merit Screening',
        'duration': '3-5 Days',
        'description':
            'Academic grading audit, supervisor matching, and scholarship shortlisting.',
        'icon': 'fact_check',
      },
      {
        'title': 'Application & Research Proposal Submission',
        'duration': '2 Weeks',
        'description':
            'Formal submission to scholarship committee and interview coaching.',
        'icon': 'school',
      },
      {
        'title': 'Grant Letter Issuance & Visa Stamping',
        'duration': '3-4 Weeks',
        'description':
            'Official scholarship award documentation and fast-track student visa filing.',
        'icon': 'verified',
      },
    ],
    feeBreakdown: [
      {
        'label': 'SB Scholarship Mentorship & Filing',
        'amount': 'PKR 25,000',
        'subNote': 'Complete application, proposal review, and visa filing',
        'tag': 'Due Now',
      },
    ],
    applicationRequirements: {
      'age_requirement': {
        'enabled': true,
        'min_age': 18,
        'max_age': 28,
        'bracket': '18 - 28 Years (Strict Merit Bracket)',
      },
      'education_requirement': {
        'enabled': true,
        'min_qualification': "Bachelor's Degree (4-Year)",
        'min_cgpa_or_marks': '3.5+ CGPA or 75% Marks',
        'field_of_study': 'Relevant Academic Discipline',
      },
      'language_requirement': {
        'enabled': true,
        'test_type': 'IELTS Academic',
        'min_score': '7.0 Overall Band',
        'is_mandatory': true,
      },
      'experience_requirement': {
        'enabled': false,
        'min_years': 'Research or Academic Experience Preferred',
        'role_level': 'Scholarly Track',
      },
      'financial_requirement': {
        'enabled': false,
        'min_bank_balance': 'Exempt (Fully Funded by Grant)',
        'holding_period': 'N/A',
        'proof_type': 'Official scholarship grant letter covers 100% costs',
      },
      'travel_history_requirement': {
        'prior_travel_required': false,
        'rejection_declaration_required': true,
        'police_certificate_required': false,
        'medical_check_required': true,
      },
      'custom_questions': [
        {
          'id': 'q1',
          'question': 'What is your current grading system and score?',
          'type': 'dropdown',
          'options': 'CGPA (Scale 4.0), Percentage Marks (Scale 100%), Division / Honours System',
          'is_required': true,
        },
        {
          'id': 'q2',
          'question': 'Do you have published research papers or thesis?',
          'type': 'dropdown',
          'options': 'Yes - International Peer-Reviewed, Yes - National Journal / Conference, Thesis Completed, None',
          'is_required': true,
        },
      ],
    },
  );
}
