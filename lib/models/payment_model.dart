class AdminPaymentItem {
  const AdminPaymentItem({
    required this.id,
    required this.userId,
    this.applicationId,
    this.listingId,
    required this.transactionId,
    required this.referenceId,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'PKR',
    required this.status, // 'pending', 'success', 'completed', 'failed', 'refunded'
    this.promoCode,
    this.discountAmount,
    this.serviceFee,
    this.processingFee,
    this.proofFileUrl,
    this.gatewayResponse,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String userId;
  final String? applicationId;
  final String? listingId;
  final String transactionId;
  final String referenceId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final String? promoCode;
  final double? discountAmount;
  final double? serviceFee;
  final double? processingFee;
  final String? proofFileUrl;
  final dynamic gatewayResponse;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  bool get isSuccessful => status == 'success' || status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  /// Human-friendly formatted payment channel / method label
  String get displayPaymentMethod {
    final lowerMethod = paymentMethod.toLowerCase();

    final isBankTransfer = lowerMethod.contains('bank') ||
        lowerMethod.contains('ibft') ||
        lowerMethod.contains('wire') ||
        transactionId.toUpperCase().startsWith('IBFT') ||
        (gatewayResponse is Map &&
            (gatewayResponse['channel'] == '1link_ibft' ||
                gatewayResponse['channel'] == 'bank_transfer' ||
                gatewayResponse['bank'] != null ||
                gatewayResponse['sender_name'] != null));

    if (isBankTransfer) {
      if (gatewayResponse is Map && gatewayResponse['bank'] != null) {
        final bName = gatewayResponse['bank'].toString();
        if (bName.isNotEmpty) return 'Bank Transfer ($bName)';
      }
      return 'Bank Transfer (1Link IBFT)';
    }

    if (lowerMethod.contains('card') || lowerMethod.contains('visa') || lowerMethod.contains('master')) {
      return 'Debit / Credit Card';
    }
    if (lowerMethod.contains('jazz')) {
      return 'JazzCash';
    }
    if (lowerMethod.contains('easy')) {
      return 'EasyPaisa';
    }
    if (lowerMethod == 'payfast') {
      return 'PayFast Gateway';
    }

    return paymentMethod.toUpperCase();
  }

  factory AdminPaymentItem.fromMap(
    Map<String, dynamic> map, {
    String? userName,
    String? userEmail,
  }) {
    final gw = map['gateway_response'];
    final tx = map['transaction_id']?.toString() ?? '';
    final rawMethod = map['payment_method']?.toString();
    final isBank = tx.toUpperCase().startsWith('IBFT') ||
        (rawMethod != null &&
            (rawMethod.contains('bank') ||
                rawMethod.contains('ibft') ||
                rawMethod.contains('wire'))) ||
        (gw is Map &&
            (gw['channel'] == '1link_ibft' ||
                gw['channel'] == 'bank_transfer' ||
                gw['bank'] != null ||
                gw['sender_name'] != null));

    return AdminPaymentItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      applicationId: map['application_id']?.toString(),
      listingId: map['listing_id']?.toString(),
      transactionId: tx,
      referenceId: map['reference_id']?.toString() ?? '',
      paymentMethod: isBank ? 'bank_transfer' : (rawMethod ?? 'bank_transfer'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'PKR',
      status: map['status']?.toString() ?? 'pending',
      promoCode: map['promo_code']?.toString(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble(),
      serviceFee: (map['service_fee'] as num?)?.toDouble(),
      processingFee: (map['processing_fee'] as num?)?.toDouble(),
      proofFileUrl: map['proof_file_url']?.toString(),
      gatewayResponse: gw,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      userName: userName,
      userEmail: userEmail,
    );
  }

  AdminPaymentItem copyWith({
    String? id,
    String? userId,
    String? applicationId,
    String? listingId,
    String? transactionId,
    String? referenceId,
    String? paymentMethod,
    double? amount,
    String? currency,
    String? status,
    String? promoCode,
    double? discountAmount,
    double? serviceFee,
    double? processingFee,
    String? proofFileUrl,
    dynamic gatewayResponse,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
  }) {
    return AdminPaymentItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      applicationId: applicationId ?? this.applicationId,
      listingId: listingId ?? this.listingId,
      transactionId: transactionId ?? this.transactionId,
      referenceId: referenceId ?? this.referenceId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      promoCode: promoCode ?? this.promoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      processingFee: processingFee ?? this.processingFee,
      proofFileUrl: proofFileUrl ?? this.proofFileUrl,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
