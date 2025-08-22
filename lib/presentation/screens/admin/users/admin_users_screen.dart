import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../widgets/admin/auth_wrapper.dart';

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
      _showSnackBar('Error loading users: $e', isError: true);
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
    _resetForm();
    setState(() {
      _showAddUserDialog = true;
      _editingUser = null;
    });
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
        _showSnackBar('User updated successfully');
      } else {
        // Create new user
        if (_passwordController.text.isEmpty) {
          _showSnackBar('Password is required for new users', isError: true);
          return;
        }
        await _apiService.post('/users', data: userData);
        _showSnackBar('User created successfully');
      }

      setState(() {
        _showAddUserDialog = false;
      });
      _resetForm();
      _loadUsers();
    } catch (e) {
      _showSnackBar('Error saving user: $e', isError: true);
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/users/$userId');
        _showSnackBar('User deleted successfully');
        _loadUsers();
      } catch (e) {
        _showSnackBar('Error deleting user: $e', isError: true);
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newStatus = user['status'] == 'active' ? 'suspended' : 'active';
      await _apiService
          .put('/users/${user['id']}/status', data: {'status': newStatus});
      _showSnackBar('User status updated successfully');
      _loadUsers();
    } catch (e) {
      _showSnackBar('Error updating user status: $e', isError: true);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.secondaryBackground,
              child: Text(
                (user['full_name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user['full_name'] ?? 'Unnamed User',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Full Name', user['full_name'] ?? 'N/A'),
              _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
              _buildDetailRow('Role', user['role'] ?? 'N/A'),
              _buildDetailRow('Status', user['status'] ?? 'N/A'),
              _buildDetailRow('Phone Verified',
                  user['phone_verified'] == true ? 'Yes' : 'No'),
              if (user['company_name'] != null)
                _buildDetailRow('Company', user['company_name']),
              _buildDetailRow(
                  'Last Login',
                  user['last_login'] != null
                      ? DateTime.parse(user['last_login'])
                          .toString()
                          .split('.')[0]
                      : 'Never'),
              _buildDetailRow(
                  'Created',
                  user['created_at'] != null
                      ? DateTime.parse(user['created_at'])
                          .toString()
                          .split(' ')[0]
                      : 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            child: const Text('Edit'),
          ),
        ],
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
              // Compact Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 28,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            '${_filteredUsers.length} customers',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filters Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterUsers,
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, or company...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
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
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${_filteredUsers.length} results',
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
                                      ? 'No customers yet'
                                      : 'No customers found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first customer to get started',
                                    style: TextStyle(
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                          user['full_name'] ?? 'Unnamed User',
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
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color:
                                isActive ? Colors.white : Colors.grey.shade600,
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
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        user['phone'] ?? 'No phone',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPhoneVerified)
                        Icon(Icons.verified,
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
                  tooltip: isActive ? 'Suspend User' : 'Activate User',
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // View details button
                IconButton(
                  onPressed: () => _showUserDetails(user),
                  icon: Icon(Icons.info_outline,
                      size: 18, color: AppColors.primaryColor),
                  tooltip: 'View Details',
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Edit button
                IconButton(
                  onPressed: () => _showEditUserDialog(user),
                  icon: Icon(Icons.edit,
                      size: 18, color: AppColors.secondaryColor),
                  tooltip: 'Edit User',
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteUser(user['id']),
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: Colors.red.shade400),
                  tooltip: 'Delete User',
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
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
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
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
                          ? 'Edit Customer'
                          : 'Add New Customer',
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
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Phone number must be at least 10 digits';
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
                                  ? 'Password *'
                                  : 'New Password (leave empty to keep current)',
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (_editingUser == null &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Password is required for new users';
                              }
                              if (value != null &&
                                  value.trim().isNotEmpty &&
                                  value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
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
                            labelText: 'Company Name (Optional)',
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
                                  labelText: 'Role',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'customer',
                                      child: Text('Customer')),
                                  DropdownMenuItem(
                                      value: 'admin', child: Text('Admin')),
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
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'active', child: Text('Active')),
                                  DropdownMenuItem(
                                      value: 'suspended',
                                      child: Text('Suspended')),
                                  DropdownMenuItem(
                                      value: 'pending', child: Text('Pending')),
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
                          title: const Text('Phone Verified'),
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
                      child: const Text('Cancel'),
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
                      child: Text(_editingUser != null ? 'Update' : 'Create'),
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
