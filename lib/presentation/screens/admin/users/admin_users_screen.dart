import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';
import '../../../widgets/admin/auth_wrapper.dart';
import 'user_details_screen.dart';
import 'add_user_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class AdminUsersScreenWithAuth extends StatelessWidget {
  const AdminUsersScreenWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAuthWrapper(
      child: AdminUsersScreen(),
    );
  }
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showAddUserDialog = false;
  Map<String, dynamic>? _editingUser;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  String _selectedRole = 'customer';
  String _selectedStatus = 'active';
  bool _phoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();

    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response.data['data']);
          _filteredUsers = List.from(_users);
        });
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorLoadingUsers}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final name = user['full_name']?.toString().toLowerCase() ?? '';
          final phone = user['phone']?.toString().toLowerCase() ?? '';
          final company = user['company_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              phone.contains(searchLower) ||
              company.contains(searchLower);
        }).toList();
      }
    });
  }

  void _openAddUserDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserScreen(
          onUserAdded: (newUser) {
            setState(() {
              _users.insert(0, newUser);
              _filteredUsers.insert(0, newUser);
            });
          },
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    _editingUser = user;
    _fullNameController.text = user['full_name'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _companyNameController.text = user['company_name'] ?? '';

    _selectedRole = user['role'] ?? 'customer';
    _selectedStatus = user['status'] ?? 'active';
    _phoneVerified = user['phone_verified'] ?? false;
    _passwordController.clear();

    setState(() {
      _showAddUserDialog = true;
    });
  }

  void _resetForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _companyNameController.clear();

    _selectedRole = 'customer';
    _selectedStatus = 'active';
    _phoneVerified = false;
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userData = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'status': _selectedStatus,
        'phone_verified': _phoneVerified,
        'company_name': _companyNameController.text.trim().isEmpty
            ? null
            : _companyNameController.text.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      if (_editingUser != null) {
        // Update existing user
        await _apiService.put('/users/${_editingUser!['id']}', data: userData);
        _showSnackBar(ArabicText.userUpdatedSuccessfully);
      } else {
        // Create new user
        if (_passwordController.text.isEmpty) {
          _showSnackBar(ArabicText.passwordRequiredForNewUsers, isError: true);
          return;
        }
        await _apiService.post('/users', data: userData);
        _showSnackBar(ArabicText.userCreatedSuccessfully);
      }

      setState(() {
        _showAddUserDialog = false;
      });
      _resetForm();
      _loadUsers();
    } catch (e) {
      _showSnackBar('${ArabicText.errorSavingUser}: $e', isError: true);
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ArabicText.confirm),
        content: const Text(
          ArabicText.confirmDeleteUser,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(ArabicText.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUser(userId);
            },
            child: const Text(ArabicText.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/users/$userId');
        _showSnackBar(ArabicText.userDeletedSuccessfully);
        _loadUsers();
      } catch (e) {
        _showSnackBar(ArabicText.errorDeletingUser, isError: true);
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newStatus = user['status'] == 'active' ? 'suspended' : 'active';
      await _apiService
          .put('/users/${user['id']}/status', data: {'status': newStatus});
      _showSnackBar(ArabicText.userStatusUpdatedSuccessfully);
      _loadUsers();
    } catch (e) {
      _showSnackBar(ArabicText.errorUpdatingUserStatus, isError: true);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(user: user),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search and Filters Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterUsers,
                        decoration: InputDecoration(
                          hintText: ArabicText.search,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${_filteredUsers.length} ${ArabicText.results}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.people_outline
                                      : Icons.search_off,
                                  size: 48,
                                  color: AppColors.textSecondaryColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? ArabicText.noCustomersYet
                                      : ArabicText.noCustomersFound,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${ArabicText.addYourFirst} ${ArabicText.users.toLowerCase()} ${ArabicText.toGetStarted}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _buildUserCard(user);
                            },
                          ),
              ),
            ],
          ),

          // Add/Edit User Dialog
          if (_showAddUserDialog) _buildUserDialog(),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 'active';
    final isPhoneVerified = user['phone_verified'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailsScreen(user: user),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar and basic info
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isActive ? AppColors.primaryColor : Colors.grey.shade300,
                child: Text(
                  (user['full_name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['full_name'] ?? ArabicText.unnamedUser,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.successColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            isActive ? ArabicText.active : ArabicText.inactive,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          user['phone'] ?? ArabicText.noPhone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isPhoneVerified)
                          const Icon(Icons.verified,
                              size: 12, color: AppColors.successColor),
                      ],
                    ),
                    if (user['company_name'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            user['company_name'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle status button
                  IconButton(
                    onPressed: () => _toggleUserStatus(user),
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle,
                      size: 18,
                      color: isActive ? Colors.orange : AppColors.successColor,
                    ),
                    tooltip: isActive
                        ? ArabicText.suspendUser
                        : ArabicText.activateUser,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // View details button
                  IconButton(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.info_outline,
                        size: 18, color: AppColors.primaryColor),
                    tooltip: ArabicText.viewDetails,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit,
                        size: 18, color: AppColors.secondaryColor),
                    tooltip: ArabicText.editUser,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _deleteUser(user['id']),
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade400),
                    tooltip: ArabicText.deleteUser,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add/Edit User Dialog
  Widget _buildUserDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _editingUser != null ? Icons.edit : Icons.person_add,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _editingUser != null
                          ? ArabicText.editCustomer
                          : ArabicText.addNewCustomer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: ArabicText.fullName,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return ArabicText.fullNameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: ArabicText.phoneNumber,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return ArabicText.phoneNumberRequired;
                            }
                            if (value.trim().length < 10) {
                              return ArabicText
                                  .phoneNumberMustBeAtLeastTenDigits;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password (only for new users or when editing)
                        if (_editingUser == null ||
                            _passwordController.text.isNotEmpty)
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: _editingUser == null
                                  ? ArabicText.password
                                  : ArabicText
                                      .newPasswordLeaveEmptyToKeepCurrent,
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (_editingUser == null &&
                                  (value == null || value.trim().isEmpty)) {
                                return ArabicText.passwordRequiredForNewUsers;
                              }
                              if (value != null &&
                                  value.trim().isNotEmpty &&
                                  value.trim().length < 6) {
                                return ArabicText
                                    .passwordMustBeAtLeastSixCharacters;
                              }
                              return null;
                            },
                          ),
                        if (_editingUser == null ||
                            _passwordController.text.isNotEmpty)
                          const SizedBox(height: 16),

                        // Company Name
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: ArabicText.companyName,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        // Role and Status Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: const InputDecoration(
                                  labelText: ArabicText.role,
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'customer',
                                      child: Text(ArabicText.customer)),
                                  DropdownMenuItem(
                                      value: 'admin',
                                      child: Text(ArabicText.admin)),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: ArabicText.status,
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'active',
                                      child: Text(ArabicText.active)),
                                  DropdownMenuItem(
                                      value: 'suspended',
                                      child: Text(ArabicText.suspended)),
                                  DropdownMenuItem(
                                      value: 'pending',
                                      child: Text(ArabicText.pending)),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Phone Verified Checkbox
                        CheckboxListTile(
                          title: const Text(ArabicText.phoneVerified),
                          value: _phoneVerified,
                          onChanged: (value) {
                            setState(() {
                              _phoneVerified = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dialog Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAddUserDialog = false;
                        });
                        _resetForm();
                      },
                      child: const Text(ArabicText.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(_editingUser != null
                          ? ArabicText.update
                          : ArabicText.create),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
