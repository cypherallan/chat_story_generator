import 'package:flutter/material.dart';

import '../../../../core/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;

  const ProfilePage({
    super.key,
    required this.authService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;

  bool _isEditing = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    final user = widget.authService.currentUser;

    _nameController = TextEditingController(
      text: user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty.'),
        ),
      );
      return;
    }

    try {
      await widget.authService.updateDisplayName(name);

      if (!mounted) return;

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isChanging = false;

    await showDialog(
      context: context,
      barrierDismissible: !isChanging,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> changePassword() async {
              final currentPassword = currentPasswordController.text;

              final newPassword = newPasswordController.text;

              final confirmPassword = confirmPasswordController.text;

              if (currentPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter your current password.',
                    ),
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be at least 6 characters.',
                    ),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New passwords do not match.',
                    ),
                  ),
                );
                return;
              }

              if (currentPassword == newPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be different from your current password.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isChanging = true;
              });

              try {
                await widget.authService.changePassword(
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password changed successfully.',
                    ),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                String message;

                switch (e.code) {
                  case 'wrong-password':
                  case 'invalid-credential':
                    message = 'Your current password is incorrect.';
                    break;

                  case 'weak-password':
                    message = 'The new password is too weak.';
                    break;

                  case 'too-many-requests':
                    message = 'Too many attempts. Please try again later.';
                    break;

                  default:
                    message = e.message ?? 'Unable to change password.';
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }

                setDialogState(() {
                  isChanging = false;
                });
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to change password: $e',
                      ),
                    ),
                  );
                }

                setDialogState(() {
                  isChanging = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Change password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      enabled: !isChanging,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: isChanging
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscureCurrent = !obscureCurrent;
                                  });
                                },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !isChanging,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: isChanging
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscureNew = !obscureNew;
                                  });
                                },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !isChanging,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: isChanging
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscureConfirm = !obscureConfirm;
                                  });
                                },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: isChanging ? null : changePassword,
                  child: isChanging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('CHANGE PASSWORD'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to sign in again to access your conversations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('LOG OUT'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authService.signOut();

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                child: Text(
                  (user?.displayName?.isNotEmpty ?? false)
                      ? user!.displayName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.email ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: _isEditing
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : 'No name set',
                      ),
                trailing: _isEditing
                    ? IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveName,
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(
                  user?.email ?? 'No email',
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                subtitle: const Text(
                  'Update your account password',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: const Text(
                  'LOG OUT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
