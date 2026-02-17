import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getAdminUsers();
      if (result['success'] == true && result['data'] != null) {
        final content = result['data']['content'] ?? result['data'];
        final list = (content is List) ? content : [];
        setState(() {
          _users = list.map<AppUser>((u) => AppUser(
            id: u['id']?.toString(),
            name: '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim(),
            username: u['username'] ?? '',
            email: u['email'] ?? '',
            firstName: u['firstName'] ?? '',
            lastName: u['lastName'] ?? '',
            role: (u['role'] ?? 'employee').toString().toLowerCase().replaceAll('role_', ''),
            status: (u['active'] == true || u['active'] == 'true') ? 'active' : 'inactive',
            active: u['active'] == true || u['active'] == 'true',
          )).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('User Management',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${users.length} users',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = users[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryDark,
                        child: Text(
                          u.firstName.isNotEmpty
                              ? u.firstName[0]
                              : u.username[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${u.role} · ${u.email}',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMid)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: u.status == 'active'
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.textLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          u.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: u.status == 'active'
                                ? AppColors.success
                                : AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMid),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (v) async {
                          if (v == 'toggle') {
                            try {
                              await ApiService.updateUser(u.id!, {'active': !u.active});
                              _fetchUsers();
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          } else if (v == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete User?'),
                                content: Text('Remove "${u.name}" permanently?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await ApiService.deleteUser(u.id!);
                                _fetchUsers();
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showCreateDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = ValueNotifier('EMPLOYEE');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Create User'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password * (min 8 chars)', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: roleCtrl,
                builder: (_, val, __) => DropdownButtonFormField<String>(
                  initialValue: val,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: ['ADMIN', 'SUPERVISOR', 'EMPLOYEE'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => roleCtrl.value = v!,
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (usernameCtrl.text.trim().length < 3 || passwordCtrl.text.length < 8 || firstNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields (username 3+, password 8+, first name)'), backgroundColor: AppColors.error));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.createUser({
                  'username': usernameCtrl.text.trim(),
                  'password': passwordCtrl.text,
                  'firstName': firstNameCtrl.text.trim(),
                  'lastName': lastNameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'role': roleCtrl.value,
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created'), backgroundColor: AppColors.success));
                _fetchUsers();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
