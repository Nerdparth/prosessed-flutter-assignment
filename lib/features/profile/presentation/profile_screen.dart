import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../app/theme_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../cart/presentation/cart_provider.dart';
import '../data/profile_repository.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ProfileRepository().getProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/products');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
            tooltip: 'Back',
          ),
          title: const Text(
            'My Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load your profile'),
                  const SizedBox(height: 8),
                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(profileProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
          data: (user) {
            final firstName = user['firstName'] as String? ?? '';
            final lastName = user['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            final username = user['username'] as String? ?? '';
            final email = user['email'] as String? ?? '';
            final image = user['image'] as String? ?? '';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.secondary,
                        AppTheme.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white24,
                        child: ClipOval(
                          child: image.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white,
                                )
                              : CachedNetworkImage(
                                  imageUrl: image,
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName.isEmpty ? username : fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '@$username',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const _SectionTitle(title: 'Personal information'),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Full name',
                  value: fullName.isEmpty ? 'Not provided' : fullName,
                ),
                _InfoTile(
                  icon: Icons.alternate_email,
                  label: 'Username',
                  value: username.isEmpty ? 'Not provided' : username,
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email address',
                  value: email.isEmpty ? 'Not provided' : email,
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Appearance'),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: colors.primary,
                    ),
                    title: const Text('Dark mode'),
                    subtitle: Text(
                      isDark ? 'Dark theme enabled' : 'Light theme enabled',
                    ),
                    value: isDark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme(value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Account'),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Sign out of your ShopSphere account'),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'ShopSphere · Your style, your space',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await AuthRepository().logout();
      await ref.read(cartProvider.notifier).clearCart();

      if (!context.mounted) return;
      ref.invalidate(profileProvider);
      context.go('/');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
