import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../data/panel_auth_repository.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Casca do painel: navegação lateral fixa no desktop, drawer no celular.
/// O menu muda conforme o role: academia ou operação UniHub.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _gymItems = [
    (path: '/dashboard', icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    (path: '/students', icon: LucideIcons.users, label: 'Alunos'),
    (path: '/finance', icon: LucideIcons.receipt, label: 'Financeiro'),
    (path: '/settings', icon: LucideIcons.settings, label: 'Configurações'),
  ];

  static const _adminItems = [
    (
      path: '/admin/overview',
      icon: LucideIcons.layoutDashboard,
      label: 'Visão geral',
    ),
    (path: '/admin/gyms', icon: LucideIcons.dumbbell, label: 'Academias'),
    (path: '/admin/payouts', icon: LucideIcons.receipt, label: 'Repasses'),
    (path: '/admin/students', icon: LucideIcons.users, label: 'Estudantes'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final items = session?.isAdmin == true ? _adminItems : _gymItems;

    final sidebar = _SidebarContent(
      session: session,
      items: items,
      location: location,
      onNavigate: (path) {
        // No drawer (celular), fecha antes de navegar
        if (isMobile(context)) Navigator.of(context).pop();
        context.go(path);
      },
      onLogout: () {
        if (isMobile(context)) Navigator.of(context).pop();
        ref.read(sessionProvider.notifier).logout();
      },
    );

    if (isMobile(context)) {
      return Scaffold(
        appBar: AppBar(
          title: UniHubWordmark(
            size: 18,
            suffix: session?.isAdmin == true ? 'operação' : null,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
          ),
        ),
        drawer: Drawer(
          backgroundColor: UniHubColors.background,
          child: sidebar,
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: UniHubColors.divider, width: 1),
              ),
            ),
            child: sidebar,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Conteúdo da navegação, reusado pela coluna fixa (desktop) e pelo drawer (celular).
class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.session,
    required this.items,
    required this.location,
    required this.onNavigate,
    required this.onLogout,
  });

  final PanelSession? session;
  final List<({String path, IconData icon, String label})> items;
  final String location;
  final void Function(String path) onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              UniHubSpacing.x6,
              UniHubSpacing.x6,
              UniHubSpacing.x6,
              UniHubSpacing.x2,
            ),
            child: UniHubWordmark(
              size: 20,
              suffix: session?.isAdmin == true ? 'operação' : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6),
            child: Text(
              session?.displayName ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: UniHubColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: UniHubSpacing.x6),
          for (final item in items)
            _NavItem(
              icon: item.icon,
              label: item.label,
              selected: location == item.path,
              onTap: () => onNavigate(item.path),
            ),
          const Spacer(),
          const Divider(),
          _NavItem(
            icon: LucideIcons.logOut,
            label: 'Sair',
            selected: false,
            onTap: onLogout,
          ),
          const SizedBox(height: UniHubSpacing.x4),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Semantics: expõe o item como botão para leitores de tela/automação
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UniHubSpacing.x6,
            vertical: UniHubSpacing.x3,
          ),
          child: Row(
            children: [
              // Marcador fino laranja para o item ativo — acento com intenção
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: UniHubSpacing.x3),
                color: selected ? UniHubColors.accent : Colors.transparent,
              ),
              Icon(
                icon,
                size: 18,
                color: selected
                    ? UniHubColors.accent
                    : UniHubColors.textSecondary,
              ),
              const SizedBox(width: UniHubSpacing.x3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? UniHubColors.textPrimary
                      : UniHubColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
