// Location: agrivana\lib\features\profile\view\profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh profile data
    context.read<AuthBloc>().add(AuthFetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Profile header with subtle gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primarySurface.withValues(alpha: 0.7),
                      AppTheme.background,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child:
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final user = state is AuthAuthenticated ? state.user : null;
                  return Column(
                    children: [
                      // Profile photo
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: user?.isPremium == true
                                ? AppTheme.premiumGold
                                : AppTheme.primary.withValues(alpha: 0.2),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user.profilePhoto!,
                                    width: 84, height: 84, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person_rounded, size: 44, color: AppTheme.primary),
                                  ),
                                )
                              : const Icon(Icons.person_rounded, size: 44, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(user?.name ?? 'Pengguna',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      // Email
                      if (user?.email != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(user!.email!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ),
                      // Bio
                      if (user?.bio != null && user!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(user.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ),
                      // Location & Member since
                      if (user?.locationCity != null && user!.locationCity!.isNotEmpty ||
                          user?.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (user?.locationCity != null && user!.locationCity!.isNotEmpty) ...[
                                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textHint),
                                const SizedBox(width: 3),
                                Text(user.locationCity!,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                              ],
                              if (user?.locationCity != null && user!.locationCity!.isNotEmpty &&
                                  user.createdAt != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Container(width: 3, height: 3,
                                      decoration: const BoxDecoration(color: AppTheme.textHint, shape: BoxShape.circle)),
                                ),
                              if (user?.createdAt != null) ...[
                                const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textHint),
                                const SizedBox(width: 3),
                                Text('Bergabung ${_formatDate(user!.createdAt!)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                              ],
                            ],
                          ),
                        ),
                      // Premium badge
                      if (user?.isPremium == true) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppTheme.premiumGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text('Premium',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              ),
              const SizedBox(height: 24),
              // Menu list
              _menuCard([
                _menuItem(Icons.person_outline, 'Edit Profil', () async {
                  final result = await Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  if (result == true && mounted) {
                    // Refresh profile data after edit
                    context.read<AuthBloc>().add(AuthFetchProfile());
                  }
                }),
                _menuItem(Icons.location_on_outlined, 'Alamat', () => Navigator.of(context).pushNamed(AppRoutes.addresses)),
                _menuItem(Icons.receipt_long_outlined, 'Pesanan', () => Navigator.of(context).pushNamed(AppRoutes.orderList)),
                _menuItem(Icons.favorite_outline, 'Wishlist', () => Navigator.of(context).pushNamed(AppRoutes.wishlist)),
                _menuItem(Icons.chat_outlined, 'Chat', () => Navigator.of(context).pushNamed(AppRoutes.chatList)),
              ]),
              const SizedBox(height: 12),
              _menuCard([
                _menuItem(Icons.storefront_outlined, 'Toko Saya', () => Navigator.of(context).pushNamed(AppRoutes.sellerDashboard)),
                _menuItem(Icons.workspace_premium_outlined, 'Langganan', () => Navigator.of(context).pushNamed(AppRoutes.subscription)),
                _menuItem(Icons.smart_toy_outlined, 'Chatbot Vana', () => Navigator.of(context).pushNamed(AppRoutes.chatbot)),
              ]),
              const SizedBox(height: 12),
              _menuCard([
                _menuItem(Icons.notifications_outlined, 'Notifikasi', () => Navigator.of(context).pushNamed(AppRoutes.notifications)),
                _menuItem(Icons.lock_outline, 'Ganti Password', () => Navigator.of(context).pushNamed(AppRoutes.changePassword)),
              ]),
              const SizedBox(height: 12),
              // Logout
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthUnauthenticated) {
                      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                    }
                  },
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                    title: const Text('Keluar', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
