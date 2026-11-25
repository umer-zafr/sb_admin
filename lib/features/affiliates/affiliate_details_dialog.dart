import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/affiliate_model.dart';
import '../../widgets/status_badge.dart';

class AffiliateDetailsDialog extends StatelessWidget {
  const AffiliateDetailsDialog({
    super.key,
    required this.affiliate,
  });

  final AffiliateItem affiliate;

  static void show(BuildContext context, {required AffiliateItem affiliate}) {
    showDialog(
      context: context,
      builder: (ctx) => AffiliateDetailsDialog(affiliate: affiliate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aff = affiliate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        aff.name.isNotEmpty ? aff.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  aff.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: aff.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Applied from ${aff.city}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AdminColors.textMuted,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AdminColors.border),
                const SizedBox(height: 20),

                // Key Metrics Row
                Row(
                  children: [
                    _buildMetricBox(
                      'AUDIENCE REACH',
                      '${aff.totalFollowers.toString()} followers',
                      Icons.people_outline_rounded,
                      AdminColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricBox(
                      'REFERRALS USED',
                      '${aff.referralCount} clients',
                      Icons.shopping_bag_outlined,
                      AdminColors.info,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricBox(
                      'TOTAL EARNED',
                      'PKR ${aff.totalEarnings.toInt()}',
                      Icons.payments_outlined,
                      AdminColors.success,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Contact Details
                const Text(
                  'CONTACT INFORMATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoTile(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: aff.email,
                  canCopy: true,
                ),
                const SizedBox(height: 8),
                _buildInfoTile(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'WhatsApp / Phone',
                  value: aff.phone,
                  canCopy: true,
                ),
                const SizedBox(height: 8),
                _buildInfoTile(
                  context,
                  icon: Icons.location_on_outlined,
                  label: 'City & Region',
                  value: aff.city,
                  canCopy: false,
                ),

                const SizedBox(height: 20),

                // Social Media Profiles
                const Text(
                  'SOCIAL MEDIA PLATFORMS & PROFILES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (aff.profileLinks.isEmpty && aff.platforms.isEmpty)
                  const Text(
                    'No social links provided',
                    style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: aff.platforms.map((platform) {
                      final url = aff.profileLinks[platform] ?? '';
                      return InkWell(
                        onTap: url.isNotEmpty
                            ? () {
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$platform link copied to clipboard!'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _getPlatformIcon(platform),
                              const SizedBox(width: 8),
                              Text(
                                platform,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              if (url.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded, size: 14, color: AdminColors.textMuted),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // Promo Code Configuration (if approved)
                if (aff.isApproved) ...[
                  const Text(
                    'ASSIGNED PROMO CODE & DISCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded, color: AdminColors.success),
                            const SizedBox(width: 10),
                            Text(
                              aff.promoCode ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.success,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          aff.discountType == 'percentage'
                              ? '${aff.discountValue.toInt()}% OFF'
                              : 'PKR ${aff.discountValue.toInt()} OFF',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (aff.notes != null && aff.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'ADMIN NOTES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Text(
                      aff.notes!,
                      style: const TextStyle(fontSize: 13, color: AdminColors.textPrimary),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool canCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AdminColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: AdminColors.textSecondary,
              tooltip: 'Copy $label',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('instagram')) {
      return const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.purple);
    }
    if (p.contains('youtube')) {
      return const Icon(Icons.play_circle_fill_rounded, size: 16, color: Colors.red);
    }
    if (p.contains('tiktok')) {
      return const Icon(Icons.music_note_rounded, size: 16, color: Colors.black87);
    }
    if (p.contains('facebook')) {
      return const Icon(Icons.facebook_rounded, size: 16, color: Colors.blue);
    }
    if (p.contains('linkedin')) {
      return const Icon(Icons.business_center_rounded, size: 16, color: Colors.blueAccent);
    }
    return const Icon(Icons.link_rounded, size: 16, color: AdminColors.primary);
  }
}

