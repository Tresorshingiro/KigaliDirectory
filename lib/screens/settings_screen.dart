import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final locationNotifications = ref.watch(locationNotificationsProvider);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: Color(0xFF212121)),
          ),
        ),
      );
    }

    final userProfileAsync = ref.watch(userProfileProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show currently authenticated email prominently
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF2E7D32), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Logged in as: ${currentUser.email}',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  userProfileAsync.when(
                    data: (profile) {
                      if (profile == null) {
                        return const Text(
                          'Profile not found',
                          style: TextStyle(color: Color(0xFF757575)),
                        );
                      }
                      return Column(
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                    error: (error, stack) => Text(
                      'Error loading profile',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings section
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Account info
                  _SettingsItem(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: currentUser.email ?? 'No email',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentUser.emailVerified
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentUser.emailVerified ? 'Verified' : 'Not Verified',
                        style: TextStyle(
                          color: currentUser.emailVerified ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFFE0E0E0), height: 1),

                  // Location notifications toggle
                  _SettingsItem(
                    icon: Icons.notifications_active,
                    title: 'Location Notifications',
                    subtitle: 'Get notified about nearby places',
                    trailing: Switch(
                      value: locationNotifications,
                      onChanged: (value) {
                        ref.read(locationNotificationsProvider.notifier).state = value;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Location notifications enabled'
                                  : 'Location notifications disabled',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeColor: const Color(0xFFFF8F00),
                    ),
                  ),

                  const Divider(color: Color(0xFFE0E0E0), height: 1),

                  // App version
                  const _SettingsItem(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: '1.0.0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout button
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Color(0xFF212121)),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Color(0xFF757575)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Sign out and invalidate all providers to clear cached state
                  await ref.read(authNotifierProvider.notifier).signOut();
                  ref.invalidate(authStateProvider);
                  ref.invalidate(currentUserProvider);
                  ref.invalidate(allListingsProvider);
                  ref.invalidate(userListingsProvider);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF2E7D32),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF212121),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF757575),
          fontSize: 14,
        ),
      ),
      trailing: trailing,
    );
  }
}
