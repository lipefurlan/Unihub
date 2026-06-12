import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final checkinsAsync = ref.watch(myCheckinsProvider);

    if (student == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        children: [
          Row(
            children: [
              InitialsAvatar(name: student.name, photoUrl: student.photoUrl, radius: 28),
              const SizedBox(width: UniHubSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      student.university,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                    Text(
                      student.email,
                      style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x6),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.creditCard,
            label: 'Carteirinha digital',
            onTap: () => context.push('/card'),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.repeat,
            label: 'Gerenciar plano',
            subtitle: student.subscription?.plan.name ?? 'Sem plano ativo',
            onTap: () => context.push('/plans'),
          ),
          const Divider(),
          _ProfileAction(
            icon: LucideIcons.logOut,
            label: 'Sair',
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
          const Divider(),
          const SizedBox(height: UniHubSpacing.x8),
          const SectionTitle('Histórico de check-ins'),
          const SizedBox(height: UniHubSpacing.x2),
          checkinsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (e, _) =>
                Text('$e', style: const TextStyle(color: UniHubColors.textSecondary)),
            data: (checkins) => checkins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
                    child: Text(
                      'Nenhum check-in ainda. Que tal começar hoje?',
                      style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, c) in checkins.take(30).indexed) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.gym.name,
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      formatDateTime(c.timestamp),
                                      style: const TextStyle(
                                          fontSize: 12.5, color: UniHubColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Plano ${c.planTierAtCheckin}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: UniHubColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: UniHubColors.textSecondary),
            const SizedBox(width: UniHubSpacing.x4),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary)),
            const SizedBox(width: UniHubSpacing.x2),
            const Icon(LucideIcons.chevronRight, size: 16, color: UniHubColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
