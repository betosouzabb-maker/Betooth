import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/sharing/share_service.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authControllerProvider.select((s) => s.user),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                name: user?.name ?? '',
                email: user?.email ?? '',
                photoUrl: user?.profilePhotoUrl,
                role: user?.role ?? 'USER',
              ),
            ),
            title: const Text('Perfil'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _SectionTitle('Conta'),
              _ProfileMenuItem(
                icon: Icons.history_rounded,
                label: 'Histórico de reprodução',
                onTap: () => context.push('/history'),
              ),
              _ProfileMenuItem(
                icon: Icons.favorite_rounded,
                label: 'Minhas favoritas',
                onTap: () => context.push('/favorites'),
              ),
              _ProfileMenuItem(
                icon: Icons.upload_rounded,
                label: 'Enviar música',
                onTap: () => context.push('/upload'),
              ),
              _SectionTitle('Áudio'),
              _ProfileMenuItem(
                icon: Icons.graphic_eq_rounded,
                label: 'Equalizador',
                onTap: () => context.push('/equalizer'),
              ),
              _SectionTitle('Compartilhar'),
              _ProfileMenuItem(
                icon: Icons.share_rounded,
                label: 'Compartilhar o Betooth',
                onTap: () async {
                  await ShareService.instance.shareApp();
                },
              ),
              _SectionTitle('Sobre'),
              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                label: 'Versão do app',
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                onTap: null,
              ),
              const SizedBox(height: 16),
              _LogoutButton(),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryAccent, AppColors.background],
        ),
      ),
      padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 16),
      child: Row(
        children: [
          _Avatar(name: name, photoUrl: photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.isEmpty ? 'Usuário' : name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _RoleBadge(role: role),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: AppColors.card,
      );
    }

    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.card,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final label = role == 'ADMIN'
        ? 'Admin'
        : role == 'ARTIST'
            ? 'Artista'
            : 'Ouvinte';

    final color = role == 'ADMIN'
        ? Colors.orangeAccent
        : role == 'ARTIST'
            ? AppColors.secondaryAccent
            : AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sair da conta'),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Sair'),
              content: const Text('Deseja sair da sua conta?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sair',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(authControllerProvider.notifier).logout();
          }
        },
      ),
    );
  }
}
