import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/affiliate_model.dart';
import '../../services/admin_affiliate_service.dart';

class AffiliateApprovalDialog extends StatefulWidget {
  const AffiliateApprovalDialog({
    super.key,
    required this.affiliate,
  });

  final AffiliateItem affiliate;

  static Future<bool?> show(
    BuildContext context, {
    required AffiliateItem affiliate,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AffiliateApprovalDialog(affiliate: affiliate),
    );
  }

  @override
  State<AffiliateApprovalDialog> createState() =>
      _AffiliateApprovalDialogState();
}

class _AffiliateApprovalDialogState extends State<AffiliateApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _promoCodeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _commissionController;
  late final TextEditingController _notesController;

  late String _discountType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final aff = widget.affiliate;

    // Generate initial suggested promo code if not already set
    String initialCode = aff.promoCode ?? '';
    if (initialCode.isEmpty) {
      final cleanName = aff.name
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toUpperCase();
      final prefix = cleanName.length >= 4
          ? cleanName.substring(0, 4)
          : (cleanName.padRight(4, 'X'));
      initialCode = '${prefix}10';
    }

    _promoCodeController = TextEditingController(text: initialCode);
    _discountType = aff.discountType.isNotEmpty ? aff.discountType : 'percentage';
    _discountValueController = TextEditingController(
      text: aff.discountValue > 0
          ? (aff.discountValue % 1 == 0
              ? aff.discountValue.toInt().toString()
              : aff.discountValue.toString())
          : (_discountType == 'percentage' ? '10' : '500'),
    );
    _commissionController = TextEditingController(
      text: (aff.commissionPerReferral % 1 == 0)
          ? aff.commissionPerReferral.toInt().toString()
          : aff.commissionPerReferral.toString(),
    );
    _notesController = TextEditingController(text: aff.notes ?? '');
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _discountValueController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _promoCodeController.text.trim().toUpperCase();
    final discountVal = double.tryParse(_discountValueController.text.trim()) ?? 0.0;
    final commissionVal = double.tryParse(_commissionController.text.trim()) ?? 1000.0;
    final notes = _notesController.text.trim();

    if (discountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount value must be greater than 0'),
          backgroundColor: AdminColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AdminAffiliateService.instance.approveAffiliate(
        affiliateId: widget.affiliate.id,
        affiliateName: widget.affiliate.name,
        promoCode: code,
        discountType: _discountType,
        discountValue: discountVal,
        commissionPerReferral: commissionVal,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate promo code: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aff = widget.affiliate;
    final isAlreadyApproved = aff.isApproved;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.successBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AdminColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAlreadyApproved
                                  ? 'Update Promo & Terms'
                                  : 'Approve & Assign Promo Code',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Assign an active voucher code for ${aff.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AdminColors.textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Partner Quick Info Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: AdminColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${aff.name} • ${aff.city} (${aff.totalFollowers.toString()} followers)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Promo Code Field
                  const Text(
                    'PROMO CODE (UPPERCASE)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _promoCodeController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                    ],
                    onChanged: (val) {
                      final upper = val.toUpperCase();
                      if (val != upper) {
                        _promoCodeController.value = _promoCodeController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. UMER10, VISA20, INFLUENCER15',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.primary, width: 2),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Promo code cannot be empty';
                      }
                      if (val.trim().length < 3) {
                        return 'Promo code must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Discount Type Selector (Percentage vs Fixed PKR)
                  const Text(
                    'DISCOUNT TYPE FOR CLIENTS IN APP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _discountType = 'percentage';
                              if (_discountValueController.text == '500') {
                                _discountValueController.text = '10';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _discountType == 'percentage'
                                  ? AdminColors.primary.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _discountType == 'percentage'
                                    ? AdminColors.primary
                                    : AdminColors.border,
                                width: _discountType == 'percentage' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _discountType == 'percentage'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: _discountType == 'percentage'
                                      ? AdminColors.primary
                                      : AdminColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Percentage (%)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _discountType = 'fixed';
                              if (_discountValueController.text == '10') {
                                _discountValueController.text = '500';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _discountType == 'fixed'
                                  ? AdminColors.primary.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _discountType == 'fixed'
                                    ? AdminColors.primary
                                    : AdminColors.border,
                                width: _discountType == 'fixed' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _discountType == 'fixed'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: _discountType == 'fixed'
                                      ? AdminColors.primary
                                      : AdminColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Fixed Amount (PKR)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Discount Value & Commission Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discount Value Field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _discountType == 'percentage'
                                  ? 'DISCOUNT PERCENTAGE (%)'
                                  : 'DISCOUNT AMOUNT (PKR)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _discountValueController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: _discountType == 'percentage' ? 'e.g. 15' : 'e.g. 500',
                                suffixText: _discountType == 'percentage' ? '%' : 'PKR',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AdminColors.border),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final num = double.tryParse(val.trim());
                                if (num == null || num <= 0) return 'Invalid value';
                                if (_discountType == 'percentage' && num > 100) {
                                  return 'Max 100%';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Commission Field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PARTNER COMMISSION (PKR)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _commissionController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '1000',
                                suffixText: 'PKR',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AdminColors.border),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) return 'Invalid value';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Admin Notes Field
                  const Text(
                    'INTERNAL NOTES (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Campaign agreed: 1 YouTube video + 3 Instagram stories',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AdminColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Summary Alert Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.infoBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.info.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AdminColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saving will immediately create this promo code in the Supabase database. Mobile app clients entering this code at checkout will receive the discount, and referrals will automatically count on the partner’s web dashboard.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AdminColors.info.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: AdminColors.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isAlreadyApproved
                                    ? 'Save Promo Code Changes'
                                    : 'Approve & Activate Promo Code',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
