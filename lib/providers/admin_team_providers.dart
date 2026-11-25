import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../models/staff_invitation_model.dart';
import '../services/admin_team_service.dart';

class TeamRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final teamRevisionProvider =
    NotifierProvider<TeamRevisionNotifier, int>(TeamRevisionNotifier.new);

final teamMembersListProvider = FutureProvider.family<
    List<AdminUserProfile>,
    ({String? search, String? role})>((ref, params) async {
  ref.watch(teamRevisionProvider);
  return AdminTeamService.instance.getTeamMembers(
    searchQuery: params.search,
    roleFilter: params.role,
  );
});

final pendingInvitationsProvider = FutureProvider<List<StaffInvitation>>((ref) async {
  ref.watch(teamRevisionProvider);
  return AdminTeamService.instance.getPendingInvitations();
});
