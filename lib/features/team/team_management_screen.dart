import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/staff_invitation_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_team_providers.dart';
import '../../services/admin_team_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedTabIndex = 0; // 0: Active Members, 1: Pending Invitations
  bool _isDirectCreationMode = true; // Option 1: Direct Account Creation with Password
  bool _obscurePassword = false;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _selectedRole = 'consultant'; // default to operational role
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateRandomPassword();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _generateRandomPassword() {
    final rand = Random();
    final numPart = rand.nextInt(9000) + 1000;
    _passwordController.text = 'SbStaff@$numPart';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      TeamAccessResult result;

      if (_isDirectCreationMode) {
        // OPTION 1: Direct Account Creation with Password
        result = await AdminTeamService.instance.createStaffDirect(
          fullName: name,
          email: email,
          password: password,
          role: _selectedRole,
        );
      } else {
        // Mode 2: Invitation Link / Pre-provisioning
        result = await AdminTeamService.instance.inviteOrGrantAccess(
          fullName: name,
          email: email,
          role: _selectedRole,
        );
      }

      _nameController.clear();
      _emailController.clear();
      _generateRandomPassword();
      ref.read(teamRevisionProvider.notifier).increment();

      if (mounted) {
        _showSuccessDialog(result, password);
      }
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AdminColors.danger),
                SizedBox(width: 10),
                Text('Operation Failed'),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(TeamAccessResult result, String plainPassword) {
    final roleName = _selectedRole == 'admin' ? 'SUPER ADMIN' : 'STAFF / CONSULTANT';
    final credentialsText = '''
*SB CONSULTANTS — STAFF LOGIN CREDENTIALS*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 *Name:* ${result.fullName ?? result.user?.fullName ?? 'Staff Member'}
📧 *Email:* ${result.email}
🔑 *Password:* $plainPassword
🛡️ *Role:* $roleName
🌐 *Portal:* https://sbconsultant.site/admin
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Please log in and update your password after initial sign-in.''';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AdminColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Staff Account Created!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.message,
                style: const TextStyle(fontSize: 13.5, color: AdminColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Credentials Presentation Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LOGIN CREDENTIALS',
                          style: TextStyle(
                            color: AdminColors.accentGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE NOW',
                            style: TextStyle(
                              color: AdminColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    _buildCredentialRow('Email:', result.email),
                    const SizedBox(height: 8),
                    _buildCredentialRow('Password:', plainPassword),
                    const SizedBox(height: 8),
                    _buildCredentialRow('Authority:', roleName),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Actions inside modal
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: credentialsText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AdminColors.success,
                            content: Text('Credentials copied! Ready to paste into WhatsApp or SMS.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Credentials', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _selectedTabIndex = 0); // show in active members
            },
            child: const Text('Done & View Active Staff', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _handleChangeRole(String userId, String targetRole, String name) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Update Privileges',
      message: 'Are you sure you want to change $name\'s role to ${targetRole.toUpperCase()}?',
      confirmLabel: 'Confirm Update',
    );

    if (confirm) {
      try {
        await AdminTeamService.instance.updateMemberRole(
          userId: userId,
          newRole: targetRole,
        );
        ref.read(teamRevisionProvider.notifier).increment();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.success,
              content: Text('Updated privileges for $name'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.danger,
              content: Text(e.toString().replaceAll('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRevokeAccess(String userId, String name) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Revoke Dashboard Authority',
      message:
          'Are you sure you want to revoke administrative dashboard authority from $name?\n\n'
          'Their account will be downgraded to a standard client profile and they will immediately lose console access.',
      confirmLabel: 'Revoke Authority',
      isDestructive: true,
    );

    if (confirm) {
      try {
        await AdminTeamService.instance.revokeAccess(userId: userId);
        ref.read(teamRevisionProvider.notifier).increment();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.info,
              content: Text('Dashboard authority revoked for $name'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.danger,
              content: Text(e.toString().replaceAll('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelInvitation(StaffInvitation invitation) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Cancel Invitation',
      message:
          'Are you sure you want to cancel the pre-provisioned invitation for ${invitation.email}?\n\n'
          'If they sign up later, they will only receive standard user permissions.',
      confirmLabel: 'Cancel Invitation',
      isDestructive: true,
    );

    if (confirm) {
      try {
        await AdminTeamService.instance.cancelInvitation(invitation.id);
        ref.read(teamRevisionProvider.notifier).increment();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.info,
              content: Text('Invitation for ${invitation.email} has been cancelled.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.danger,
              content: Text(e.toString().replaceAll('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final currentUserId =
        authState is AdminAuthAuthenticated ? authState.profile.id : '';

    final teamAsync = ref.watch(
      teamMembersListProvider((search: _searchQuery, role: _roleFilter)),
    );
    final pendingAsync = ref.watch(pendingInvitationsProvider);

    return AdminScaffold(
      title: 'Team & Staff Permissions',
      subtitle:
          'Direct Provisioning (Option 1): Create staff credentials with password directly — no email server required',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Direct Staff Account Creation Form (Option 1)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AdminColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selector Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AdminColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Staff Member',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Option 1: Directly create account and password. Instant activation — zero email dependency.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AdminColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle Option 1 vs Link
                        Container(
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Row(
                            children: [
                              _buildModeChoicePill(
                                label: 'Direct Account (Option 1)',
                                icon: Icons.key_rounded,
                                isSelected: _isDirectCreationMode,
                                onTap: () => setState(() => _isDirectCreationMode = true),
                              ),
                              _buildModeChoicePill(
                                label: 'Invite Link',
                                icon: Icons.link_rounded,
                                isSelected: !_isDirectCreationMode,
                                onTap: () => setState(() => _isDirectCreationMode = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Inputs Row 1: Name and Email
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Input
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Staff Full Name',
                              hintText: 'e.g. Bilal Asif',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Staff name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Email Input
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Staff Email / Login ID',
                              hintText: 'e.g. bilalasif8988@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Inputs Row 2: Password and Role
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Password (only shown in Direct Creation Mode)
                        if (_isDirectCreationMode) ...[
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Assigned Password',
                                hintText: 'Min 6 characters',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Auto-Generate Random Password',
                                      icon: const Icon(Icons.auto_awesome, size: 18, color: AdminColors.primary),
                                      onPressed: _generateRandomPassword,
                                    ),
                                    IconButton(
                                      tooltip: _obscurePassword ? 'Show' : 'Hide',
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: AdminColors.textSecondary,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ],
                                ),
                              ),
                              validator: (val) {
                                if (!_isDirectCreationMode) return null;
                                if (val == null || val.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Role Dropdown
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Authority Tier',
                              prefixIcon: Icon(Icons.security, size: 20),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'consultant',
                                child: Text('Staff / Consultant (Operations — No Payments)'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Super Admin (Full Access & Revenue Metrics)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRole = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Submit Button
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(_isDirectCreationMode ? Icons.key_rounded : Icons.send_rounded, size: 18),
                            label: Text(
                              _isSubmitting
                                  ? 'Creating...'
                                  : (_isDirectCreationMode ? 'Create Staff Account' : 'Generate Invite Link'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Explanatory helper box for two tiers
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: AdminColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Direct Provisioning: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bypasses email verification. The account and password are created immediately so you can copy and share them directly with staff.   •   ',
                                  ),
                                  TextSpan(
                                    text: 'Staff / Consultant: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Operations only. Can manage Visas, Applications, and Client dossiers. Revenue figures and payments are strictly hidden.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Custom Navigation Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  index: 0,
                  icon: Icons.people_outline,
                  label: teamAsync.when(
                    data: (m) => 'Active Team Members (${m.length})',
                    loading: () => 'Active Team Members (...)',
                    error: (_, __) => 'Active Team Members',
                  ),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  index: 1,
                  icon: Icons.outgoing_mail,
                  label: pendingAsync.when(
                    data: (p) => 'Pending Invitations (${p.length})',
                    loading: () => 'Pending Invitations (...)',
                    error: (_, __) => 'Pending Invitations',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Tab Contents
          if (_selectedTabIndex == 0) ...[
            // Active Team Members Section
            SearchFilterBar<String>(
              searchController: _searchController,
              searchHint: 'Search team by name, email, or phone...',
              onSearchChanged: (val) {
                setState(() => _searchQuery = val);
              },
              filterValue: _roleFilter,
              filterLabel: 'Tier',
              filterItems: const [
                FilterDropdownItem(value: 'all', label: 'All Staff'),
                FilterDropdownItem(value: 'admin', label: 'Super Admins'),
                FilterDropdownItem(value: 'consultant', label: 'Consultants / Staff'),
              ],
              onFilterChanged: (val) {
                if (val != null) setState(() => _roleFilter = val);
              },
              onRefresh: () {
                ref.read(teamRevisionProvider.notifier).increment();
              },
            ),
            const SizedBox(height: 16),
            teamAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading team members: $err'),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('No active team members matching criteria.'),
                      ),
                    ),
                  );
                }

                return DataTableCard(
                  title: 'Active Authorized Staff (${members.length})',
                  subtitle: 'Accounts currently possessing administrative dashboard access',
                  columns: const [
                    DataColumn(label: Text('MEMBER')),
                    DataColumn(label: Text('ACCESS TIER')),
                    DataColumn(label: Text('PERMISSIONS SCOPE')),
                    DataColumn(label: Text('JOINED')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: members.map((m) {
                    final isSelf = m.id == currentUserId;

                    return DataRow(
                      cells: [
                        // Member Identity
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: m.isAdmin
                                    ? AdminColors.primary
                                    : const Color(0xFF0284C7),
                                child: Text(
                                  (m.fullName?.isNotEmpty ?? false)
                                      ? m.fullName![0].toUpperCase()
                                      : (m.email.isNotEmpty ? m.email[0].toUpperCase() : 'A'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (m.fullName != null && m.fullName!.isNotEmpty)
                                                ? m.fullName!
                                                : m.email.split('@').first,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (isSelf) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AdminColors.accentGold.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF78350F),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      m.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AdminColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Role Badge
                        DataCell(
                          m.isAdmin
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AdminColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield, size: 13, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'SUPER ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.badge_outlined,
                                          size: 13, color: Color(0xFF0369A1)),
                                      SizedBox(width: 5),
                                      Text(
                                        'STAFF / CONSULTANT',
                                        style: TextStyle(
                                          color: Color(0xFF0369A1),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),

                        // Permissions Scope
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Text(
                              m.isAdmin
                                  ? 'Full Unrestricted • Revenue, Team, Visas'
                                  : 'Operations Only • Visas & Applications (No Payments)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: m.isAdmin
                                    ? AdminColors.textPrimary
                                    : AdminColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        // Date Joined
                        DataCell(
                          Text(
                            DateFormat('dd MMM yyyy').format(m.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                        // Actions
                        DataCell(
                          isSelf
                              ? const Text(
                                  'Current Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AdminColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Switch Tier
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () {
                                        final targetRole =
                                            m.isAdmin ? 'consultant' : 'admin';
                                        _handleChangeRole(
                                          m.id,
                                          targetRole,
                                          m.fullName ?? m.email,
                                        );
                                      },
                                      icon: Icon(
                                        m.isAdmin
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14,
                                      ),
                                      label: Text(
                                        m.isAdmin
                                            ? 'Make Consultant'
                                            : 'Make Admin',
                                        style: const TextStyle(fontSize: 11.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Revoke
                                    IconButton(
                                      tooltip: 'Revoke Dashboard Access',
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: AdminColors.danger,
                                        size: 19,
                                      ),
                                      onPressed: () => _handleRevokeAccess(
                                        m.id,
                                        m.fullName ?? m.email,
                                      ),
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
          ] else ...[
            // Pending Invitations Section
            pendingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading pending invitations: $err'),
                ),
              ),
              data: (invitations) {
                if (invitations.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AdminColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.mark_email_read_outlined,
                                size: 48, color: AdminColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No Pending Invitations',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'All invited staff members have registered and claimed their administrative access.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return DataTableCard(
                  title: 'Pending Staff Invitations (${invitations.length})',
                  subtitle:
                      'Pre-provisioned accounts. When these users sign in with their email, permissions will activate automatically.',
                  columns: const [
                    DataColumn(label: Text('INVITED EMAIL')),
                    DataColumn(label: Text('PRE-ASSIGNED TIER')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('INVITED DATE')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: invitations.map((inv) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 16, color: AdminColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    inv.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          inv.isAdmin
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AdminColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SUPER ADMIN',
                                    style: TextStyle(
                                      color: AdminColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'STAFF / CONSULTANT',
                                    style: TextStyle(
                                      color: Color(0xFF0369A1),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Awaiting User Login',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(inv.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (inv.inviteLink != null && inv.inviteLink!.isNotEmpty) ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AdminColors.primary,
                                    side: const BorderSide(color: AdminColors.primary),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: inv.inviteLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AdminColors.success,
                                        content: Text('Direct activation link copied! Share with staff.'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.link, size: 14),
                                  label: const Text('Copy Link', style: TextStyle(fontSize: 11.5)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminColors.danger,
                                  side: const BorderSide(color: AdminColors.danger),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () => _handleCancelInvitation(inv),
                                icon: const Icon(Icons.cancel_outlined, size: 14),
                                label: const Text('Cancel Invite', style: TextStyle(fontSize: 11.5)),
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
        ],
      ),
    );
  }

  Widget _buildModeChoicePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AdminColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AdminColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
