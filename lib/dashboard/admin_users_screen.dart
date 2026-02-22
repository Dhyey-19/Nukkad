import 'package:flutter/material.dart';
import 'package:nukkad/services/admin_service.dart';
import 'package:nukkad/utils/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final data = await _adminService.getUsers(
      role: roleFilter == 'all' ? null : roleFilter,
    );
    setState(() {
      users = data;
      isLoading = false;
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final current = user['is_active'] == true;
    final ok = await _adminService.updateUserStatus(
      userId: user['user_id'],
      isActive: !current,
    );
    if (ok) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Users'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_alt_outlined),
              onSelected: (val) {
                setState(() => roleFilter = val);
                _loadUsers();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'all', child: Text('All')),
                PopupMenuItem(value: 'customer', child: Text('Customers')),
                PopupMenuItem(value: 'business', child: Text('Businesses')),
                PopupMenuItem(value: 'admin', child: Text('Admins')),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadUsers,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: Text(
                              (u['full_name'] ?? 'U').toString().substring(
                                0,
                                1,
                              ),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['full_name'] ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${u['role']} • ${u['phone'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              u['is_active'] == true
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                              color: u['is_active'] == true
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                            tooltip: 'Toggle active',
                            onPressed: () => _toggleActive(u),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
