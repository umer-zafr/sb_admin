import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_booking_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRescheduleDialog(ConsultancyBookingItem booking) {
    final dateController = TextEditingController(text: booking.bookingDate);
    final slotController = TextEditingController(text: booking.bookingTimeSlot);
    final consultantController =
        TextEditingController(text: booking.consultantName ?? 'Senior Visa Officer');
    final linkController =
        TextEditingController(text: booking.meetingLink ?? 'https://meet.google.com/sb-consult');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reschedule Booking #${booking.bookingReference}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appointment Date',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: dateController),
              const SizedBox(height: 12),
              const Text('Time Slot',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: slotController),
              const SizedBox(height: 12),
              const Text('Assigned Consultant',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: consultantController),
              const SizedBox(height: 12),
              const Text('Meeting Link (Google Meet / Zoom)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: linkController),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminBookingService.instance.rescheduleBooking(
                bookingId: booking.id,
                bookingDate: dateController.text.trim(),
                timeSlot: slotController.text.trim(),
                consultantName: consultantController.text.trim(),
                meetingLink: linkController.text.trim(),
              );
              ref.invalidate(bookingsListProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save & Notify Client'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(
      bookingsListProvider((search: _searchQuery, status: _statusFilter)),
    );

    return AdminScaffold(
      title: 'Consultancy Bookings',
      subtitle: 'Schedule, assign, and verify one-on-one sessions between clients and visa advisors',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search bookings by reference, service, or consultant...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: [
              const FilterDropdownItem(value: 'all', label: 'All Bookings'),
              ...AdminConstants.bookingStatuses.map(
                (s) => FilterDropdownItem(
                  value: s,
                  label: s.toUpperCase(),
                ),
              ),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            onRefresh: () => ref.invalidate(bookingsListProvider),
          ),
          const SizedBox(height: 20),

          bookingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading bookings: $err'),
              ),
            ),
            data: (bookings) {
              return DataTableCard(
                title: 'Scheduled Consultation Sessions (${bookings.length})',
                subtitle: 'Directly linked to Step 2 (Consultant Call) of client applications',
                columns: const [
                  DataColumn(label: Text('REFERENCE')),
                  DataColumn(label: Text('CLIENT')),
                  DataColumn(label: Text('SERVICE')),
                  DataColumn(label: Text('DATE & TIME')),
                  DataColumn(label: Text('CONSULTANT')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: bookings.map((b) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          b.bookingReference,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AdminColors.primary),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                b.userName ?? 'Client Profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                              ),
                              Text(
                                b.userEmail ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            b.serviceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${b.bookingDate}\n${b.bookingTimeSlot}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: Text(
                            b.consultantName ?? 'Senior Officer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(StatusBadge(status: b.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (b.isPending) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 20, color: AdminColors.success),
                                tooltip: 'Confirm Booking',
                                onPressed: () async {
                                  await AdminBookingService.instance
                                      .updateBookingStatus(b.id, 'confirmed');
                                  ref.invalidate(bookingsListProvider);
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                              tooltip: 'Reschedule Session',
                              onPressed: () => _showRescheduleDialog(b),
                            ),
                            if (!b.isCompleted) ...[
                              IconButton(
                                icon: const Icon(Icons.task_alt_rounded,
                                    size: 18, color: AdminColors.info),
                                tooltip: 'Mark Completed',
                                onPressed: () async {
                                  await AdminBookingService.instance
                                      .updateBookingStatus(b.id, 'completed');
                                  ref.invalidate(bookingsListProvider);
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  size: 18, color: AdminColors.danger),
                              tooltip: 'Cancel Booking',
                              onPressed: () async {
                                final confirm = await ConfirmationDialog.show(
                                  context,
                                  title: 'Cancel Booking',
                                  message:
                                      'Are you sure you want to cancel booking #${b.bookingReference}?',
                                  confirmLabel: 'Cancel Session',
                                  isDestructive: true,
                                );
                                if (confirm) {
                                  await AdminBookingService.instance
                                      .updateBookingStatus(b.id, 'cancelled');
                                  ref.invalidate(bookingsListProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
