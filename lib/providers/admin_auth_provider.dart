import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../services/admin_auth_service.dart';

sealed class AdminAuthState {
  const AdminAuthState();
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminAuthAuthenticated extends AdminAuthState {
  const AdminAuthAuthenticated(this.profile);
  final AdminUserProfile profile;
}

class AdminAuthUnauthenticated extends AdminAuthState {
  const AdminAuthUnauthenticated([this.errorMessage]);
  final String? errorMessage;
}

class AdminAuthNotifier extends Notifier<AdminAuthState> {
  final _service = AdminAuthService.instance;

  @override
  AdminAuthState build() {
    Future.microtask(() => checkSession());
    return const AdminAuthInitial();
  }

  Future<void> checkSession() async {
    state = const AdminAuthLoading();
    try {
      final profile = await _service.getCurrentProfile();
      if (profile != null && profile.isStaff) {
        state = AdminAuthAuthenticated(profile);
      } else {
        state = const AdminAuthUnauthenticated();
      }
    } catch (e) {
      state = AdminAuthUnauthenticated(e.toString());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AdminAuthLoading();
    try {
      final profile = await _service.signIn(email: email, password: password);
      state = AdminAuthAuthenticated(profile);
    } catch (e) {
      state = AdminAuthUnauthenticated(
        e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AdminAuthUnauthenticated();
  }
}

final adminAuthProvider =
    NotifierProvider<AdminAuthNotifier, AdminAuthState>(() {
  return AdminAuthNotifier();
});
